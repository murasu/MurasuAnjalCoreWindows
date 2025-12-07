# Compare Weasel and Tamil99 Categories

$weaselCLSID = "{A3F4CDED-B1E9-41EE-9CA6-7B4D0DE6CB0A}"
$tamil99CLSID = "{95F0C259-8336-4BF3-AE73-7BE2D2E23462}" # This appears to be Tamil99

Write-Host "=== WEASEL vs TAMIL99 CATEGORY COMPARISON ===" -ForegroundColor Cyan

# Function to get categories
function Get-IMECategories {
    param($clsid, $name)
    
    Write-Host "`n--- $name Categories ---" -ForegroundColor Yellow
    Write-Host "CLSID: $clsid`n"
    
    $path = "HKLM:\SOFTWARE\Classes\CLSID\$clsid\Implemented Categories"
    
    if (Test-Path $path) {
        $categories = Get-ChildItem $path | Select-Object -ExpandProperty PSChildName
        
        foreach ($cat in $categories) {
            Write-Host "  $cat"
        }
        
        Write-Host "`nTotal: $($categories.Count) categories" -ForegroundColor Green
        return $categories
    } else {
        Write-Host "Path not found: $path" -ForegroundColor Red
        return @()
    }
}

# Get categories for both
$weaselCats = Get-IMECategories $weaselCLSID "WEASEL"
$tamil99Cats = Get-IMECategories $tamil99CLSID "TAMIL99"

# Compare
Write-Host "`n=== COMPARISON ===" -ForegroundColor Cyan

# Categories in Weasel but NOT in Tamil99
$onlyWeasel = $weaselCats | Where-Object { $_ -notin $tamil99Cats }
if ($onlyWeasel) {
    Write-Host "`nCategories ONLY in Weasel (MISSING in Tamil99):" -ForegroundColor Red
    foreach ($cat in $onlyWeasel) {
        Write-Host "  $cat" -ForegroundColor Yellow
    }
}

# Categories in Tamil99 but NOT in Weasel
$onlyTamil99 = $tamil99Cats | Where-Object { $_ -notin $weaselCats }
if ($onlyTamil99) {
    Write-Host "`nCategories ONLY in Tamil99 (NOT in Weasel):" -ForegroundColor Red
    foreach ($cat in $onlyTamil99) {
        Write-Host "  $cat" -ForegroundColor Yellow
    }
}

# Common categories
$common = $weaselCats | Where-Object { $_ -in $tamil99Cats }
Write-Host "`nCommon categories: $($common.Count)" -ForegroundColor Green

# Decode important GUIDs
Write-Host "`n=== IMPORTANT CATEGORY CHECKS ===" -ForegroundColor Cyan

$categories = @{
    "{E2449140-85C2-4E9D-A01A-97FAD71A7CD3}" = "SEARCHANDNAVIGATION"
    "{A5C559E3-5E85-40D9-95DD-597D05150C43}" = "INPUTMODECOMPARTMENT"
    "{246ecb87-c2f2-4abe-905b-c8b38add2c43}" = "TIPCAP_IMMERSIVESUPPORT"
    "{13A016DF-560B-46CD-947A-4C3AF1E0E35D}" = "TIPCAP_UIELEMENTENABLED"
    "{3FAB6E70-5FAC-469E-A30F-DB5B70F03F31}" = "TIPCAP_SECUREMODE"
    "{532FE2F1-3876-4C43-B269-90E9D9BF3E49}" = "TIPCAP_WOW16"
}

foreach ($guid in $categories.Keys) {
    $name = $categories[$guid]
    $inWeasel = $guid -in $weaselCats
    $inTamil99 = $guid -in $tamil99Cats
    
    $weaselStatus = if ($inWeasel) { "YES" } else { "NO" }
    $tamil99Status = if ($inTamil99) { "YES" } else { "NO" }
    
    $color = if ($inWeasel -eq $inTamil99) { "Gray" } else { "Yellow" }
    
    Write-Host "`n$name ($guid)" -ForegroundColor $color
    Write-Host "  Weasel:  $weaselStatus" -NoNewline
    if ($inWeasel) { Write-Host " ✓" -ForegroundColor Green } else { Write-Host " ✗" -ForegroundColor Red }
    Write-Host "  Tamil99: $tamil99Status" -NoNewline
    if ($inTamil99) { Write-Host " ✓" -ForegroundColor Green } else { Write-Host " ✗" -ForegroundColor Red }
}

# Check DLL signature
Write-Host "`n=== CODE SIGNING COMPARISON ===" -ForegroundColor Cyan

function Check-Signature {
    param($path, $name)
    
    Write-Host "`n$name`: $path"
    if (Test-Path $path) {
        $sig = Get-AuthenticodeSignature $path
        Write-Host "  Status: $($sig.Status)"
        if ($sig.Status -eq "Valid") {
            Write-Host "  Signer: $($sig.SignerCertificate.Subject)"
            Write-Host "  Issuer: $($sig.SignerCertificate.Issuer)"
        }
    } else {
        Write-Host "  File not found!" -ForegroundColor Red
    }
}

Check-Signature "C:\Windows\System32\weasel.dll" "Weasel"
Check-Signature "C:\Windows\System32\MurasuAnjal.dll" "Tamil99"

Write-Host "`n=== END OF COMPARISON ===" -ForegroundColor Cyan
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")