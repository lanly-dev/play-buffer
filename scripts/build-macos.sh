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

# Verify source file exists
SOURCE_FILE="../builder/play_buffer.c"
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file not found at $SOURCE_FILE"
    echo "Current directory: $(pwd)"
    echo "Contents of ../builder/:"
    ls -la ../builder/
    exit 1
fi
echo "Source file found: $SOURCE_FILE"

# Find the actual library file
PORTAUDIO_LIB=$(find ./build -name "libportaudio*.a" | head -n 1)
if [ -z "$PORTAUDIO_LIB" ]; then
    echo "Error: Could not find PortAudio static library"
    exit 1
fi
echo "Using PortAudio library: $PORTAUDIO_LIB"

# Show the compilation command for debugging
echo "Compiling with command:"
echo "gcc -v -o play_buffer ../builder/play_buffer.c -I./include \"$PORTAUDIO_LIB\" -framework CoreAudio -framework AudioToolbox -framework AudioUnit -framework CoreFoundation -framework CoreServices"

# Execute the compilation with verbose output
gcc -v -o play_buffer ../builder/play_buffer.c -I./include "$PORTAUDIO_LIB" \
    -framework CoreAudio -framework AudioToolbox -framework AudioUnit -framework CoreFoundation -framework CoreServices

# Check compilation result
COMPILE_RESULT=$?
echo "Compilation exit code: $COMPILE_RESULT"

if [ $COMPILE_RESULT -ne 0 ]; then
    echo "Error: Compilation failed with exit code $COMPILE_RESULT"
    exit 1
fi

# Verify the executable was created and check its properties
if [ -f play_buffer ]; then
    echo "play_buffer executable created successfully"
    ls -la play_buffer
    file play_buffer
    chmod +x play_buffer
    echo "File permissions set to executable"
else
    echo "Error: play_buffer executable was not created despite successful compilation"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

mkdir -p build/artifacts
cp play_buffer build/artifacts/

# Verify the artifact
echo "Verifying artifact in build/artifacts:"
ls -la build/artifacts/
file build/artifacts/play_buffer
echo "Artifact verification complete"