# Build PortAudio on Windows
New-Item -ItemType Directory -Force build
Set-Location build
cmake ..
cmake --build . --config Release