# Inkwell

A beautiful, native Markdown editor for macOS with live preview.

![macOS](https://img.shields.io/badge/macOS-12.0+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.1-orange?style=flat-square&logo=swift)

## Features

- **Live Preview** — side-by-side editor and rendered preview with synced scrolling
- **Native macOS App** — lightweight WKWebView-based app, no Electron bloat
- **Rich Toolbar** — SVG icons with hover tooltips showing keyboard shortcuts
- **Keyboard Shortcuts** — `⌘B` bold, `⌘I` italic, `⌘K` link, `⌘E` code, `⌘S` save, `⌘O` open
- **View Modes** — split, editor-only, or preview-only (`⌘1` / `⌘2` / `⌘3`)
- **File Operations** — open `.md` files, save markdown, export as styled HTML
- **Resizable Panes** — drag the divider to adjust the split
- **Auto-Save** — content persists in localStorage between sessions
- **Status Bar** — cursor position, word count, character count
- **Custom App Icon** — amber pen nib on dark background

## Install

### From DMG

1. Download `Inkwell.dmg` from [Releases](../../releases)
2. Open the DMG and drag **Inkwell** to **Applications**
3. Launch from Applications or Spotlight

> On first launch, macOS may block the unsigned app. Right-click > Open, or go to System Settings > Privacy & Security > "Open Anyway".

### Build from Source

Requires macOS 12+ and Swift 6.x (included with Xcode).

```bash
cd build
./build.sh
```

The built app will be at `build/Inkwell.app` and the installer at `Inkwell.dmg`.

## Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Bold | `⌘B` |
| Italic | `⌘I` |
| Inline Code | `⌘E` |
| Insert Link | `⌘K` |
| Save | `⌘S` |
| Open | `⌘O` |
| Split View | `⌘1` |
| Editor Only | `⌘2` |
| Preview Only | `⌘3` |

## Project Structure

```
├── markdown-editor.html   # The full editor UI (HTML/CSS/JS)
├── build/
│   ├── main.swift         # Native macOS app (WKWebView wrapper)
│   ├── gen_icon.swift     # App icon generator (Core Graphics)
│   ├── Info.plist         # App bundle metadata
│   └── build.sh           # Build script
└── README.md
```

### Featurelist to add to inkwell
- AI tool build in - linked to local or cloud LLM
- Update icon
- Change name, although i kind of like it
- Ask Claude what it would improve in this editor? 
- what are some premium features that can be added to this editor? 
- Add the ability to rename the file
- Add the ability to add a new tab, to work on multiple tabs / docs at the same time. 
- Change the about section to add my name and Claudes
- Allow ability to open the finder window where the file is saved
- Dark mode for the preview mode
- Where is the file being saved to? 
- Why does the open file button not work? - can we get this to open a finder window?

## License

MIT
