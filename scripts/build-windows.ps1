# Build PortAudio on Windows
Set-Location portaudio
New-Item -ItemType Directory -Force build
Set-Location build
cmake ..
cmake --build . --config Release