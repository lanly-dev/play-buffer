#!/bin/bash
set -e

# Build PortAudio on Ubuntu
cd portaudio
mkdir build
cd build
cmake ..
make -j$(nproc)