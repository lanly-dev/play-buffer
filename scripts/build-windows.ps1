# Build PortAudio on Windows
New-Item -ItemType Directory -Force build
Set-Location build
cmake ..
cmake --build . --config Release

# Build play_buffer.exe
Set-Location ..
$env:INCLUDE = "$PWD\include;$env:INCLUDE"
$env:LIB = "$PWD\build\Release;$env:LIB"
cl ..\builder\play_buffer.c /I .\include /link /LIBPATH:build\Release portaudio_static.lib /OUT:play_buffer.exe
New-Item -ItemType Directory -Force -Path build\artifacts | Out-Null
Copy-Item play_buffer.exe build\artifacts\
cl play_buffer.c /I portaudio\include /link /LIBPATH:build portaudio.lib /OUT:play_buffer.exe
New-Item -ItemType Directory -Force -Path build\artifacts | Out-Null
Copy-Item play_buffer.exe build\artifacts\