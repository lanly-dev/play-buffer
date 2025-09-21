# Build PlayBuffer on Windows
Write-Host "Building PlayBuffer with locally built PortAudio..."

# PortAudio should already be built by the CI workflow at ./portaudio/install/
if (-not (Test-Path "portaudio\install\lib")) {
    Write-Host "Error: PortAudio not found. Expected at portaudio\install\"
    exit 1
}

# Find PortAudio library
$paLib = Get-ChildItem "portaudio\install\lib" -Filter "*portaudio*.lib" | Select-Object -First 1
if (-not $paLib) {
    Write-Host "Error: Could not find PortAudio library in portaudio\install\lib"
    exit 1
}

Write-Host "Found PortAudio library: $($paLib.FullName)"

# Setup Visual Studio environment
Write-Host "Setting up Visual Studio environment..."
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $installPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    $vcvars = "$installPath\VC\Auxiliary\Build\vcvars64.bat"
} else {
    Write-Host "Warning: vswhere not found, using fallback compiler detection"
    $vcvars = ""
}

# System libraries for PortAudio on Windows
$sysLibs = @(
    'kernel32.lib','user32.lib','advapi32.lib','ole32.lib','oleaut32.lib','uuid.lib',
    'winmm.lib','avrt.lib','mmdevapi.lib','ksuser.lib'
)
$sysLibsJoined = ($sysLibs -join ' ')

# Compile play_buffer.exe
Write-Host "Compiling play_buffer.exe..."
$includeDir = "portaudio\install\include"
$sourceFile = "play_buffer.c"

if ($vcvars) {
    $compileCmd = "`"$vcvars`" && cl /MD `"$sourceFile`" /I `"$includeDir`" /link `"$($paLib.FullName)`" $sysLibsJoined /OUT:play_buffer.exe"
} else {
    $compileCmd = "cl /MD `"$sourceFile`" /I `"$includeDir`" /link `"$($paLib.FullName)`" $sysLibsJoined /OUT:play_buffer.exe"
}

Write-Host "Compile command: $compileCmd"
$result = cmd /c $compileCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed with exit code: $LASTEXITCODE"
    Write-Host "Output: $result"
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