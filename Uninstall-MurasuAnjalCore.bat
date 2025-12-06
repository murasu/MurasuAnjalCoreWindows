@echo off
REM Uninstall-MurasuAnjalCore.bat
REM Uninstallation script for Murasu Anjal Core TSF IME
REM Must be run as Administrator

echo ============================================
echo Murasu Anjal Core - Tamil99 IME Uninstallation
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

set DLL_PATH="%~dp0build\Release\MurasuAnjalCore.dll"

if not exist %DLL_PATH% (
    echo WARNING: MurasuAnjalCore.dll not found
    echo The IME may have already been uninstalled
    pause
    exit /b 0
)

echo Uninstalling Murasu Anjal Core Tamil99 IME...
echo.

REM Unregister the DLL
regsvr32 /u /s %DLL_PATH%

echo.
echo ============================================
echo Uninstallation Complete!
echo ============================================
echo.
pause
