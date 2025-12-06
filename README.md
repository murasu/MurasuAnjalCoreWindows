# Murasu Anjal Core - Tamil TSF IME

A minimal Text Services Framework (TSF) based Input Method Editor (IME) for Tamil keyboards, designed specifically for compatibility with Respondus LockDown Browser and other restricted environments.

## Project Goals

- **Extensible**: Starting with Tamil99, but designed to support additional Tamil keyboard layouts
- **Minimal**: No external dependencies, network access, or file system operations beyond installation
- **Secure**: Works in restricted exam environments like Respondus LockDown Browser
- **Modern**: TSF-based architecture for best Windows compatibility

## Current Implementation

This initial release supports basic Tamil99 keyboard layout with demonstration character mappings. Full Tamil99 layout can be added by expanding the mapping table.

## System Requirements

- Windows 10/11 (64-bit)
- Visual Studio 2022 or later with C++ Desktop Development workload
- Administrator privileges for installation

## Build Instructions

1. Open MurasuAnjalCore.vcxproj in Visual Studio 2022
2. Select **Release** configuration and **x64** platform
3. Build Solution (Ctrl+Shift+B)
4. The DLL will be created in uild\Release\MurasuAnjalCore.dll

## Installation

1. Build the project (see above)
2. Right-click Install-MurasuAnjalCore.bat and select **Run as administrator**
3. Follow the on-screen instructions

### Manual Windows Configuration

After installation:

1. Go to **Settings** > **Time & Language** > **Language & region**
2. Add Tamil language if not already added
3. Click **Options** next to Tamil
4. "Murasu Anjal Core - Tamil99" should appear under Keyboards

### For Respondus LockDown Browser

**Important**: Configure these settings BEFORE launching LockDown Browser:

1. Go to **Settings** > **Time & Language** > **Typing** > **Advanced keyboard settings**
2. Enable:
   - "Let me use a different input method for each app window"
   - "Use the desktop language bar when it's available"
3. Click "Language bar options"
4. Select "Floating on Desktop" (NOT "Docked in the taskbar")
5. Click Apply

**Keyboard Switching**:
- Set up hotkeys: **Settings** > **Typing** > **Advanced Keyboard Settings** > **Input Language Hot Keys**
- Common combinations: Left Alt + Shift or Ctrl + Shift

## Current Character Mapping (Demo)

This is a demonstration version with basic mappings:

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

## Expanding the Tamil99 Layout

To add the complete Tamil99 mapping:

1. Open src\MurasuAnjalCore.cpp
2. Find the _MapKeyToTamil() function (around line 280)
3. Add more case statements following the pattern:

\\\cpp
// More consonants
case 'U': return 0x0BA4;  // த (tha)
case 'I': return 0x0BA8;  // ந (na)
case 'O': return 0x0BAA;  // ப (pa)
case 'P': return 0x0BAE;  // ம (ma)

// More vowels
case 'J': return 0x0B8E;  // எ (e)
case 'K': return 0x0B8F;  // ஏ (ee)
case 'L': return 0x0B90;  // ஐ (ai)

// Add all remaining Tamil99 mappings...
\\\

4. Rebuild the project
5. Uninstall the old version
6. Install the new version

## Future Keyboard Layouts

The architecture supports adding additional Tamil keyboard layouts:

1. Add layout-specific mapping functions
2. Add layout selection mechanism
3. Register additional profiles in Register.cpp

Possible future layouts:
- Tamil Typewriter
- Phonetic Tamil
- InScript Tamil
- Custom layouts

## Troubleshooting

### IME doesn't appear in keyboard list
- Ensure you ran installation as Administrator
- Check if Tamil language is added to Windows
- Restart Windows after installation

### Doesn't work in LockDown Browser
- Verify floating language bar is enabled (see configuration above)
- Test hotkey switching in regular Notepad first
- Ensure you're using the latest build

### Build errors
- Verify Visual Studio has C++ Desktop Development workload installed
- Check Windows SDK is installed (10.0 or later)
- Clean solution and rebuild

### Characters not appearing correctly
- Ensure you have Tamil fonts installed (Windows includes Latha, Vijaya)
- Test in different applications (Notepad, Word, browser)

## Uninstallation

1. Right-click Uninstall-MurasuAnjalCore.bat and select **Run as administrator**
2. Remove Tamil keyboard from Windows Language settings if desired

## Architecture

This IME implements the minimum TSF interfaces required:

- ITfTextInputProcessor - Main processor interface
- ITfTextInputProcessorEx - Extended activation
- ITfThreadMgrEventSink - Thread manager events
- ITfKeyEventSink - Keyboard event handling

The implementation is intentionally minimal to avoid conflicts in restricted environments:
- No candidate windows or UI elements
- No dictionary files or external resources
- No network or internet access
- No user preferences or settings files
- Direct character insertion only

## GUIDs

This installation uses:
- CLSID: {75E86BCD-4B3C-48BD-94EA-56584C5AE817}
- Profile GUID: {8901761E-CAA5-451E-B469-3A6D22F69F9A}

## Project Structure

\\\
MurasuAnjalCore/
├── include/
│   └── MurasuAnjalCore.h          # Main header with TSF interfaces
├── src/
│   ├── MurasuAnjalCore.cpp        # Core IME implementation
│   ├── Register.cpp               # COM registration
│   └── MurasuAnjalCore.def        # DLL exports
├── build/                         # Build output
├── MurasuAnjalCore.vcxproj        # Visual Studio project
├── Install-MurasuAnjalCore.bat    # Installation script
├── Uninstall-MurasuAnjalCore.bat  # Uninstallation script
└── README.md                      # This file
\\\

## Contributing

When adding new keyboard layouts:
1. Follow the minimal design principle
2. Embed all mappings in code (no external files)
3. Test in LockDown Browser environment
4. Update documentation

## License

This is a minimal reference implementation for educational and exam purposes.

## About Murasu Anjal

"Anjal" (அஞ்சல்) means "letter" or "character" in Tamil. This project aims to provide reliable, exam-safe Tamil input methods for Windows systems.

## Support

For issues specific to:
- Singapore MOE exam deployment: Consult your system administrator
- Respondus LockDown Browser compatibility: See troubleshooting section
- General TSF/Windows issues: Check Windows Event Viewer for registration errors

## Version History

- v0.1 (Initial): Basic Tamil99 demo with 12 character mappings
- Future: Complete Tamil99 layout, additional keyboard layouts
