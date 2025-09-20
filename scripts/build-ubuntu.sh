#!/bin/bash
set -e

# Build PortAudio on Ubuntu
mkdir build
cd build
cmake ..
make -j$(nproc)