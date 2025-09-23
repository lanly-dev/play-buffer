#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <portaudio.h>
#include <stdint.h>

#define SAMPLE_RATE 44100
#define FRAMES_PER_BUFFER 16

#ifndef PLAYBUFFER_VERSION
#define PLAYBUFFER_VERSION "unknown"
#endif

#ifndef PORTAUDIO_COMMIT
#define PORTAUDIO_COMMIT "unknown"
#endif

// Embedded version strings (visible with 'strings' command on Linux/macOS)
static const char* version_info[] = {
    "PlayBuffer-Version: " PLAYBUFFER_VERSION,
    "PortAudio-Commit: " PORTAUDIO_COMMIT,
    NULL
};

float *audio_buffer = NULL;
size_t buffer_size = 0;
size_t audio_index = 0;
int audio_finished = 0;

// Read all available float samples from stdin
void read_all_from_stdin() {
    size_t capacity = SAMPLE_RATE; // Start with 1 second capacity
    audio_buffer = malloc(capacity * sizeof(float));
    if (!audio_buffer) {
        printf("Failed to allocate initial buffer\n");
        return;
    }

    // Read in larger chunks for better performance
    #define CHUNK_SIZE 1024 // Read 1024 floats at a time
    float chunk[CHUNK_SIZE];
    size_t samples_read;
    size_t total_bytes = 0;
    int read_count = 0;

    printf("Starting to read from stdin...\n");

    while ((samples_read = fread(chunk, sizeof(float), CHUNK_SIZE, stdin)) > 0) {
        read_count++;
        printf("Read %zu samples in chunk %d\n", samples_read, read_count);

        // Ensure we have enough capacity
        while (buffer_size + samples_read > capacity) {
            capacity *= 2;
            printf("Expanding buffer to %zu samples\n", capacity);
            audio_buffer = realloc(audio_buffer, capacity * sizeof(float));
            if (!audio_buffer) {
                printf("Failed to reallocate buffer\n");
                return;
            }
        }

        // Copy the chunk to our buffer
        memcpy(audio_buffer + buffer_size, chunk, samples_read * sizeof(float));
        buffer_size += samples_read;
        total_bytes += samples_read * sizeof(float);

        // If we read less than requested, we've reached EOF
        if (samples_read < CHUNK_SIZE) {
            printf("Reached EOF (read %zu < %d)\n", samples_read, CHUNK_SIZE);
            break;
        }
    }
    printf("Finished reading. Total: %zu bytes (%zu samples) in %d chunks\n", total_bytes, buffer_size, read_count);
}

static int paCallback(const void *input, void *output,
                     unsigned long frameCount,
                     const PaStreamCallbackTimeInfo* timeInfo,
                     PaStreamCallbackFlags statusFlags,
                     void *userData) {
    float *out = (float*)output;

    for (unsigned long i = 0; i < frameCount; i++) {
        if (audio_index < buffer_size) {
            out[i] = audio_buffer[audio_index++];
        } else {
            out[i] = 0.0f; // Silence when done
            audio_finished = 1;
        }
    }
    return audio_finished ? paComplete : paContinue;
}

// Play audio that is already fully loaded into memory using PortAudio callback API
static int play_preloaded(void) {
    if (buffer_size == 0) {
        printf("No audio data received\n");
        return 1;
    }

    printf("Playing %zu samples (%.4f seconds)\n", buffer_size, (float)buffer_size / SAMPLE_RATE);

    PaError err;
    if ((err = Pa_Initialize()) != paNoError) {
        fprintf(stderr, "Pa_Initialize failed: %s\n", Pa_GetErrorText(err));
        return 1;
    }

    PaStream *stream = NULL;
    err = Pa_OpenDefaultStream(&stream, 0, 1, paFloat32, SAMPLE_RATE,
                               FRAMES_PER_BUFFER, paCallback, NULL);
    if (err != paNoError) {
        fprintf(stderr, "Pa_OpenDefaultStream failed: %s\n", Pa_GetErrorText(err));
        Pa_Terminate();
        return 1;
    }

    if ((err = Pa_StartStream(stream)) != paNoError) {
        fprintf(stderr, "Pa_StartStream failed: %s\n", Pa_GetErrorText(err));
        Pa_CloseStream(stream);
        Pa_Terminate();
        return 1;
    }

    // Wait until audio finishes playing
    while (!audio_finished) {
        Pa_Sleep(100);
    }

    Pa_StopStream(stream);
    Pa_CloseStream(stream);
    Pa_Terminate();
    return 0;
}

// --- Callback-based streaming implementation ---
#define STREAM_RINGBUF_SIZE (SAMPLE_RATE * 2) // 2 seconds of audio
static float *stream_ringbuf = NULL;
static size_t stream_write_idx = 0;
static size_t stream_read_idx = 0;
static int stream_eof = 0;

static size_t stream_ringbuf_available(void) {
    if (stream_write_idx >= stream_read_idx)
        return stream_write_idx - stream_read_idx;
    else
        return STREAM_RINGBUF_SIZE - (stream_read_idx - stream_write_idx);
}

static size_t stream_ringbuf_free(void) {
    return STREAM_RINGBUF_SIZE - stream_ringbuf_available() - 1;
}

static int stream_callback(const void *input, void *output,
                          unsigned long frameCount,
                          const PaStreamCallbackTimeInfo* timeInfo,
                          PaStreamCallbackFlags statusFlags,
                          void *userData) {
    float *out = (float*)output;
    size_t avail = stream_ringbuf_available();
    size_t to_copy = frameCount < avail ? frameCount : avail;
    for (unsigned long i = 0; i < to_copy; i++) {
        out[i] = stream_ringbuf[stream_read_idx];
        stream_read_idx = (stream_read_idx + 1) % STREAM_RINGBUF_SIZE;
    }
    for (unsigned long i = to_copy; i < frameCount; i++) {
        out[i] = 0.0f; // underrun: output silence
    }
    // If EOF and buffer empty, signal completion
    if (stream_eof && stream_ringbuf_available() == 0)
        return paComplete;
    return paContinue;
}

static int play_streaming(void) {
    PaError err;
    stream_ringbuf = (float*)malloc(sizeof(float) * STREAM_RINGBUF_SIZE);
    if (!stream_ringbuf) {
        fprintf(stderr, "Failed to allocate streaming ring buffer\n");
        return 1;
    }
    stream_write_idx = 0;
    stream_read_idx = 0;
    stream_eof = 0;

    if ((err = Pa_Initialize()) != paNoError) {
        fprintf(stderr, "Pa_Initialize failed: %s\n", Pa_GetErrorText(err));
        free(stream_ringbuf);
        return 1;
    }

    PaStream *stream = NULL;
    err = Pa_OpenDefaultStream(&stream, 0, 1, paFloat32, SAMPLE_RATE,
                               FRAMES_PER_BUFFER, stream_callback, NULL);
    if (err != paNoError) {
        fprintf(stderr, "Pa_OpenDefaultStream failed: %s\n", Pa_GetErrorText(err));
        Pa_Terminate();
        free(stream_ringbuf);
        return 1;
    }

    if ((err = Pa_StartStream(stream)) != paNoError) {
        fprintf(stderr, "Pa_StartStream failed: %s\n", Pa_GetErrorText(err));
        Pa_CloseStream(stream);
        Pa_Terminate();
        free(stream_ringbuf);
        return 1;
    }

    printf("Streaming from stdin (callback mode)...\n");

    // Main thread: read from stdin and push to ring buffer
    #define STREAM_CHUNK_SIZE 256
    float chunk[STREAM_CHUNK_SIZE];
    while (!stream_eof) {
        size_t free_space = stream_ringbuf_free();
        if (free_space == 0) {
            Pa_Sleep(1); // Buffer full, wait for callback to consume
            continue;
        }
        size_t to_read = free_space < STREAM_CHUNK_SIZE ? free_space : STREAM_CHUNK_SIZE;
        size_t n = fread(chunk, sizeof(float), to_read, stdin);
        if (n > 0) {
            // Copy to ring buffer
            for (size_t i = 0; i < n; i++) {
                stream_ringbuf[stream_write_idx] = chunk[i];
                stream_write_idx = (stream_write_idx + 1) % STREAM_RINGBUF_SIZE;
            }
        }
        if (n < to_read) {
            // EOF or error
            stream_eof = 1;
        }
    }

    // Wait for playback to finish
    while (Pa_IsStreamActive(stream)) {
        Pa_Sleep(10);
    }

    Pa_StopStream(stream);
    Pa_CloseStream(stream);
    Pa_Terminate();
    free(stream_ringbuf);
    return 0;
}

static void print_usage(const char* prog) {
    printf("Usage: %s [--stream-blocking] [--stream-callback]\n", prog);
    printf("\n");
    printf("Reads raw 32-bit float samples from stdin and plays them.\n");
    printf("\n");
    printf("Modes:\n");
    printf("  (default) Preload: read all stdin to memory, then play.\n");
    printf("  --stream-blocking   : stream from stdin using blocking API (smoother, more latency)\n");
    printf("  --stream-callback   : stream from stdin using callback API (lower latency, risk underruns)\n");
}

int main(int argc, char** argv) {
    // On Windows, set stdin to binary mode
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
    _setmode(_fileno(stdin), _O_BINARY);
#endif
    printf("PlayBuffer %s\n", PLAYBUFFER_VERSION);
    printf("Built with PortAudio commit: %s\n", PORTAUDIO_COMMIT);

    // Print default low output latency
    PaError err_init = Pa_Initialize();
    if (err_init == paNoError) {
        PaDeviceInfo *info = Pa_GetDeviceInfo(Pa_GetDefaultOutputDevice());
        if (info) {
            printf("Default low output latency: %.4f seconds\n", info->defaultLowOutputLatency);
        }
        Pa_Terminate();
    } else {
        printf("(Could not query PortAudio device info: %s)\n", Pa_GetErrorText(err_init));
    }

    int use_stream_blocking = 0;
    int use_stream_callback = 0;
    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--stream-blocking") == 0) {
            use_stream_blocking = 1;
        } else if (strcmp(argv[i], "--stream-callback") == 0) {
            use_stream_callback = 1;
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            print_usage(argv[0]);
            return 0;
        } else {
            fprintf(stderr, "Unknown argument: %s\n\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        }
    }

    int rc = 0;
    if (use_stream_blocking) {
        // Blocking API
        PaError err;
        if ((err = Pa_Initialize()) != paNoError) {
            fprintf(stderr, "Pa_Initialize failed: %s\n", Pa_GetErrorText(err));
            return 1;
        }
        PaStream *stream = NULL;
        err = Pa_OpenDefaultStream(&stream, 0, 1, paFloat32, SAMPLE_RATE,
                                   FRAMES_PER_BUFFER, NULL, NULL);
        if (err != paNoError) {
            fprintf(stderr, "Pa_OpenDefaultStream failed: %s\n", Pa_GetErrorText(err));
            Pa_Terminate();
            return 1;
        }
        if ((err = Pa_StartStream(stream)) != paNoError) {
            fprintf(stderr, "Pa_StartStream failed: %s\n", Pa_GetErrorText(err));
            Pa_CloseStream(stream);
            Pa_Terminate();
            return 1;
        }
        printf("Streaming from stdin (blocking mode)...\n");
        float *ioBuffer = (float*)malloc(sizeof(float) * FRAMES_PER_BUFFER);
        if (!ioBuffer) {
            fprintf(stderr, "Failed to allocate streaming buffer\n");
            Pa_StopStream(stream);
            Pa_CloseStream(stream);
            Pa_Terminate();
            return 1;
        }
        while (1) {
            size_t readCount = fread(ioBuffer, sizeof(float), FRAMES_PER_BUFFER, stdin);
            if (readCount == FRAMES_PER_BUFFER) {
                err = Pa_WriteStream(stream, ioBuffer, FRAMES_PER_BUFFER);
                if (err != paNoError) {
                    fprintf(stderr, "Pa_WriteStream failed: %s\n", Pa_GetErrorText(err));
                    break;
                }
            } else if (readCount > 0) {
                memset(ioBuffer + readCount, 0, (FRAMES_PER_BUFFER - readCount) * sizeof(float));
                err = Pa_WriteStream(stream, ioBuffer, FRAMES_PER_BUFFER);
                if (err != paNoError) {
                    fprintf(stderr, "Pa_WriteStream failed on final write: %s\n", Pa_GetErrorText(err));
                }
                break;
            } else {
                if (feof(stdin)) {
                    // normal EOF
                } else if (ferror(stdin)) {
                    perror("fread");
                }
                break;
            }
        }
        free(ioBuffer);
        Pa_StopStream(stream);
        Pa_CloseStream(stream);
        Pa_Terminate();
        rc = 0;
    } else if (use_stream_callback) {
        // Callback API
        rc = play_streaming();
    } else {
        // Read all audio data from stdin then play
        read_all_from_stdin();
        rc = play_preloaded();
        free(audio_buffer);
    }
    return rc;
}
