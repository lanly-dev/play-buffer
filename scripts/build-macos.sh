#!/bin/bash
set -e

# Build PortAudio on macOS
mkdir -p build
cd build
cmake ..
make -j$(sysctl -n hw.ncpu)