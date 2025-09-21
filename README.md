# PlayBuffer

A simple cross-platform audio player that reads raw float audio samples from stdin and plays them through the default audio output device using PortAudio.

## Purpose

This utility allows you to pipe raw audio data (32-bit float samples) directly to your speakers or headphones. It's useful for testing audio processing pipelines, debugging audio streams, or playing programmatically generated audio data.

## Features

- Reads raw 32-bit float audio samples from standard input
- Plays audio at 44.1 kHz sample rate
- Dynamic buffer allocation for audio of any length
- Cross-platform support (Windows, Linux, macOS)
- Uses PortAudio for reliable audio output
- Version information embedded in binaries
- Automated daily builds with latest PortAudio

## Building

### Prerequisites

- CMake 3.10 or later
- C compiler (GCC, Clang, or MSVC)
- PortAudio library (automatically built from source by scripts)

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

The build scripts automatically download and compile the latest PortAudio from source, ensuring you have the most recent audio library.

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
- **Input**: Raw binary data via stdin (no headers)

## Version Information

The executable includes embedded version information:

- **Windows**: Visible in file properties (right-click → Properties → Details)
- **Linux/macOS**: Use `strings play_buffer | grep -E "(PlayBuffer|PortAudio)"` or run the executable to see version info

## Configuration

Key parameters can be modified in `play_buffer.c`:

- `SAMPLE_RATE`: Audio sample rate (default: 44100)
- `FRAMES_PER_BUFFER`: Audio buffer size (default: 256)

## Automated Builds

This project includes GitHub Actions workflows that:

- **Monitor PortAudio daily** for new commits
- **Build automatically** on Windows, Linux, and macOS
- **Create releases** with version tags like `v2025.09.21-b0cc303.1`
- **Embed version metadata** including PortAudio commit information

Download the latest pre-built binaries from the [Releases page](https://github.com/lanly-dev/play-buffer/releases).

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the functionality or add new features.
