# Build PortAudio on Windows
New-Item -ItemType Directory -Force build
Set-Location build
# Configure CMake to use dynamic MSVC runtime (/MD) to match PortAudio's default import symbols
cmake .. -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreadedDLL"
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

# Prefer static library if available, otherwise fall back to import lib
$libFile = Get-ChildItem build -Recurse -Filter "*portaudio_static*.lib" | Select-Object -First 1
if (-not $libFile) { $libFile = Get-ChildItem build -Recurse -Filter "*portaudio*.lib" | Select-Object -First 1 }

if ($libFile) {
    Write-Host "Found PortAudio library at: $($libFile.FullName)"

    # System libraries commonly required by PortAudio backends on Windows
    $sysLibs = @(
        'kernel32.lib','user32.lib','advapi32.lib','ole32.lib','oleaut32.lib','uuid.lib',
        'winmm.lib','avrt.lib','mmdevapi.lib','ksuser.lib'
    )

    $sysLibsJoined = ($sysLibs -join ' ')
    $linkLib = $libFile.FullName

    Write-Host "Compiling play_buffer.exe..."
    $compileCmd = "`"$vcvars`" && cl /MD ..\builder\play_buffer.c /I .\include /link `"$linkLib`" $sysLibsJoined /OUT:play_buffer.exe"
    Write-Host "Link command: $compileCmd"
    cmd /c $compileCmd
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