# Build PortAudio on Windows
New-Item -ItemType Directory -Force build
Set-Location build
cmake ..
cmake --build . --config Release

# Build play_buffer.exe
Set-Location ..

# Use Visual Studio's vcvars to setup environment, then compile
Write-Host "Setting up Visual Studio environment..."
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$installPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$vcvars = "$installPath\VC\Auxiliary\Build\vcvars64.bat"

Write-Host "Compiling play_buffer.exe..."
cmd /c "`"$vcvars`" && cl ..\builder\play_buffer.c /I .\include /link /LIBPATH:build\Release portaudio_static.lib /OUT:play_buffer.exe"

# Verify and copy the executable
if (Test-Path "play_buffer.exe") {
    Write-Host "play_buffer.exe created successfully"
    New-Item -ItemType Directory -Force -Path build\artifacts | Out-Null
    Copy-Item play_buffer.exe build\artifacts\
} else {
    Write-Host "Error: play_buffer.exe was not created"
    exit 1
}