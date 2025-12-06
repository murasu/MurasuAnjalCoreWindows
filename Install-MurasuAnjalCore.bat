@echo off
REM Install-MurasuAnjalCore.bat
REM Installation script for Murasu Anjal Core TSF IME
REM Must be run as Administrator

echo ============================================
echo Murasu Anjal Core - Tamil99 IME Installation
echo ============================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Determine architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set DLL_PATH="%~dp0build\Release\MurasuAnjalCore.dll"
) else (
    set DLL_PATH="%~dp0build\Release\MurasuAnjalCore.dll"
)

if not exist %DLL_PATH% (
    echo ERROR: MurasuAnjalCore.dll not found
    echo Please build the project first using Visual Studio
    pause
    exit /b 1
)

echo Installing Murasu Anjal Core Tamil99 IME...
echo.

REM Register the DLL
regsvr32 /s %DLL_PATH%
if %errorLevel% neq 0 (
    echo ERROR: Registration failed
    pause
    exit /b 1
)

echo.
echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo Next steps:
echo 1. Go to Settings ^> Time ^& Language ^> Language ^& region
echo 2. Click "Add a language"
echo 3. Search for "Tamil"
echo 4. Add Tamil language
echo 5. Click Options next to Tamil
echo 6. Under Keyboards, you should see "Murasu Anjal Core - Tamil99"
echo 7. Configure the floating language bar (see README.md)
echo.
echo For Respondus LockDown Browser:
echo - Enable floating desktop language bar
echo - Set up keyboard hotkeys for switching
echo.
pause
