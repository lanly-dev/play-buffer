# Build PortAudio on Windows
New-Item -ItemType Directory -Force build
Set-Location build
cmake ..
cmake --build . --config Release

# Build play_buffer.exe
Set-Location ..

# Debug: Check what was actually built
Write-Host "Contents of build directory:"
Get-ChildItem build -Recurse -Name "*.lib" | Write-Host
Write-Host "Looking for PortAudio libraries..."
Get-ChildItem build -Recurse -Filter "*.lib" | ForEach-Object { Write-Host $_.FullName }

# Use Visual Studio's vcvars to setup environment, then compile
Write-Host "Setting up Visual Studio environment..."
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$installPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$vcvars = "$installPath\VC\Auxiliary\Build\vcvars64.bat"

# Find the actual library file
$libFile = Get-ChildItem build -Recurse -Filter "*portaudio*.lib" | Select-Object -First 1
if ($libFile) {
    Write-Host "Found PortAudio library at: $($libFile.FullName)"
    
    Write-Host "Compiling play_buffer.exe..."
    # Use the full path to the library file directly, like we do in macOS
    # Use /MT for static runtime linking and add required Windows libraries
    cmd /c "`"$vcvars`" && cl /MT ..\builder\play_buffer.c /I .\include /link `"$($libFile.FullName)`" kernel32.lib user32.lib advapi32.lib ole32.lib winmm.lib /OUT:play_buffer.exe"
} else {
    Write-Host "Error: Could not find PortAudio library file"
    exit 1
}

# Verify and copy the executable
if (Test-Path "play_buffer.exe") {
    Write-Host "play_buffer.exe created successfully"
    New-Item -ItemType Directory -Force -Path build\artifacts | Out-Null
    Copy-Item play_buffer.exe build\artifacts\
} else {
    Write-Host "Error: play_buffer.exe was not created"
    exit 1
}