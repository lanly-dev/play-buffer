# PortAudio Builder

This repository automatically monitors the [PortAudio](https://github.com/PortAudio/portaudio) repository for new releases. When a new release is detected, it triggers a build process across multiple platforms (Windows, Ubuntu, macOS) and creates a new release with the built artifacts.

## Purpose

PortAudio is a cross-platform audio I/O library. This builder ensures that pre-built binaries are available for each new version, making it easier for developers to integrate PortAudio without needing to build from source.

## How it works

- A GitHub Actions workflow runs daily to check for new PortAudio releases.
- If a new release is found, it clones the PortAudio repository at that tag.
- Builds the library using CMake on Windows (MSVC), Ubuntu (GCC), and macOS (Clang).
- Creates a new release in this repository with the built static and shared libraries, headers, and other artifacts.

## Releases

Releases in this repository correspond to PortAudio versions. Each release contains:
- Static libraries (.lib, .a)
- Shared libraries (.dll, .so, .dylib)
- Header files
- Build logs

## Contributing

This repository is automated. To suggest changes to the build process, open an issue or pull request.
