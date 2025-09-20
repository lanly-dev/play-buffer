#!/bin/sh

# To find where play_buffer.c is located, use:
# find .. -name play_buffer.c

# Check for portaudio.h header
echo "Current working directory: $(pwd)"
echo "Listing contents of ./include:"
ls -la ./include
PORTAUDIO_HEADER_PATH="./include/portaudio.h"
if [ ! -f "$PORTAUDIO_HEADER_PATH" ]; then
	echo "Error: portaudio.h not found at $PORTAUDIO_HEADER_PATH"
	echo "Please ensure PortAudio is downloaded and include/portaudio.h exists."
	exit 1
else
	echo "Found portaudio.h at: $PORTAUDIO_HEADER_PATH"
fi

# Build PortAudio on macOS using CMake with policy flag
mkdir -p build
cd build
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(nproc 2>/dev/null || echo 4)

# Build the play_buffer example
cd ..
gcc -o play_buffer ../builder/play_buffer.c -I./include -L./build -lportaudio
mkdir -p build/artifacts
cp play_buffer build/artifacts/