#!/bin/bash
set -e

# Build PortAudio on Ubuntu
mkdir -p build
cd build
cmake ..
make -j$(nproc)