#!/bin/sh
set -e

# Build PortAudio on Ubuntu
mkdir -p build
cd build
cmake ..
make -j$(nproc 2>/dev/null || echo 4)

# Build the play_buffer example
cd ..
gcc -o play_buffer ../builder/play_buffer.c -I./include -L./build -lportaudio -lm -lpthread -lasound
mkdir -p build/artifacts
cp play_buffer build/artifacts/