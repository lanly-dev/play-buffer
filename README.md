# play-buffer

A simple cross-platform audio player that reads raw float audio samples from stdin and plays them through the default audio output device using PortAudio.

## Purpose

This utility allows you to pipe raw audio data (32-bit float samples) directly to your speakers or headphones. It's useful for testing audio processing pipelines, debugging audio streams, or playing programmatically generated audio data.

## Features

- Reads raw 32-bit float audio samples from standard input
- Plays audio at 44.1 kHz sample rate
- 2-second playback duration (configurable in source)
- Cross-platform support (Windows, Linux, macOS)
- Uses PortAudio for reliable audio output

## Building

### Prerequisites

- CMake 3.10 or later
- C compiler (GCC, Clang, or MSVC)
- PortAudio library

### Platform-specific build scripts

Use the provided build scripts for your platform:

#### Windows
```powershell
.\scripts\build-windows.ps1
```

#### Ubuntu/Linux
```bash
./scripts/build-ubuntu.sh
```

#### macOS
```bash
./scripts/build-macos.sh
```

## Usage

The program reads raw 32-bit float audio samples from stdin and plays them:

```bash
# Example: Generate and play a sine wave
your_audio_generator | ./play_buffer

# Example: Play raw audio data from a file
cat audio_samples.raw | ./play_buffer
```

### Audio Format

- **Sample Rate**: 44,100 Hz
- **Channels**: Mono
- **Sample Format**: 32-bit floating point (-1.0 to 1.0)
- **Byte Order**: Native endianness

## Configuration

Key parameters can be modified in `play_buffer.c`:

- `SAMPLE_RATE`: Audio sample rate (default: 44100)
- `FRAMES_PER_BUFFER`: Audio buffer size (default: 256)
- `BUFFER_SIZE`: Total buffer size (default: SAMPLE_RATE * 2)

## Automated Builds

This project includes GitHub Actions workflows that automatically build the project on multiple platforms and create releases when changes are pushed to the main branch.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the functionality or add new features.
