#include <stdio.h>
#include <stdlib.h>
#include <portaudio.h>

#define SAMPLE_RATE 44100
#define FRAMES_PER_BUFFER 256

#ifndef PLAYBUFFER_VERSION
#define PLAYBUFFER_VERSION "unknown"
#endif

float *audio_buffer = NULL;
size_t buffer_size = 0;
size_t audio_index = 0;
int audio_finished = 0;

// Read all available float samples from stdin
void read_all_from_stdin() {
    size_t capacity = SAMPLE_RATE; // Start with 1 second capacity
    audio_buffer = malloc(capacity * sizeof(float));

    float sample;
    while (fread(&sample, sizeof(float), 1, stdin) == 1) {
        if (buffer_size >= capacity) {
            capacity *= 2;
            audio_buffer = realloc(audio_buffer, capacity * sizeof(float));
        }
        audio_buffer[buffer_size++] = sample;
    }
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
    
    // Read all audio data from stdin
    read_all_from_stdin();

    if (buffer_size == 0) {
        printf("No audio data received\n");
        return 1;
    }

    printf("Playing %zu samples (%.2f seconds)\n", buffer_size, (float)buffer_size / SAMPLE_RATE);

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
