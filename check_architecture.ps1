# Check DLL Architecture

Write-Host "=== DLL ARCHITECTURE CHECK ===" -ForegroundColor Cyan

function Get-DllArchitecture {
    param($path)
    
    if (-not (Test-Path $path)) {
        Write-Host "File not found: $path" -ForegroundColor Red
        return
    }
    
    Write-Host "`nAnalyzing: $path" -ForegroundColor Yellow
    
    # Read PE header to determine architecture
    $bytes = [System.IO.File]::ReadAllBytes($path)
    
    # Check DOS header
    if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
        Write-Host "  Not a valid PE file" -ForegroundColor Red
        return
    }
    
    # Get PE header offset
    $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
    
    # Check PE signature
    if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset+1] -ne 0x45) {
        Write-Host "  Invalid PE signature" -ForegroundColor Red
        return
    }
    
    # Get machine type (2 bytes after PE signature + 4 bytes)
    $machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
    
    $arch = switch ($machine) {
        0x014C { "x86 (32-bit)" }
        0x8664 { "x64 (64-bit)" }
        0xAA64 { "ARM64" }
        0x01C4 { "ARM" }
        default { "Unknown (0x{0:X4})" -f $machine }
    }
    
    Write-Host "  Architecture: $arch" -ForegroundColor Green
    Write-Host "  Machine Code: 0x$($machine.ToString('X4'))"
    Write-Host "  Size: $([Math]::Round($bytes.Length / 1KB, 2)) KB"
    
    return $arch
}

# Check your DLL in different locations
Write-Host "`n[1] Checking build directory DLLs:" -ForegroundColor Cyan

$buildDirs = @("ARM64\Release", "ARM64EC\Release", "x64\Release", "Release")
foreach ($dir in $buildDirs) {
    $dll = Join-Path $dir "MurasuAnjalCore.dll"
    if (Test-Path $dll) {
        Get-DllArchitecture $dll
    }
}

# Check System32
Write-Host "`n[2] Checking System32:" -ForegroundColor Cyan
$sys32Dll = "C:\WINDOWS\System32\MurasuAnjalCore.dll"
if (Test-Path $sys32Dll) {
    Get-DllArchitecture $sys32Dll
}

# Check Weasel for comparison
Write-Host "`n[3] Checking Weasel (for comparison):" -ForegroundColor Cyan

$weaselLocations = @(
    "C:\WINDOWS\System32\weasel.dll",
    "C:\WINDOWS\SysWOW64\weasel.dll",
    "C:\WINDOWS\System32\weaselARM64.dll",
    "C:\WINDOWS\System32\weaselx64.dll"
)

foreach ($loc in $weaselLocations) {
    if (Test-Path $loc) {
        Get-DllArchitecture $loc
    }
}

# Recommendations
Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host @"

Based on Weasel being in SysWOW64 (x86 32-bit), you should:

1. Build as x64 (64-bit), NOT ARM64
   - x64 will run under emulation on ARM64 Windows
   - This is what Weasel does (x86 under emulation)

2. Install to correct location:
   - x86 DLLs go to: C:\WINDOWS\SysWOW64\
   - x64 DLLs go to: C:\WINDOWS\System32\ (yes, confusing naming!)
   - ARM64 DLLs go to: C:\WINDOWS\System32\

3. Use correct regsvr32:
   - For x86: C:\WINDOWS\SysWOW64\regsvr32.exe
   - For x64: C:\WINDOWS\System32\regsvr32.exe (or just regsvr32)
   - For ARM64: C:\WINDOWS\System32\regsvr32.exe

Commands to rebuild as x64:

  msbuild MurasuAnjalCore.sln /t:Clean /p:Configuration=Release /p:Platform=x64
  msbuild MurasuAnjalCore.sln /t:Build /p:Configuration=Release /p:Platform=x64

Then install:

  copy x64\Release\MurasuAnjalCore.dll C:\WINDOWS\System32\
  regsvr32 C:\WINDOWS\System32\MurasuAnjalCore.dll

"@

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")