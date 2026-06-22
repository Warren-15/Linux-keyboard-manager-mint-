[README.md](https://github.com/user-attachments/files/29197536/README.md)
# Linux-keyboard-manager-mint-
Create and Edit Custom keyboard
# ISO 105 Keyboard Layout Editor

A professional web-based editor for creating and customizing ISO 105 keyboard layouts with full support for 4-level key mappings (Standard, Shift, AltGr, Shift+AltGr). Export your layouts in `.layout` format compatible with XKB (X Keyboard Extension) for Linux desktop environments.

![Keyboard Layout Editor](https://img.shields.io/badge/Keyboard-Editor-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![HTML](https://img.shields.io/badge/HTML-5-orange)
![JavaScript](https://img.shields.io/badge/JavaScript-ES6-yellow)

## ✨ Features

### 🎹 Interactive Keyboard
- **Complete ISO 105 layout** with all keys including number row, function keys, navigation cluster, arrow keys, and full numpad
- **4-level key display** showing Standard, Shift, AltGr, and Shift+AltGr combinations
- **Real-time editing** - click any key to modify its four levels
- **Responsive design** - adapts to screen sizes from desktop to mobile

### 🛠️ Editing Capabilities
- **Key-level editing** - assign any character or symbol to each of the 4 levels
- **Emoji picker** - browse and insert emojis and special symbols with categorized sections
- **Import/Export** - save and load `.layout` files for sharing or backup
- **Reset functionality** - reset individual keys or the entire layout
- **Export modes**: DEF (symbol names) or HEX (Unicode code points)

### 🌍 Internationalization
- **Language support** - select from 10 languages (Arabic, English, French, German, Spanish, Italian, Portuguese, Russian, Japanese, Chinese)
- **Country-specific layouts** - automatic flag display based on country selection
- **Multi-level mapping** - support for special characters used in different languages

### 🔧 Technical Features
- **keysymdef.h integration** - loads standard XKB symbol definitions
- **Cache system** - stores definitions locally for offline use
- **Light/Dark theme** - comfortable editing in any lighting condition
- **Responsive UI** - optimized for all screen sizes

## 🚀 Quick Start

### Online Usage
1. Open `keys_editor.html` in any modern web browser
2. Click **"Load Defs"** to load keysymdef.h and emoji definitions (optional but recommended)
3. Start editing keys by clicking on any key
4. Use the toolbar to import/export layouts

### Offline Usage
The editor works completely offline once loaded. All data is stored in your browser's localStorage.

### Layout File Format
The editor uses a custom `.layout` format compatible with XKB:
```xkb
key <TLDE> { [ twosuperior   , asciitilde    , ~             , ³ ] };   // ² ~ ~ ³
key <AE01> { [ ampersand     , 1             , function      , U2225 ] };  // & 1 ƒ ∥
```

## 📋 Installation

### Prerequisites
- Modern web browser (Chrome, Firefox, Edge, Safari)
- Optional: `keysymdef.h` file from XKB data directory (`/usr/include/X11/keysymdef.h`)
- Optional: `emojis_and_symbols.txt` for emoji support

### Installation Steps
1. Clone the repository:
```bash
git clone https://github.com/yourusername/keyboard-layout-editor.git
cd keyboard-layout-editor
```

2. Open the editor:
```bash
# Simply open in browser
open keys_editor.html
# or
firefox keys_editor.html
```

3. (Optional) Load definition files:
   - Click **"Load Defs"** button
   - Select your `keysymdef.h` file
   - Select your `emojis_and_symbols.txt` file

## 🎯 Usage Guide

### Basic Workflow
1. **Load Definitions** (optional) - Click "Load Defs" to load XKB symbols and emojis
2. **Edit Keys** - Click any key to open the editor panel
3. **Set Levels** - Fill in the four level inputs:
   - Standard: Default character
   - Shift+: Character with Shift modifier
   - AltGr+: Character with AltGr modifier
   - Shift+AltGr: Character with both modifiers
4. **Export** - Click "Export .layout" to download your custom layout
5. **Import** - Use "Import .layout" to load existing layouts

### Keyboard Shortcuts
| Action | Description |
|--------|-------------|
| Click key | Open editor for that key |
| Enter in level field | Auto-update key display |
| 🔣 button | Open emoji picker |

### Level Mappings Explained
| Level | Modifier | Typical Use |
|-------|----------|-------------|
| Level 1 | None | Standard character (e.g., `a`, `1`) |
| Level 2 | Shift | Uppercase or shifted symbol (e.g., `A`, `!`) |
| Level 3 | AltGr | Third-level characters (e.g., `@`, `#`) |
| Level 4 | Shift+AltGr | Fourth-level characters (e.g., `~`, `€`) |

## 📦 Export File Structure

The exported `.layout` file follows this structure:

```
# ================================================================
# Layout Definition File for US.layout
# ================================================================

# ⚙️ BASIC INFO
INPUT_SOURCE_NAME="English (US)"
SHORT_NAME="US"
LANGUAGE_CODE="en"
COUNTRY_CODE="US"
FLAG="🇺🇸"

# First row - Numbers and symbols
# Standard:    ² & é " '"'"' ( - è _ ç à ) =
# Shift:       ~ 1 2 3 4 5 6 7 8 9 0 ° +
# AltGr:       ³ | ² # { [ ± ` \ # @ ] }
# AltGr+Shift: ⁴ ∥ ½ ⅓ ¼ ★ ✴ ☾ ∞ ⊙ φ ○ ≠

key <TLDE> { [ twosuperior   , asciitilde    , ~             , ³ ] };   // ² ~ ~ ³
key <AE01> { [ ampersand     , 1             , function      , U2225 ] };  // & 1 ƒ ∥
```

## 🛠️ Integration with Keyboard Manager

This editor works seamlessly with the [Keyboard Manager](https://github.com/yourusername/keyboard-manager) bash script for installing layouts on Linux:

```bash
# After editing your layout, export it as US.layout
# Then use the keyboard manager to install it
./Keyboard_installer.sh
# Select option 1 to install custom layouts
```

## 🔄 Integration with Linux Desktop

To use your custom layout on Linux:

1. Export your layout as `.layout` file
2. Use the Keyboard Manager to install it:
```bash
./Keyboard_installer.sh
# Choose option 1: Install custom layouts
# Select your .layout file
# Choose option 3: Full desktop refresh
```

3. The layout will be available in your desktop environment's keyboard settings

## 📁 File Structure

```
keyboard-layout-editor/
├── keys_editor.html      # Main editor application
├── README.md             # This documentation
└── Keyboard_installer.sh # Linux installation helper
```

## 🔧 Troubleshooting

### Common Issues

**Q: The emoji picker shows no emojis**
- Click "Load Defs" and select an `emojis_and_symbols.txt` file
- Or use the default emojis automatically loaded

**Q: Exported layout shows names like `twosuperior` instead of actual characters**
- This is normal when using DEF mode - the file stores symbol names
- Use HEX mode if you prefer Unicode code points (e.g., `U00B2`)

**Q: Changes don't appear on my Linux system**
- After exporting, use Keyboard Manager to install
- Refresh your desktop environment (Alt+F2, then type `r`)

**Q: Some keys don't show correct symbols**
- Load a valid `keysymdef.h` file
- Or use HEX mode for explicit Unicode code points

## 🚀 Future Enhancements

- [ ] Multiple layout support (switch between layouts)
- [ ] Layout preview with real keyboard rendering
- [ ] Dead key support
- [ ] Keyboard shortcut export (E.g., Compose key sequences)
- [ ] User-defined categories in emoji picker
- [ ] Cloud storage for layouts

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Keep the single-file HTML structure
- Ensure responsive design works on all devices
- Maintain support for both light and dark themes
- Add comments for complex functions
- Test across different browsers

## 📄 License

This project is licensed under the MIT License - see below:

```
MIT License

Copyright (c) 2026 Keyboard Layout Editor Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 Acknowledgments

- **XKB** - The X Keyboard Extension that makes custom layouts possible
- **ISO 105** - The keyboard layout standard this editor is based on
- **All contributors** - For testing, feedback, and improvements

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/keyboard-layout-editor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/keyboard-layout-editor/discussions)
- **Email**: mr.dabbabi@gmail.com

---

**Built with ❤️ for the Linux community**
