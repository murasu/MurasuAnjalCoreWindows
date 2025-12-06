# Cleanup-MurasuAnjalCore.ps1
# Run as Administrator

$oldCLSID = "{22431C85-48F9-48C0-A15D-FF1479A1753B}"
$oldProfileGUID = "{1010D39A-DA70-4B28-8D00-A9B500C5B3BD}"
$dllPath = "C:\Users\nedum\Projects\MurasuAnjalCore\ARM64EC\Debug\MurasuAnjalCore.dll"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Complete IME Cleanup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Unregister DLL
Write-Host "Step 1: Unregistering DLL..." -ForegroundColor Yellow
if (Test-Path $dllPath) {
    Start-Process regsvr32 -ArgumentList "/u /s `"$dllPath`"" -Wait -NoNewWindow
    Write-Host "  DLL unregistered" -ForegroundColor Green
} else {
    Write-Host "  DLL not found, skipping" -ForegroundColor Gray
}

# 2. Delete CLSID from HKCR
Write-Host "Step 2: Deleting CLSID from HKEY_CLASSES_ROOT..." -ForegroundColor Yellow
$clsidPath = "HKCR:\CLSID\$oldCLSID"
if (Test-Path $clsidPath) {
    Remove-Item -Path $clsidPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  CLSID deleted" -ForegroundColor Green
} else {
    Write-Host "  CLSID not found" -ForegroundColor Gray
}

# 3. Delete TIP registration
Write-Host "Step 3: Deleting TIP registration..." -ForegroundColor Yellow
$tipPath = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$oldCLSID"
if (Test-Path $tipPath) {
    Remove-Item -Path $tipPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  TIP registration deleted" -ForegroundColor Green
} else {
    Write-Host "  TIP not found" -ForegroundColor Gray
}

# 4. Remove from Tamil language settings
Write-Host "Step 4: Removing from Tamil language settings..." -ForegroundColor Yellow
$langList = Get-WinUserLanguageList
$tamilLang = $langList | Where-Object { $_.LanguageTag -eq "ta-IN" }
if ($tamilLang) {
    $oldIME = "0449:$oldCLSID$oldProfileGUID"
    if ($tamilLang.InputMethodTips -contains $oldIME) {
        $tamilLang.InputMethodTips.Remove($oldIME)
        Set-WinUserLanguageList $langList -Force
        Write-Host "  Removed from Tamil InputMethodTips" -ForegroundColor Green
    } else {
        Write-Host "  Not in InputMethodTips" -ForegroundColor Gray
    }
} else {
    Write-Host "  Tamil language not found" -ForegroundColor Gray
}

# 5. Restart CTF service
Write-Host "Step 5: Restarting CTF service..." -ForegroundColor Yellow
Stop-Process -Name ctfmon -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process ctfmon -ErrorAction SilentlyContinue
Write-Host "  CTF service restarted" -ForegroundColor Green

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Generate new GUIDs in PowerShell:" -ForegroundColor White
Write-Host "   [guid]::NewGuid().ToString().ToUpper()" -ForegroundColor Gray
Write-Host "   [guid]::NewGuid().ToString().ToUpper()" -ForegroundColor Gray
Write-Host "2. Update include\MurasuAnjalCore.h with new GUIDs" -ForegroundColor White
Write-Host "3. Rebuild in Release|ARM64EC" -ForegroundColor White
Write-Host "4. Register the new DLL" -ForegroundColor White
Write-Host "5. Restart Windows" -ForegroundColor White
Write-Host ""