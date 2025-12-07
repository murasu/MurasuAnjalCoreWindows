# Tamil99 Troubleshooting Script
# Run as Administrator

$ErrorActionPreference = "Continue"

Write-Host "`n=== TAMIL99 DLL TROUBLESHOOTING ===" -ForegroundColor Cyan

$systemDll = "C:\WINDOWS\System32\MurasuAnjalCore.dll"
$tamil99CLSID = "{52D6F4BF-C674-4A90-BD14-2F9FAEE9F0F3}"

# 1. Check if DLL exists and is locked
Write-Host "`n[1] Checking DLL status..." -ForegroundColor Yellow

if (Test-Path $systemDll) {
    $dllInfo = Get-Item $systemDll
    Write-Host "  DLL exists: $systemDll"
    Write-Host "  Size: $([Math]::Round($dllInfo.Length / 1KB, 2)) KB"
    Write-Host "  Last Modified: $($dllInfo.LastWriteTime)"
    
    # Try to find which process is using it
    Write-Host "`n  Checking for processes using the DLL..." -ForegroundColor Cyan
    
    # Use handle.exe if available, otherwise use PowerShell method
    $handles = Get-Process | Where-Object {
        $_.Modules.FileName -contains $systemDll
    } -ErrorAction SilentlyContinue
    
    if ($handles) {
        Write-Host "  WARNING: DLL is in use by:" -ForegroundColor Red
        $handles | ForEach-Object {
            Write-Host "    Process: $($_.Name) (PID: $($_.Id))"
            Write-Host "    Path: $($_.Path)"
        }
        
        Write-Host "`n  Recommendation: Kill these processes before reinstalling" -ForegroundColor Yellow
    } else {
        Write-Host "  DLL is not currently in use" -ForegroundColor Green
    }
} else {
    Write-Host "  DLL not found at $systemDll" -ForegroundColor Yellow
}

# 2. Check DLL architecture and dependencies
Write-Host "`n[2] Checking DLL architecture and dependencies..." -ForegroundColor Yellow

if (Test-Path $systemDll) {
    # Check if it's a valid DLL
    try {
        $sig = Get-AuthenticodeSignature $systemDll
        Write-Host "  Signature Status: $($sig.Status)"
    } catch {
        Write-Host "  Warning: Could not check signature" -ForegroundColor Yellow
    }
    
    # Try to load and check exports
    Write-Host "`n  Checking DLL exports..." -ForegroundColor Cyan
    
    # Use dumpbin if available (from VS)
    $dumpbin = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\arm64\dumpbin.exe"
    $dumpbinPath = Get-Item $dumpbin -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($dumpbinPath) {
        Write-Host "  Using dumpbin to check exports..."
        & $dumpbinPath /exports $systemDll | Select-String "DllRegisterServer|DllUnregisterServer|DllGetClassObject"
    } else {
        Write-Host "  dumpbin not found (need Visual Studio)" -ForegroundColor Yellow
    }
}

# 3. Check registry registration
Write-Host "`n[3] Checking registry registration..." -ForegroundColor Yellow

$clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$tamil99CLSID"
if (Test-Path $clsidPath) {
    Write-Host "  CLSID registered: YES" -ForegroundColor Green
    
    $inprocPath = "$clsidPath\InprocServer32"
    if (Test-Path $inprocPath) {
        $inproc = Get-ItemProperty $inprocPath
        Write-Host "  InprocServer32: $($inproc.'(default)')"
        Write-Host "  ThreadingModel: $($inproc.ThreadingModel)"
    }
} else {
    Write-Host "  CLSID NOT registered" -ForegroundColor Red
}

$tipPath = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$tamil99CLSID"
if (Test-Path $tipPath) {
    Write-Host "  TSF TIP registered: YES" -ForegroundColor Green
} else {
    Write-Host "  TSF TIP NOT registered" -ForegroundColor Red
}

# 4. Compare with Weasel's registration
Write-Host "`n[4] Comparing with Weasel..." -ForegroundColor Yellow

$weaselCLSID = "{A3F4CDED-B1E9-41EE-9CA6-7B4D0DE6CB0A}"
$weaselClsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$weaselCLSID\InprocServer32"

if (Test-Path $weaselClsidPath) {
    $weaselInproc = Get-ItemProperty $weaselClsidPath
    Write-Host "  Weasel DLL: $($weaselInproc.'(default)')"
    
    if (Test-Path $weaselInproc.'(default)') {
        $weaselDll = Get-Item $weaselInproc.'(default)'
        Write-Host "  Weasel Size: $([Math]::Round($weaselDll.Length / 1KB, 2)) KB"
    }
}

# 5. Solutions
Write-Host "`n=== SOLUTIONS ===" -ForegroundColor Cyan

Write-Host @"

Problem 1: DLL is locked
Solution: 
  1. Unregister first: regsvr32 /u C:\WINDOWS\System32\MurasuAnjalCore.dll
  2. Kill any ctfmon.exe or TextInputHost.exe processes
  3. Then re-register

Problem 2: Missing dependencies / Architecture mismatch
Solution:
  1. Check build configuration (ARM64EC might not be correct)
  2. Try building as ARM64 native instead
  3. Check dependencies with Dependency Walker or dumpbin
  
Commands to try:

# Unregister and clean
regsvr32 /u C:\WINDOWS\System32\MurasuAnjalCore.dll
taskkill /F /IM ctfmon.exe
taskkill /F /IM TextInputHost.exe
del C:\WINDOWS\System32\MurasuAnjalCore.dll

# Copy fresh version
copy ARM64EC\Release\MurasuAnjalCore.dll C:\WINDOWS\System32\

# Register
regsvr32 C:\WINDOWS\System32\MurasuAnjalCore.dll

Alternative: Try building as ARM64 native instead of ARM64EC

"@

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")