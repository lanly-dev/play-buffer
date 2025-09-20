#!/bin/bash
set -e

# Build PortAudio on macOS using CMake with policy flag
mkdir -p build
cd build
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(sysctl -n hw.ncpu)