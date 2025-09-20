#!/bin/bash
set -e

# Find play_buffer.c location
echo "Searching for play_buffer.c..."
PLAY_BUFFER_PATH=$(find .. -name play_buffer.c 2>/dev/null | head -n 1)
if [ -z "$PLAY_BUFFER_PATH" ]; then
	echo "Error: play_buffer.c not found!"
	exit 1
else
	echo "Found play_buffer.c at: $PLAY_BUFFER_PATH"
fi

# Build PortAudio on macOS using CMake with policy flag
mkdir -p build
cd build
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(sysctl -n hw.ncpu)

# Build the play_buffer example
cd ..
gcc -o play_buffer "$PLAY_BUFFER_PATH" -I./portaudio/include -L./build -lportaudio
mkdir -p build/artifacts
cp play_buffer build/artifacts/