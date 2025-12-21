#!/bin/bash
set -e

echo "Building PlayBuffer with locally built PortAudio..."

# Get version from environment or generate default
VERSION=${PLAYBUFFER_VERSION:-"dev-build"}
echo "Building version: $VERSION"

# Get PortAudio commit from environment
PORTAUDIO_COMMIT=${PORTAUDIO_COMMIT:-"unknown"}
echo "PortAudio commit: $PORTAUDIO_COMMIT"

# Assume CI builds PortAudio into portaudio/install/ (workflow clones into repo root)
PA_PREFIX="portaudio/install"

# Ensure portaudio/install exists and find static library
if [ ! -d "$PA_PREFIX" ]; then
    echo "Error: PortAudio not found. Expected at portaudio/install/"
    exit 1
fi
PA_LIB=$(find "$PA_PREFIX/lib" -name "libportaudio*.a" | head -n 1)
if [ -z "$PA_LIB" ]; then
    echo "Error: Could not find PortAudio static library in $PA_PREFIX/lib"
    exit 1
fi

echo "Found PortAudio library: $PA_LIB"

# Build play_buffer with version information
echo "Compiling play_buffer..."
gcc -o play_buffer play_buffer.c \
    -DPLAYBUFFER_VERSION="\"$VERSION\"" \
    -DPORTAUDIO_COMMIT="\"$PORTAUDIO_COMMIT\"" \
    -I "$PA_PREFIX/include" \
    "$PA_LIB" \
    -framework CoreAudio \
    -framework CoreFoundation \
    -framework CoreServices \
    -framework AudioUnit \
    -framework AudioToolbox

# Create artifacts directory and copy executable
mkdir -p build/artifacts
cp play_buffer build/artifacts/

echo "PlayBuffer built successfully!"