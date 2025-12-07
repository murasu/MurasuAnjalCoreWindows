# Install Tamil99 with Static Runtime
# Run as Administrator

param(
    [string]$BuildDir = "ARM64EC\Release",
    [string]$DllName = "MurasuAnjalCore.dll"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== TAMIL99 INSTALLATION (Static Runtime) ===" -ForegroundColor Cyan

# Check admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    exit 1
}

$sourceDll = Join-Path $BuildDir $DllName
$systemDll = "C:\WINDOWS\System32\$DllName"

# 1. Verify source
Write-Host "`n[1] Checking source DLL..." -ForegroundColor Yellow

if (-not (Test-Path $sourceDll)) {
    Write-Host "ERROR: Source not found: $sourceDll" -ForegroundColor Red
    exit 1
}

$sourceInfo = Get-Item $sourceDll
Write-Host "  Source: $sourceDll" -ForegroundColor Green
Write-Host "  Size: $([Math]::Round($sourceInfo.Length / 1KB, 2)) KB"

if ($sourceInfo.Length -lt 100KB) {
    Write-Host "  WARNING: DLL seems small. Runtime might not be statically linked!" -ForegroundColor Yellow
    Write-Host "  Expected: ~300-500 KB with /MT"
} else {
    Write-Host "  Good! Size indicates static runtime linking ✓" -ForegroundColor Green
}

# 2. Stop text input services
Write-Host "`n[2] Stopping text input services..." -ForegroundColor Yellow

$procs = @("ctfmon", "TextInputHost", "SearchHost")
foreach ($p in $procs) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 1

# 3. Unregister old version
Write-Host "`n[3] Unregistering old version..." -ForegroundColor Yellow

if (Test-Path $systemDll) {
    $result = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/u","/s",$systemDll -Wait -PassThru -NoNewWindow
    Write-Host "  Unregistered (code: $($result.ExitCode))"
    
    Remove-Item $systemDll -Force -ErrorAction SilentlyContinue
}

# 4. Copy new version
Write-Host "`n[4] Copying to System32..." -ForegroundColor Yellow

Copy-Item $sourceDll $systemDll -Force
Write-Host "  Copied successfully ✓" -ForegroundColor Green

# 5. Register
Write-Host "`n[5] Registering with regsvr32..." -ForegroundColor Yellow

$result = Start-Process -FilePath "regsvr32.exe" -ArgumentList $systemDll -Wait -PassThru -WindowStyle Hidden

if ($result.ExitCode -eq 0) {
    Write-Host "  Registration SUCCESSFUL! ✓" -ForegroundColor Green
} else {
    Write-Host "  Registration FAILED with code: $($result.ExitCode)" -ForegroundColor Red
    Write-Host "  Trying verbose mode..."
    
    # Try without /s to see error
    & regsvr32.exe $systemDll
    exit 1
}

# 6. Verify
Write-Host "`n[6] Verifying installation..." -ForegroundColor Yellow

$tamil99CLSID = "{52D6F4BF-C674-4A90-BD14-2F9FAEE9F0F3}"

$checks = @(
    @{ Name = "CLSID"; Path = "HKLM:\SOFTWARE\Classes\CLSID\$tamil99CLSID" },
    @{ Name = "TSF TIP"; Path = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$tamil99CLSID" }
)

$allGood = $true
foreach ($check in $checks) {
    if (Test-Path $check.Path) {
        Write-Host "  $($check.Name): Registered ✓" -ForegroundColor Green
    } else {
        Write-Host "  $($check.Name): NOT registered ✗" -ForegroundColor Red
        $allGood = $false
    }
}

# 7. Check categories (should be none, like Weasel)
Write-Host "`n[7] Checking categories..." -ForegroundColor Yellow

$catPath = "HKLM:\SOFTWARE\Classes\CLSID\$tamil99CLSID\Implemented Categories"
if (Test-Path $catPath) {
    $cats = Get-ChildItem $catPath
    Write-Host "  Categories: $($cats.Count) registered"
    Write-Host "  (Note: Weasel has 0 categories and works fine)" -ForegroundColor Yellow
} else {
    Write-Host "  Categories: NONE (like Weasel!) ✓" -ForegroundColor Green
}

# 8. Restart services
Write-Host "`n[8] Restarting text services..." -ForegroundColor Yellow
Start-Process "ctfmon.exe" -ErrorAction SilentlyContinue

if ($allGood) {
    Write-Host "`n=== INSTALLATION SUCCESSFUL ===" -ForegroundColor Green
    Write-Host @"

Tamil99 is now installed!

CRITICAL TEST - Try in this order:
1. ✓ Notepad (should work - standard desktop app)
2. ✓ Settings app (should work - UWP app)  
3. ⭐ WINDOWS SEARCH BAR ← THE MOMENT OF TRUTH!

To enable Tamil99:
1. Win+I → Time & Language → Language & Region
2. Click Tamil (India) → Options
3. Add Tamil99 keyboard
4. Switch to Tamil99 and test!

If Search bar works → 🎉 VICTORY!
If Search bar doesn't work → We need to look at the code itself

"@
} else {
    Write-Host "`n=== INSTALLATION FAILED ===" -ForegroundColor Red
    Write-Host "Check the errors above"
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")