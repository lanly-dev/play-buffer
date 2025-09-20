#!/bin/bash
set -e

# Build PortAudio on macOS using CMake with policy flag
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"
mkdir -p build
cd build
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(sysctl -n hw.ncpu)

# Build the play_buffer example
cd "$PROJECT_ROOT"
gcc -o play_buffer play_buffer.c -I./portaudio/include -L./build -lportaudio
mkdir -p build/artifacts
cp play_buffer build/artifacts/