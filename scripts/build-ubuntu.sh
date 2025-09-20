#!/bin/bash
set -e

# Build PortAudio on Ubuntu
mkdir -p build
cd build
cmake ..
make -j$(nproc)

# Build the play_buffer example
cd ..
gcc -o play_buffer play_buffer.c -Iportaudio/include -Lbuild -lportaudio
mkdir -p build/artifacts
cp play_buffer build/artifacts/
mkdir -p build/artifacts
cp play_buffer build/artifacts/