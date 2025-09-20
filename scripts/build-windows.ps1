$env:INCLUDE = "$PWD\portaudio\include;$env:INCLUDE"
$env:LIB = "$PWD\build;$env:LIB"
cl play_buffer.c /I portaudio\include /link /LIBPATH:build portaudio.lib /OUT:play_buffer.exe
New-Item -ItemType Directory -Force -Path build\artifacts | Out-Null
Copy-Item play_buffer.exe build\artifacts\
# Build PortAudio on Windows
New-Item -ItemType Directory -Force build
Set-Location build
cmake ..
cmake --build . --config Release

# Build play_buffer.exe
Set-Location ..
$env:INCLUDE = "$PWD\portaudio\include;$env:INCLUDE"
$env:LIB = "$PWD\build;$env:LIB"
cl play_buffer.c /I portaudio\include /link /LIBPATH:build portaudio.lib /OUT:play_buffer.exe
New-Item -ItemType Directory -Force -Path build\artifacts | Out-Null
Copy-Item play_buffer.exe build\artifacts\