#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <portaudio.h>

#define SAMPLE_RATE 44100
#define FRAMES_PER_BUFFER 256

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

int main() {
    printf("PlayBuffer %s\n", PLAYBUFFER_VERSION);
    printf("Built with PortAudio commit: %s\n", PORTAUDIO_COMMIT);

    // Read all audio data from stdin
    read_all_from_stdin();

    if (buffer_size == 0) {
        printf("No audio data received\n");
        return 1;
    }

    printf("Playing %zu samples (%.4f seconds)\n", buffer_size, (float)buffer_size / SAMPLE_RATE);

    Pa_Initialize();
    PaStream *stream;
    Pa_OpenDefaultStream(&stream, 0, 1, paFloat32, SAMPLE_RATE,
                         FRAMES_PER_BUFFER, paCallback, NULL);
    Pa_StartStream(stream);

    // Wait until audio finishes playing
    while (!audio_finished) {
        Pa_Sleep(100);
    }

    Pa_StopStream(stream);
    Pa_CloseStream(stream);
    Pa_Terminate();

    free(audio_buffer);
    return 0;
}
