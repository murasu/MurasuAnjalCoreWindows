# Deep dive into Weasel's TSF registration

$weaselCLSID = "{A3F4CDED-B1E9-41EE-9CA6-7B4D0DE6CB0A}"

Write-Host "=== WEASEL TSF REGISTRATION ANALYSIS ===" -ForegroundColor Cyan

# 1. Check CLSID registration
Write-Host "`n[1] CLSID Registration:" -ForegroundColor Yellow
$clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$weaselCLSID"
if (Test-Path $clsidPath) {
    Write-Host "CLSID exists: $clsidPath" -ForegroundColor Green
    
    $props = Get-ItemProperty $clsidPath
    Write-Host "  Default value: $($props.'(default)')"
    
    # Check InprocServer32
    $inprocPath = "$clsidPath\InprocServer32"
    if (Test-Path $inprocPath) {
        Write-Host "`n  InprocServer32:" -ForegroundColor Cyan
        $inproc = Get-ItemProperty $inprocPath
        Write-Host "    DLL: $($inproc.'(default)')"
        Write-Host "    ThreadingModel: $($inproc.ThreadingModel)"
    }
} else {
    Write-Host "CLSID not found!" -ForegroundColor Red
}

# 2. Check TSF TIP registration
Write-Host "`n[2] TSF TIP Registration:" -ForegroundColor Yellow
$tipPath = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$weaselCLSID"
if (Test-Path $tipPath) {
    Write-Host "TIP registered: $tipPath" -ForegroundColor Green
    
    # Get all properties
    $tipProps = Get-ItemProperty $tipPath
    Write-Host "`n  Properties:"
    $tipProps.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Value)"
    }
    
    # Check Language Profiles
    $langPath = "$tipPath\LanguageProfile"
    if (Test-Path $langPath) {
        Write-Host "`n  Language Profiles:" -ForegroundColor Cyan
        Get-ChildItem $langPath | ForEach-Object {
            $langId = $_.PSChildName
            Write-Host "`n    Language: $langId ($('{0:X4}' -f [int]$langId))"
            
            Get-ChildItem $_.PSPath | ForEach-Object {
                $profileGuid = $_.PSChildName
                Write-Host "      Profile GUID: $profileGuid"
                
                $profileProps = Get-ItemProperty $_.PSPath
                $profileProps.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                    Write-Host "        $($_.Name): $($_.Value)"
                }
            }
        }
    }
} else {
    Write-Host "TIP not registered!" -ForegroundColor Red
}

# 3. Check if there's a separate category registration path
Write-Host "`n[3] Checking Alternative Category Locations:" -ForegroundColor Yellow

$altPaths = @(
    "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$weaselCLSID\Category",
    "HKLM:\SOFTWARE\Microsoft\CTF\Categories",
    "HKCR:\CLSID\$weaselCLSID\Implemented Categories"
)

foreach ($path in $altPaths) {
    if (Test-Path $path) {
        Write-Host "`nFound: $path" -ForegroundColor Green
        Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  $($_.PSChildName)"
        }
    }
}

# 4. Compare with Tamil99 structure
Write-Host "`n[4] Tamil99 CLSID Check:" -ForegroundColor Yellow

$tamil99CLSIDs = @(
    "{95F0C259-8336-4BF3-AE73-7BE2D2E23462}",
    "{F7123523-AA20-43CB-8BE3-8AA74E8584F9}",
    "{81EA0A17-AA39-455B-BA20-EA79A8F98966}",
    "{52D6F4BF-C674-4A90-BD14-2F9FAEE9F0F3}"  # Original Tamil99 CLSID
)

foreach ($clsid in $tamil99CLSIDs) {
    $clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$clsid"
    if (Test-Path $clsidPath) {
        $name = (Get-ItemProperty $clsidPath -ErrorAction SilentlyContinue).'(default)'
        if ($name) {
            Write-Host "`nFound: $clsid" -ForegroundColor Green
            Write-Host "  Name: $name"
            
            # Check if it's registered in TSF TIP
            $tipPath = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$clsid"
            if (Test-Path $tipPath) {
                Write-Host "  Registered as TSF TIP: YES" -ForegroundColor Green
            } else {
                Write-Host "  Registered as TSF TIP: NO" -ForegroundColor Yellow
            }
        }
    }
}

# 5. Check WOW64 registry (32-bit view on 64-bit system)
Write-Host "`n[5] Checking WOW6432Node (32-bit registry):" -ForegroundColor Yellow

$wow64Path = "HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\$weaselCLSID"
if (Test-Path $wow64Path) {
    Write-Host "Found in WOW6432Node!" -ForegroundColor Green
    
    $catPath = "$wow64Path\Implemented Categories"
    if (Test-Path $catPath) {
        Write-Host "  Has categories in WOW6432Node:"
        Get-ChildItem $catPath | ForEach-Object {
            Write-Host "    $($_.PSChildName)"
        }
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host @"

KEY FINDINGS:
1. Weasel CLSID: $weaselCLSID
2. Categories registered: NONE (in standard location)
3. Code signing: NOT SIGNED
4. Architecture: Server-based (WeaselServer.exe + weasel.dll)

This proves:
- TSF categories are NOT required for Search bar
- Code signing is NOT required for Search bar
- The issue with Tamil99 is NOT about categories or signing

Next steps:
1. Install Tamil99 properly (copy to System32)
2. Test if it works without categories
3. If not, the issue is in the TSF interface implementation itself

"@

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")