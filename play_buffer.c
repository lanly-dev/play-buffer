#include <stdio.h>
#include <portaudio.h>

#define SAMPLE_RATE 44100
#define FRAMES_PER_BUFFER 256


#define BUFFER_SIZE (SAMPLE_RATE * 2)
float buffer[BUFFER_SIZE];

// Read BUFFER_SIZE float samples from stdin
void read_buffer_from_stdin(float *buf, size_t size) {
    size_t read = fread(buf, sizeof(float), size, stdin);
    if (read < size) {
        // Fill remaining with silence if not enough data
        for (size_t i = read; i < size; ++i) buf[i] = 0.0f;
    }
}

static int paCallback(const void *input, void *output,
                     unsigned long frameCount,
                     const PaStreamCallbackTimeInfo* timeInfo,
                     PaStreamCallbackFlags statusFlags,
                     void *userData) {
    static size_t idx = 0;
    float *out = (float*)output;
    float *audio = (float*)userData;
    for (unsigned long i = 0; i < frameCount; i++) {
        out[i] = audio[idx++];
        if (idx >= SAMPLE_RATE * 2) idx = 0; // Loop or stop as needed
    }
    return paContinue;
}

int main() {
    // Read buffer from stdin
    read_buffer_from_stdin(buffer, BUFFER_SIZE);

    Pa_Initialize();
    PaStream *stream;
    Pa_OpenDefaultStream(&stream, 0, 1, paFloat32, SAMPLE_RATE,
                         FRAMES_PER_BUFFER, paCallback, buffer);
    Pa_StartStream(stream);
    Pa_Sleep(2000); // Play for 2 seconds
    Pa_StopStream(stream);
    Pa_CloseStream(stream);
    Pa_Terminate();
    return 0;
}
