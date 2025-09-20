#!/bin/bash
set -e

PLAY_BUFFER_PATH="../builder/play_buffer.c"

# Check for portaudio.h header
PORTAUDIO_HEADER_PATH="./portaudio/include/portaudio.h"
if [ ! -f "$PORTAUDIO_HEADER_PATH" ]; then
	echo "Error: portaudio.h not found at $PORTAUDIO_HEADER_PATH"
	echo "Please ensure PortAudio is downloaded and portaudio/include/portaudio.h exists."
	exit 1
else
	echo "Found portaudio.h at: $PORTAUDIO_HEADER_PATH"
fi

# Build PortAudio on macOS using CMake with policy flag
mkdir -p build
cd build
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(sysctl -n hw.ncpu)

# Build the play_buffer example
cd ..
gcc -o play_buffer ../builder/play_buffer.c -I./portaudio/include -L./build -lportaudio
mkdir -p build/artifacts
cp play_buffer build/artifacts/