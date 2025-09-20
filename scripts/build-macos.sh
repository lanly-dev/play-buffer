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
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DPA_BUILD_SHARED=OFF -DPA_BUILD_STATIC=ON
make -j$(nproc 2>/dev/null || echo 4)

# Debug: List what was built
echo "Contents of build directory:"
ls -la
echo "Looking for library files:"
find . -name "*.a" -o -name "*.dylib" -o -name "*.so"

# Build the play_buffer example
cd ..

# Find the actual library file
PORTAUDIO_LIB=$(find ./build -name "libportaudio*.a" | head -n 1)
if [ -z "$PORTAUDIO_LIB" ]; then
    echo "Error: Could not find PortAudio static library"
    exit 1
fi
echo "Using PortAudio library: $PORTAUDIO_LIB"

gcc -o play_buffer ../builder/play_buffer.c -I./include "$PORTAUDIO_LIB" \
    -framework CoreAudio -framework AudioToolbox -framework AudioUnit -framework CoreFoundation -framework CoreServices
mkdir -p build/artifacts
cp play_buffer build/artifacts/