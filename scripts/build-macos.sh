#!/bin/bash
set -e

echo "Building PlayBuffer with locally built PortAudio..."

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

# Build play_buffer
echo "Compiling play_buffer..."
gcc -o play_buffer play_buffer.c \
    -I portaudio/install/include \
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
echo "Using PortAudio library: $PORTAUDIO_LIB"

# Show the compilation command for debugging
echo "Compiling with command:"
echo "clang -v -o play_buffer ../builder/play_buffer.c -I./include \"$PORTAUDIO_LIB\" -framework CoreAudio -framework AudioToolbox -framework AudioUnit -framework CoreFoundation -framework CoreServices"

# Try using clang instead of gcc (more standard on macOS)
clang -v -o play_buffer ../builder/play_buffer.c -I./include "$PORTAUDIO_LIB" \
    -framework CoreAudio -framework AudioToolbox -framework AudioUnit -framework CoreFoundation -framework CoreServices

# Check compilation result
COMPILE_RESULT=$?
echo "Compilation exit code: $COMPILE_RESULT"

# If that fails, try alternative approach with explicit linking
if [ $COMPILE_RESULT -ne 0 ]; then
    echo "First compilation failed, trying alternative approach..."
    clang -v -o play_buffer ../builder/play_buffer.c -I./include \
        -L./build -lportaudio \
        -framework CoreAudio -framework AudioToolbox -framework AudioUnit -framework CoreFoundation -framework CoreServices
    COMPILE_RESULT=$?
    echo "Alternative compilation exit code: $COMPILE_RESULT"
fi

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