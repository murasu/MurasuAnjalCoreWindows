# Investigation Script: Compare Weasel with Tamil99 IME
# Run this in PowerShell as Administrator

Write-Host "`n==== WEASEL IME INVESTIGATION ====" -ForegroundColor Cyan
Write-Host "This script compares Weasel with Tamil99 to find differences`n"

# 1. Find Weasel's CLSID
Write-Host "`n[1] Finding Weasel CLSID..." -ForegroundColor Yellow
$weaselCLSID = $null
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\CTF\TIP" | ForEach-Object {
    $desc = $_.GetValue("DescriptionString")
    if ($desc -like "*Weasel*" -or $desc -like "*Rime*" -or $desc -like "*小狼毫*") {
        $weaselCLSID = $_.PSChildName
        Write-Host "Found Weasel CLSID: $weaselCLSID" -ForegroundColor Green
        Write-Host "Description: $desc"
    }
}

if (-not $weaselCLSID) {
    Write-Host "ERROR: Could not find Weasel CLSID!" -ForegroundColor Red
    Write-Host "Is Weasel installed?"
    exit 1
}

# Tamil99 CLSID for comparison
$tamil99CLSID = "{52D6F4BF-C674-4A90-BD14-2F9FAEE9F0F3}"

# 2. Compare Registered Categories
Write-Host "`n[2] Comparing Registered Categories..." -ForegroundColor Yellow

Write-Host "`n--- Weasel Categories ---" -ForegroundColor Cyan
$weaselCategoriesPath = "HKLM:\SOFTWARE\Classes\CLSID\$weaselCLSID\Implemented Categories"
if (Test-Path $weaselCategoriesPath) {
    $weaselCategories = Get-ChildItem $weaselCategoriesPath | Select-Object -ExpandProperty PSChildName
    $weaselCategories | ForEach-Object {
        Write-Host "  $_"
    }
    Write-Host "Total: $($weaselCategories.Count) categories"
} else {
    Write-Host "  No categories found at: $weaselCategoriesPath" -ForegroundColor Red
}

Write-Host "`n--- Tamil99 Categories ---" -ForegroundColor Cyan
$tamil99CategoriesPath = "HKLM:\SOFTWARE\Classes\CLSID\$tamil99CLSID\Implemented Categories"
if (Test-Path $tamil99CategoriesPath) {
    $tamil99Categories = Get-ChildItem $tamil99CategoriesPath | Select-Object -ExpandProperty PSChildName
    $tamil99Categories | ForEach-Object {
        Write-Host "  $_"
    }
    Write-Host "Total: $($tamil99Categories.Count) categories"
} else {
    Write-Host "  No categories found!" -ForegroundColor Red
}

# 3. Check for Search-specific interfaces
Write-Host "`n[3] Checking for Search Integration Categories..." -ForegroundColor Yellow

$searchCategory = "{E2449140-85C2-4E9D-A01A-97FAD71A7CD3}" # GUID_TFCAT_SEARCHANDNAVIGATION
$integratableCategory = "{A5C559E3-5E85-40D9-95DD-597D05150C43}" # GUID_TFCAT_TIPCAP_INPUTMODECOMPARTMENT

Write-Host "`nWeasel has SEARCHANDNAVIGATION? $($weaselCategories -contains $searchCategory)" -ForegroundColor $(if ($weaselCategories -contains $searchCategory) { "Green" } else { "Yellow" })
Write-Host "Tamil99 has SEARCHANDNAVIGATION? $($tamil99Categories -contains $searchCategory)" -ForegroundColor $(if ($tamil99Categories -contains $searchCategory) { "Green" } else { "Yellow" })

Write-Host "`nWeasel has INPUTMODECOMPARTMENT? $($weaselCategories -contains $integratableCategory)" -ForegroundColor $(if ($weaselCategories -contains $integratableCategory) { "Green" } else { "Yellow" })
Write-Host "Tamil99 has INPUTMODECOMPARTMENT? $($tamil99Categories -contains $integratableCategory)" -ForegroundColor $(if ($tamil99Categories -contains $integratableCategory) { "Green" } else { "Yellow" })

# 4. Find and Check Weasel DLLs
Write-Host "`n[4] Finding Weasel DLL files..." -ForegroundColor Yellow

$systemDir = [Environment]::GetFolderPath("System")
$weaselFiles = Get-ChildItem $systemDir -Filter "weasel*.dll" -ErrorAction SilentlyContinue

if ($weaselFiles) {
    foreach ($file in $weaselFiles) {
        Write-Host "`nFile: $($file.Name)" -ForegroundColor Cyan
        Write-Host "  Path: $($file.FullName)"
        Write-Host "  Size: $([Math]::Round($file.Length / 1KB, 2)) KB"
        
        # Check code signing
        $sig = Get-AuthenticodeSignature $file.FullName
        Write-Host "  Signed: $($sig.Status)"
        if ($sig.Status -eq "Valid") {
            Write-Host "  Signer: $($sig.SignerCertificate.Subject)"
            Write-Host "  Issuer: $($sig.SignerCertificate.Issuer)"
            Write-Host "  Valid From: $($sig.SignerCertificate.NotBefore)"
            Write-Host "  Valid Until: $($sig.SignerCertificate.NotAfter)"
        }
    }
} else {
    Write-Host "No weasel*.dll files found in System32!" -ForegroundColor Red
}

# 5. Compare with Tamil99 DLL
Write-Host "`n[5] Checking Tamil99 DLL..." -ForegroundColor Yellow
$tamil99File = Get-Item "$systemDir\MurasuAnjal.dll" -ErrorAction SilentlyContinue
if ($tamil99File) {
    Write-Host "`nFile: $($tamil99File.Name)" -ForegroundColor Cyan
    Write-Host "  Path: $($tamil99File.FullName)"
    Write-Host "  Size: $([Math]::Round($tamil99File.Length / 1KB, 2)) KB"
    
    $sig = Get-AuthenticodeSignature $tamil99File.FullName
    Write-Host "  Signed: $($sig.Status)"
    if ($sig.Status -eq "Valid") {
        Write-Host "  Signer: $($sig.SignerCertificate.Subject)"
        Write-Host "  Issuer: $($sig.SignerCertificate.Issuer)"
    }
}

# 6. Check for WeaselServer process
Write-Host "`n[6] Checking for WeaselServer process..." -ForegroundColor Yellow
$weaselProcess = Get-Process -Name "WeaselServer" -ErrorAction SilentlyContinue
if ($weaselProcess) {
    Write-Host "WeaselServer.exe is RUNNING" -ForegroundColor Green
    Write-Host "  Path: $($weaselProcess.Path)"
    Write-Host "  PID: $($weaselProcess.Id)"
} else {
    Write-Host "WeaselServer.exe is NOT running" -ForegroundColor Yellow
}

# 7. Check registry for language registration
Write-Host "`n[7] Checking Language Registration..." -ForegroundColor Yellow

# Weasel language profile
$tipPath = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$weaselCLSID"
if (Test-Path $tipPath) {
    $languageProfiles = Get-ChildItem "$tipPath\LanguageProfile" -ErrorAction SilentlyContinue
    if ($languageProfiles) {
        Write-Host "`nWeasel Language Profiles:"
        foreach ($lang in $languageProfiles) {
            Write-Host "  LANGID: $($lang.PSChildName)"
            $profiles = Get-ChildItem $lang.PSPath
            foreach ($profile in $profiles) {
                $desc = $profile.GetValue("Description")
                Write-Host "    Profile: $($profile.PSChildName) - $desc"
            }
        }
    }
}

# 8. Summary
Write-Host "`n==== SUMMARY ====" -ForegroundColor Cyan
Write-Host "`nKey Differences:"

# Category count
$diffCount = $weaselCategories.Count - $tamil99Categories.Count
Write-Host "  Categories: Weasel=$($weaselCategories.Count), Tamil99=$($tamil99Categories.Count) (diff: $diffCount)"

# Categories only in Weasel
$onlyInWeasel = $weaselCategories | Where-Object { $_ -notin $tamil99Categories }
if ($onlyInWeasel) {
    Write-Host "`nCategories ONLY in Weasel:"
    $onlyInWeasel | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Yellow
    }
}

# Categories only in Tamil99
$onlyInTamil99 = $tamil99Categories | Where-Object { $_ -notin $weaselCategories }
if ($onlyInTamil99) {
    Write-Host "`nCategories ONLY in Tamil99:"
    $onlyInTamil99 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Yellow
    }
}

Write-Host "`n==== INVESTIGATION COMPLETE ====" -ForegroundColor Cyan
Write-Host "`nNext steps:"
Write-Host "1. Review category differences above"
Write-Host "2. Check Weasel source code on GitHub"
Write-Host "3. Update Tamil99 registration to match Weasel"
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")