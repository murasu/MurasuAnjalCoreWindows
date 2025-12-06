# Murasu Anjal Core - Tamil TSF IME

A minimal Text Services Framework (TSF) based Input Method Editor (IME) for Tamil keyboards.

## Project Goals

- **Extensible**: Starting with Tamil99, but designed to support additional Tamil keyboard layouts
- **Minimal**: No external dependencies, network access, or file system operations beyond installation
- **Secure**: Works in restricted exam environments
- **Modern**: TSF-based architecture for best Windows compatibility

## Current Implementation

This initial release supports basic Tamil99 keyboard layout with demonstration character mappings. Full Tamil99 layout can be added by expanding the mapping table in `_MapKeyToTamil()`.

## System Requirements

- Windows 10/11 (x64 or ARM64)
- Visual Studio 2022 with C++ Desktop Development workload
- Administrator privileges for installation

## Build Instructions

### Using PowerShell Build Script (Recommended)

1. Run the build script from project root:
   ```powershell
   .\Build-Installer.ps1
   ```

2. Artifacts will be created in:
   ```
   Installer\Artifacts\
   ├── x64\MurasuAnjalCore.dll
   └── ARM64EC\MurasuAnjalCore.dll
   ```

### Manual Build in Visual Studio

**For x64:**
1. Open `MurasuAnjalCore.vcxproj` in Visual Studio 2022
2. Select **Release** configuration and **x64** platform
3. Build Solution (Ctrl+Shift+B)
4. Output: `build\Release\MurasuAnjalCore.dll`

**For ARM64EC:**
1. Select **Release** configuration and **ARM64EC** platform
2. Build Solution
3. Output: `ARM64EC\Release\MurasuAnjalCore.dll`

## Installation and Registration

### Using regsvr32

**For x64 systems:**
```cmd
regsvr32 /i "C:\Path\To\MurasuAnjalCore.dll"
```

**For ARM64 systems:**
```cmd
regsvr32 /i "C:\Path\To\MurasuAnjalCore.dll"
```

### Using Advanced Installer

The project includes an Advanced Installer configuration that:
- Installs appropriate DLL based on system architecture (x64 or ARM64EC)
- Handles COM registration automatically
- Configures Windows language settings

### Uninstallation

```cmd
regsvr32 /u "C:\Path\To\MurasuAnjalCore.dll"
```

## Current Character Mapping

Basic Tamil99 demonstration mappings:

| Key | Tamil Character | Unicode | Description |
|-----|-----------------|---------|-------------|
| A   | அ               | U+0B85  | Vowel A     |
| S   | ஆ               | U+0B86  | Vowel AA    |
| D   | இ               | U+0B87  | Vowel I     |
| F   | ஈ               | U+0B88  | Vowel II    |
| G   | உ               | U+0B89  | Vowel U     |
| H   | ஊ               | U+0B8A  | Vowel UU    |
| Q   | க               | U+0B95  | Ka          |
| W   | ங               | U+0B99  | Nga         |
| E   | ச               | U+0B9A  | Ca          |
| R   | ஞ               | U+0B9E  | Nya         |
| T   | ட               | U+0B9F  | Tta         |
| Y   | ண               | U+0BA3  | Nna         |

**Note:** This is a demonstration implementation. Expand the `_MapKeyToTamil()` function in `src\MurasuAnjalCore.cpp` to add the complete Tamil99 layout.

## Architecture

This IME implements the minimum TSF interfaces required:

- **ITfTextInputProcessor** - Main processor interface
- **ITfTextInputProcessorEx** - Extended activation
- **ITfThreadMgrEventSink** - Thread manager events
- **ITfKeyEventSink** - Keyboard event handling

The implementation is intentionally minimal:
- No candidate windows or UI elements
- No dictionary files or external resources
- No network or internet access
- No user preferences or settings files
- Direct character insertion only

## Key Files

- `include/MurasuAnjalCore.h` - Main header with TSF interfaces
- `src/MurasuAnjalCore.cpp` - Core IME implementation and character mappings
- `src/Register.cpp` - COM registration
- `src/MurasuAnjalCore.def` - DLL exports
- `Build-Installer.ps1` - Automated build script for installer artifacts
