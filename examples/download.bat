@echo off
setlocal enabledelayedexpansion

echo Downloading latest PlayBuffer Windows build...

REM GitHub repository info
set "REPO_OWNER=lanly-dev"
set "REPO_NAME=play-buffer"
set "API_URL=https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest"

REM Output directory (current examples folder)
set "OUTPUT_DIR=%~dp0"

REM Temp file for API response
set "TEMP_JSON=%TEMP%\playbuffer_release.json"

echo Fetching latest release information...

REM Download release info using PowerShell
powershell -Command "try { Invoke-RestMethod -Uri '%API_URL%' -Headers @{'User-Agent'='BatchScript-PlayBuffer-Downloader'} | ConvertTo-Json -Depth 10 | Out-File '%TEMP_JSON%' -Encoding UTF8; exit 0 } catch { Write-Host 'Error fetching release info:' $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo Failed to fetch release information
    exit /b 1
)

echo Parsing release information...

REM Extract tag name and download URL using PowerShell
for /f "usebackq delims=" %%i in (`powershell -Command "$json = Get-Content '%TEMP_JSON%' | ConvertFrom-Json; Write-Host $json.tag_name"`) do set "TAG_NAME=%%i"

REM Find Windows asset download URL
for /f "usebackq delims=" %%i in (`powershell -Command "$json = Get-Content '%TEMP_JSON%' | ConvertFrom-Json; $asset = $json.assets | Where-Object { $_.name -like '*windows*' -or $_.name -like '*win*' -or $_.name -like '*play_buffer.exe*' } | Select-Object -First 1; if ($asset) { Write-Host $asset.browser_download_url } else { Write-Host 'NO_ASSET_FOUND' }"`) do set "DOWNLOAD_URL=%%i"

REM Find asset name
for /f "usebackq delims=" %%i in (`powershell -Command "$json = Get-Content '%TEMP_JSON%' | ConvertFrom-Json; $asset = $json.assets | Where-Object { $_.name -like '*windows*' -or $_.name -like '*win*' -or $_.name -like '*play_buffer.exe*' } | Select-Object -First 1; if ($asset) { Write-Host $asset.name } else { Write-Host 'play_buffer.exe' }"`) do set "ASSET_NAME=%%i"

if "%DOWNLOAD_URL%"=="NO_ASSET_FOUND" (
    echo Error: No Windows executable found in latest release
    echo Available assets:
    powershell -Command "$json = Get-Content '%TEMP_JSON%' | ConvertFrom-Json; $json.assets | ForEach-Object { Write-Host '  -' $_.name }"
    del "%TEMP_JSON%" 2>nul
    exit /b 1
)

echo Latest release: %TAG_NAME%
echo Found Windows asset: %ASSET_NAME%

REM Always save as play_buffer.exe in current directory
set "OUTPUT_PATH=%OUTPUT_DIR%\play_buffer.exe"

REM Remove existing file if present
if exist "%OUTPUT_PATH%" (
    echo Removing existing play_buffer.exe...
    del "%OUTPUT_PATH%"
)

echo Downloading %ASSET_NAME% as play_buffer.exe...

REM Download the file using PowerShell
powershell -Command "try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%OUTPUT_PATH%' -Headers @{'User-Agent'='BatchScript-PlayBuffer-Downloader'}; exit 0 } catch { Write-Host 'Error downloading file:' $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo Failed to download file
    del "%TEMP_JSON%" 2>nul
    exit /b 1
)

REM Clean up temp file
del "%TEMP_JSON%" 2>nul

echo Downloaded successfully: %OUTPUT_PATH%

REM Show file info
for %%F in ("%OUTPUT_PATH%") do (
    echo File size: %%~zF bytes
    echo Modified: %%~tF
)

echo.
echo PlayBuffer Windows executable is now available as play_buffer.exe!
echo You can run it with: play_buffer.exe

pause