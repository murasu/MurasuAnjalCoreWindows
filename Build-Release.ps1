# Build script for MurasuAnjalCore installer artifacts
# Builds x64 and ARM64EC Release configurations and copies to Installer folder

param(
    [string]$SolutionPath = "C:\Users\nedum\Projects\MurasuAnjalCore\MurasuAnjalCore.sln",
    [string]$ProjectRoot = "C:\Users\nedum\Projects\MurasuAnjalCore",
    [string]$MSBuildPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
)

# Color output functions
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

# Check if MSBuild exists
if (-not (Test-Path $MSBuildPath)) {
    Write-Error "MSBuild not found at: $MSBuildPath"
    Write-Error "Please update the MSBuildPath parameter"
    exit 1
}

# Check if solution exists
if (-not (Test-Path $SolutionPath)) {
    Write-Error "Solution not found at: $SolutionPath"
    exit 1
}

Write-Info "========================================="
Write-Info "Building MurasuAnjalCore Installer Artifacts"
Write-Info "========================================="
Write-Info ""

# Create Installer folder structure
$InstallerRoot = Join-Path $ProjectRoot "Installer"
$ArtifactsRoot = Join-Path $InstallerRoot "Artifacts"
$x64Folder = Join-Path $ArtifactsRoot "x64"
$ARM64ECFolder = Join-Path $ArtifactsRoot "ARM64EC"

Write-Info "Creating installer folder structure..."
New-Item -ItemType Directory -Path $InstallerRoot -Force | Out-Null
New-Item -ItemType Directory -Path $ArtifactsRoot -Force | Out-Null
New-Item -ItemType Directory -Path $x64Folder -Force | Out-Null
New-Item -ItemType Directory -Path $ARM64ECFolder -Force | Out-Null
Write-Success "✓ Folder structure created"
Write-Info ""

# Clean previous builds
Write-Info "Cleaning previous builds..."
& $MSBuildPath $SolutionPath /t:Clean /p:Configuration=Release /p:Platform=x64 /v:minimal
& $MSBuildPath $SolutionPath /t:Clean /p:Configuration=Release /p:Platform=ARM64EC /v:minimal
Write-Success "✓ Clean completed"
Write-Info ""

# Build x64 Release
Write-Info "Building x64 Release configuration..."
& $MSBuildPath $SolutionPath /t:Build /p:Configuration=Release /p:Platform=x64 /v:minimal
if ($LASTEXITCODE -ne 0) {
    Write-Error "✗ x64 build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Success "✓ x64 build completed successfully"
Write-Info ""

# Build ARM64EC Release
Write-Info "Building ARM64EC Release configuration..."
& $MSBuildPath $SolutionPath /t:Build /p:Configuration=Release /p:Platform=ARM64EC /v:minimal
if ($LASTEXITCODE -ne 0) {
    Write-Error "✗ ARM64EC build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Success "✓ ARM64EC build completed successfully"
Write-Info ""

# Copy x64 DLL
Write-Info "Copying x64 artifacts..."
$x64Source = Join-Path $ProjectRoot "build\Release\MurasuAnjalCore.dll"
$x64Dest = Join-Path $x64Folder "MurasuAnjalCore.dll"

if (Test-Path $x64Source) {
    Copy-Item $x64Source $x64Dest -Force
    Write-Success "✓ Copied: $x64Dest"
    
    # Verify it's x64
    $dumpbin = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\dumpbin.exe"
    if (Test-Path $dumpbin) {
        $arch = & $dumpbin /headers $x64Dest | Select-String "machine"
        Write-Info "  Architecture: $($arch -replace '^\s+', '')"
    }
} else {
    Write-Error "✗ x64 DLL not found at: $x64Source"
    exit 1
}
Write-Info ""

# Copy ARM64EC DLL
Write-Info "Copying ARM64EC artifacts..."
$arm64ecSource = Join-Path $ProjectRoot "ARM64EC\Release\MurasuAnjalCore.dll"
$arm64ecDest = Join-Path $ARM64ECFolder "MurasuAnjalCore.dll"

if (Test-Path $arm64ecSource) {
    Copy-Item $arm64ecSource $arm64ecDest -Force
    Write-Success "✓ Copied: $arm64ecDest"
    
    # Verify it's ARM64EC
    $dumpbin = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\dumpbin.exe"
    if (Test-Path $dumpbin) {
        $arch = & $dumpbin /headers $arm64ecDest | Select-String "machine"
        Write-Info "  Architecture: $($arch -replace '^\s+', '')"
    }
} else {
    Write-Error "✗ ARM64EC DLL not found at: $arm64ecSource"
    exit 1
}
Write-Info ""

# Summary
Write-Success "========================================="
Write-Success "Build completed successfully!"
Write-Success "========================================="
Write-Info "Artifacts location: $InstallerRoot"
Write-Info ""
Write-Info "x64 DLL:      $x64Dest"
Write-Info "ARM64EC DLL:  $arm64ecDest"
Write-Info ""
Write-Success "Ready for Advanced Installer packaging"