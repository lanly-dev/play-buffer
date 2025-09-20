#!/bin/bash
set -e

# Build PortAudio on macOS
mkdir build
cd build
cmake ..
make -j$(sysctl -n hw.ncpu)