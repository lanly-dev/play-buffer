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
- Version information displayed at runtime
- Automated daily builds with latest PortAudio
- Example: Generate and play melodies with Node.js (see `examples/index.js`)
- Streaming mode: play while reading from stdin (`--stream`)

## Building

### Prerequisites

- CMake 3.10 or later
- C compiler (GCC, Clang, or MSVC)
- PortAudio library (automatically built from source by scripts)

### Platform-specific build scripts

Use the provided build scripts for your platform:

#### Windows
```powershell
./scripts/build-windows.ps1
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

The program reads raw 32-bit float audio samples from stdin and plays them. Two modes are available:

- Preload mode (default): reads all stdin into memory, then plays back
- Streaming mode (`--stream` or `-s`): reads and plays in chunks to minimize memory usage

```bash
# Example: Generate and play a sine wave (preload mode)
your_audio_generator | ./play_buffer

# Example: Streaming mode (recommended for long audio)
your_audio_generator | ./play_buffer --stream

# Example: Play raw audio data from a file (preload)
cat audio_samples.raw | ./play_buffer

# Example: Play raw audio data from a file (streaming)
cat audio_samples.raw | ./play_buffer --stream
```

### Node.js Example

You can generate and play melodies (such as "Happy Birthday") using Node.js. See `examples/index.js` for a working implementation.

For continuous/large audio, see `examples/streaming.js` or the inline sample below.

### Streaming from Node.js (inline)

Here's a minimal Node.js example that streams generated audio in chunks to `play_buffer` using the `--stream` mode. This avoids buffering the entire audio in memory inside `play_buffer`.

```js
const { spawn } = require('child_process')

const sampleRate = 44100
const exe = process.platform === 'win32' ? 'play_buffer.exe' : './play_buffer'

// Generator producing a continuous sine tone at 440 Hz
function* toneGenerator(freq = 440, amp = 0.3) {
  let t = 0
  const dt = 1 / sampleRate
  const chunkSize = 2048
  while (true) {
    const chunk = new Float32Array(chunkSize)
    for (let i = 0; i < chunkSize; i++) {
      chunk[i] = amp * Math.sin(2 * Math.PI * freq * t)
      t += dt
    }
    yield Buffer.from(new Uint8Array(chunk.buffer))
  }
}

const gen = toneGenerator()
const child = spawn(exe, ['--stream'], { stdio: ['pipe', 'inherit', 'inherit'] })

// Send ~3 seconds of audio, then end
let sent = 0
const targetSamples = sampleRate * 3
const chunkSamples = 2048

function pump() {
  while (sent < targetSamples) {
    const buf = gen.next().value
    const ok = child.stdin.write(buf)
    sent += chunkSamples
    if (!ok) {
      child.stdin.once('drain', pump)
      return
    }
  }
  child.stdin.end()
}

pump()
```

## Audio Format

- Sample Rate: 44,100 Hz
- Channels: Mono
- Sample Format: 32-bit floating point (-1.0 to 1.0)
- Byte Order: Native endianness
- Input: Raw binary data via stdin (no headers)

## Windows Binary Stdin Fix

On Windows, PlayBuffer sets stdin to binary mode to ensure all audio data is read correctly. This is handled automatically in the code.

## Download Latest Windows Build

Use the batch script to download the latest Windows build to your `examples` directory:

```cmd
examples\download.bat
```

## Version Information

The executable displays version information at runtime:

- Windows/Linux/macOS: Run the executable to see version and PortAudio commit info

## Configuration

Key parameters can be modified in `play_buffer.c`:

- `SAMPLE_RATE`: Audio sample rate (default: 44100)
- `FRAMES_PER_BUFFER`: Audio buffer size (default: 256)

## Automated Builds

This project includes GitHub Actions workflows that:

- Monitor PortAudio daily for new commits
- Build automatically on Windows, Linux, and macOS
- Create releases with version tags like `v2025.09.21-b0cc303.1`
- Embed version metadata including PortAudio commit information

Download the latest pre-built binaries from the [Releases page](https://github.com/lanly-dev/play-buffer/releases).

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the functionality or add new features.
