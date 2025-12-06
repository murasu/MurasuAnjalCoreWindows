# Build Script Usage

## Build-Installer.ps1

This PowerShell script builds both x64 and ARM64EC Release configurations and prepares them for installer packaging.

### Quick Start

1. Save `Build-Installer.ps1` to your project root:
   ```
   C:\Users\nedum\Projects\MurasuAnjalCore\Build-Installer.ps1
   ```

2. Run from PowerShell:
   ```powershell
   cd C:\Users\nedum\Projects\MurasuAnjalCore
   .\Build-Installer.ps1
   ```

### Output Structure

The script creates:
```
C:\Users\nedum\Projects\MurasuAnjalCore\
├── Installer\
│   └── Artifacts\
│       ├── x64\
│       │   └── MurasuAnjalCore.dll       (8664 machine - x64)
│       └── ARM64EC\
│           └── MurasuAnjalCore.dll       (AA64 machine - ARM64EC)
```

### What It Does

1. ✓ Creates `Installer` folder structure
2. ✓ Cleans previous builds
3. ✓ Builds x64 Release configuration
4. ✓ Builds ARM64EC Release configuration
5. ✓ Copies DLLs to respective folders
6. ✓ Verifies architecture of each DLL
7. ✓ Reports success/failure with color-coded output

### Advanced Installer Integration

In Advanced Installer:
1. Add x64 DLL from: `Installer\Artifacts\x64\MurasuAnjalCore.dll`
2. Add ARM64EC DLL from: `Installer\Artifacts\ARM64EC\MurasuAnjalCore.dll`
3. Set appropriate installation conditions based on system architecture

### Custom Paths

If your paths differ, run with parameters:

```powershell
.\Build-Installer.ps1 `
    -SolutionPath "C:\Custom\Path\MurasuAnjalCore.sln" `
    -ProjectRoot "C:\Custom\Path" `
    -MSBuildPath "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
```

### Troubleshooting

**Error: "MSBuild not found"**
- Update the `$MSBuildPath` parameter to match your Visual Studio installation

**Error: "DLL not found"**
- Check that both x64 and ARM64EC configurations exist in your solution
- Verify the build output paths in your project settings

**Error: Build failed**
- Run the script again with `/v:detailed` for more information:
  Edit line 49 and 57: change `/v:minimal` to `/v:detailed`

### Verification

The script automatically verifies each DLL:
- x64 should show: `8664 machine (x64)`
- ARM64EC should show: `AA64 machine (ARM64)` or `AA64 machine (ARM64EC)`
