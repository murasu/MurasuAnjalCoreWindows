# Tamil99 IME Installation Script
# Run as Administrator

param(
    [string]$BuildDir = ".",
    [string]$DllName = "MurasuAnjalCore.dll"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== TAMIL99 IME INSTALLATION ===" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'"
    exit 1
}

# 1. Find the DLL
$sourceDll = Join-Path $BuildDir $DllName
if (-not (Test-Path $sourceDll)) {
    Write-Host "ERROR: Could not find $DllName at $sourceDll" -ForegroundColor Red
    exit 1
}

Write-Host "`n[1] Source DLL found:" -ForegroundColor Green
Write-Host "    $sourceDll"
Write-Host "    Size: $([Math]::Round((Get-Item $sourceDll).Length / 1KB, 2)) KB"

# 2. Unregister old version if exists
Write-Host "`n[2] Unregistering old version..." -ForegroundColor Yellow

$systemDll = Join-Path $env:SystemRoot "System32\$DllName"
if (Test-Path $systemDll) {
    Write-Host "    Old version exists, unregistering..."
    try {
        & regsvr32.exe /u /s $systemDll
        Write-Host "    Unregistered" -ForegroundColor Green
    } catch {
        Write-Host "    Warning: Could not unregister: $_" -ForegroundColor Yellow
    }
}

# 3. Copy to System32
Write-Host "`n[3] Copying to System32..." -ForegroundColor Yellow

try {
    Copy-Item $sourceDll $systemDll -Force
    Write-Host "    Copied to: $systemDll" -ForegroundColor Green
} catch {
    Write-Host "    ERROR: Failed to copy: $_" -ForegroundColor Red
    exit 1
}

# 4. Register the DLL
Write-Host "`n[4] Registering Tamil99 IME..." -ForegroundColor Yellow

try {
    $result = & regsvr32.exe /s $systemDll 2>&1
    $lastExit = $LASTEXITCODE
    
    if ($lastExit -eq 0) {
        Write-Host "    Registration successful!" -ForegroundColor Green
    } else {
        Write-Host "    ERROR: Registration failed with code $lastExit" -ForegroundColor Red
        Write-Host "    Try running manually: regsvr32 $systemDll"
        exit 1
    }
} catch {
    Write-Host "    ERROR: $_" -ForegroundColor Red
    exit 1
}

# 5. Verify registration
Write-Host "`n[5] Verifying registration..." -ForegroundColor Yellow

$tamil99CLSID = "{52D6F4BF-C674-4A90-BD14-2F9FAEE9F0F3}"

$clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$tamil99CLSID"
if (Test-Path $clsidPath) {
    Write-Host "    CLSID registered: YES" -ForegroundColor Green
    
    $tipPath = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$tamil99CLSID"
    if (Test-Path $tipPath) {
        Write-Host "    TSF TIP registered: YES" -ForegroundColor Green
    } else {
        Write-Host "    TSF TIP registered: NO" -ForegroundColor Yellow
    }
} else {
    Write-Host "    ERROR: CLSID not found in registry!" -ForegroundColor Red
    exit 1
}

# 6. Check if categories exist
Write-Host "`n[6] Checking category registration..." -ForegroundColor Yellow

$catPath = "HKLM:\SOFTWARE\Classes\CLSID\$tamil99CLSID\Implemented Categories"
if (Test-Path $catPath) {
    $categories = Get-ChildItem $catPath
    Write-Host "    Categories registered: $($categories.Count)" -ForegroundColor Green
    $categories | ForEach-Object {
        Write-Host "      $($_.PSChildName)"
    }
} else {
    Write-Host "    Categories registered: NONE (like Weasel!)" -ForegroundColor Yellow
}

Write-Host "`n=== INSTALLATION COMPLETE ===" -ForegroundColor Green
Write-Host @"

Next steps:
1. Open Settings > Time & Language > Language & Region
2. Add Tamil (India) if not already added
3. Click Options on Tamil
4. Add Tamil99 keyboard
5. Test in:
   - Notepad (should work)
   - Settings app (should work)
   - Windows Search bar (TEST THIS!)

"@

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")