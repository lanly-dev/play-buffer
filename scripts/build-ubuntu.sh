#!/bin/bash
set -e

echo "Building PlayBuffer with locally built PortAudio..."

# Get version from environment or generate default
VERSION=${PLAYBUFFER_VERSION:-"dev-build"}
echo "Building version: $VERSION"

# Get PortAudio commit from environment
PORTAUDIO_COMMIT=${PORTAUDIO_COMMIT:-"unknown"}
echo "PortAudio commit: $PORTAUDIO_COMMIT"

# Check that PortAudio was built by CI workflow
if [ ! -d "portaudio/install" ]; then
    echo "Error: PortAudio not found. Expected at portaudio/install/"
    exit 1
fi

# Find PortAudio library
PA_LIB=$(find portaudio/install/lib -name "libportaudio*.a" | head -n 1)
if [ -z "$PA_LIB" ]; then
    echo "Error: Could not find PortAudio static library in portaudio/install/lib"
    exit 1
fi

echo "Found PortAudio library: $PA_LIB"

# Build play_buffer with version information
echo "Compiling play_buffer..."
gcc -o play_buffer play_buffer.c \
    -DPLAYBUFFER_VERSION="\"$VERSION\"" \
    -DPORTAUDIO_COMMIT="\"$PORTAUDIO_COMMIT\"" \
    -I portaudio/install/include \
    "$PA_LIB" \
    -lm -lpthread -lasound

# Create artifacts directory and copy executable
mkdir -p build/artifacts
cp play_buffer build/artifacts/

echo "PlayBuffer built successfully!"