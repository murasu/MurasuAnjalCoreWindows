# Creating a New Tamil IME Project

This guide explains how to create a new Tamil keyboard IME by cloning the working MurasuAnjalCore project.

## Why Clone Instead of Generate?

The MurasuAnjalCore project contains all the critical configurations discovered through extensive testing:
- Correct ARM64EC build settings (BuildAsX property)
- Proper GUID category registration (GUID_TFCAT_TIP_KEYBOARD)
- Working TSF interface implementations
- Build automation for dual-architecture deployment

Cloning ensures you inherit all these proven configurations automatically.

## Steps to Create a New IME

### 1. Copy the Project

```powershell
Copy-Item -Path "C:\Users\nedum\Projects\MurasuAnjalCore" -Destination "C:\Users\nedum\Projects\YourNewIME" -Recurse
```

Or manually copy the entire folder to a new location.

### 2. Generate New GUIDs

In PowerShell, generate two new GUIDs:

```powershell
[guid]::NewGuid()  # CLSID
[guid]::NewGuid()  # Profile GUID
```

Example output:
```
12345678-1234-1234-1234-123456789ABC  # Your new CLSID
ABCDEF12-3456-7890-ABCD-EF1234567890  # Your new Profile GUID
```

Save these - you'll need them in the next step.

### 3. Replace GUIDs

**File: `include\MurasuAnjalCore.h`**

Find and replace the GUID declarations (around lines 60-76):

```cpp
// OLD - Replace this entire block
static const GUID c_clsidTextService = 
{ 0x..., 0x..., 0x..., 
  { 0x..., 0x..., 0x..., 0x..., 0x..., 0x..., 0x..., 0x... } };

static const GUID c_guidProfile = 
{ 0x..., 0x..., 0x..., 
  { 0x..., 0x..., 0x..., 0x..., 0x..., 0x..., 0x..., 0x... } };
```

**Quick Method:** Use the GUID format already in the file as template - just replace the hex values with your new GUIDs. Split your GUID `12345678-1234-1234-1234-123456789ABC` into parts:
- First part: `0x12345678`
- Second part: `0x1234`
- Third part: `0x1234`
- Fourth part: Split into bytes: `0x12, 0x34, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC`

**File: `src\Register.cpp`**

Search for the same GUIDs in the registration code and update them to match your new GUIDs.

### 4. Update Display Name

**File: `include\MurasuAnjalCore.h`** (around line 82):

```cpp
#define TEXTSERVICE_DESC    L"Your IME Name - Layout Name"
```

Examples:
- `L"Murasu Tamil Typewriter"`
- `L"Murasu Tamil Phonetic"`
- `L"Murasu Bengali Probhat"`

### 5. Customize Character Mapping

**File: `src\MurasuAnjalCore.cpp`**

Find the `_MapKeyToTamil()` function (around line 280) and modify the character mappings:

```cpp
wchar_t CMurasuAnjalTextService::_MapKeyToTamil(WPARAM wParam)
{
    // Convert virtual key code to uppercase
    char key = (char)toupper((int)wParam);

    // Your custom keyboard layout mapping
    switch (key)
    {
        // Vowels
        case 'A': return 0x0B85;  // அ
        case 'S': return 0x0B86;  // ஆ
        // ... add your mappings
        
        default: return 0;
    }
}
```

Reference: [Tamil Unicode Chart](https://unicode.org/charts/PDF/U0B80.pdf)

### 6. (Optional) Rename Project Files

If you want to rename the project:

1. Rename `.vcxproj` and `.sln` files
2. Update project name inside `.vcxproj` (search for "MurasuAnjalCore")
3. Update `<RootNamespace>` in `.vcxproj`
4. Rename `.def` file in `src\`
5. Update `.def` file reference in `.vcxproj`

**Tip:** Use Visual Studio's "Rename Project" feature instead of manual renaming.

### 7. Build the Project

Use the included build script:

```powershell
cd C:\Users\nedum\Projects\YourNewIME
.\Build-Installer.ps1
```

This builds both x64 and ARM64EC versions and verifies the architectures.

Output will be in:
```
Installer\Artifacts\
├── x64\YourIME.dll
└── ARM64EC\YourIME.dll
```

### 8. Install and Test

**Register the DLL:**

```batch
# For x64 systems:
regsvr32 "C:\Users\nedum\Projects\YourNewIME\Installer\Artifacts\x64\YourIME.dll"

# For ARM64 systems:
regsvr32 "C:\Users\nedum\Projects\YourNewIME\Installer\Artifacts\ARM64EC\YourIME.dll"
```

**Configure Windows:**

1. Settings → Time & Language → Language & region
2. Add Tamil (if not already added)
3. Click Options next to Tamil
4. Your IME should appear under Keyboards

**Test:**
1. Open Notepad
2. Switch to Tamil input (Win + Space or Alt + Shift)
3. Select your new IME
4. Type to verify mappings

### 9. Uninstall (if needed)

```batch
regsvr32 /u "path\to\your\IME.dll"
```

## File Locations Summary

| What to Change | File | Purpose |
|----------------|------|---------|
| GUIDs | `include\MurasuAnjalCore.h` | COM registration IDs |
| GUIDs | `src\Register.cpp` | Registry entries |
| Display Name | `include\MurasuAnjalCore.h` | What users see in settings |
| Character Mapping | `src\MurasuAnjalCore.cpp` | Keyboard layout logic |

## Tips

- **Keep GUIDs unique**: Never reuse GUIDs from another IME
- **Test incrementally**: Start with a few character mappings, verify they work, then expand
- **Use Unicode references**: Keep a Unicode chart handy for your target script
- **Build both architectures**: Modern Windows systems need both x64 and ARM64EC
- **Version control**: Use Git to track changes to your mappings

## Architecture Notes

The project is configured for:
- **x64**: Traditional Intel/AMD processors
- **ARM64EC**: Modern ARM-based Windows devices (Surface Pro X, etc.)

The BuildAsX property in the .vcxproj handles ARM64EC compilation automatically - don't modify these settings unless you know what you're doing.

## Common Issues

**IME doesn't appear in keyboard list:**
- Verify you ran regsvr32 as Administrator
- Check Windows Event Viewer for registration errors
- Ensure GUIDs are unique and properly formatted

**Wrong characters appear:**
- Double-check Unicode values in your mapping function
- Verify Tamil fonts are installed (Windows includes Latha, Vijaya)

**Build errors:**
- Clean solution and rebuild
- Verify Windows SDK is installed (10.0 or later)
- Check that both x64 and ARM64EC platforms are configured

## Need Help?

- Check the original MurasuAnjalCore README for detailed architecture info
- Review `src\MurasuAnjalCore.cpp` for implementation examples
- Consult Windows TSF documentation for advanced features
