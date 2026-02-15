# Touchline - FM26 Accessibility Mod

**A BepInEx plugin that makes Football Manager 2026 accessible for blind and visually impaired players via screen readers.**

Touchline hooks into FM26's Unity-based UI to provide real-time screen reader output (NVDA, JAWS) and enhanced keyboard navigation. It uses the game's built-in keyboard navigation system to announce focused elements, read table data, and narrate screen transitions.

## Features

- **Focus-based announcements** — Automatically speaks the name, type, and state of the currently focused UI element
- **Menu and screen reading** — Reads all menus, options, and screens; announces screen transitions and provides parent context
- **Match day commentary** — Narrates live match events including score updates, goals, and commentary text
- **Read entire screen** — Press Ctrl+Shift+R to hear all visible text on the current screen
- **Table support** — Reads column headers and full row data when navigating tables
- **List position tracking** — Announces "X of Y" position when navigating lists and tables
- **Element state** — Announces checked/unchecked, selected, disabled states
- **Screen transitions** — Announces when you navigate to a new screen
- **Dynamic content detection** — Automatically announces popups, dialogs, and notifications
- **Rich text cleanup** — Strips Unity markup tags for clean screen reader output
- **UI deep scanner** — Debug tool that catalogs the entire UI hierarchy to a file
- **Configurable** — All features can be toggled via BepInEx configuration
- **Dual TTS backend** — Tolk (NVDA/JAWS) with Windows SAPI fallback
- **One-click installer** — `install.bat` automates the entire setup process

## Requirements

- Football Manager 26 (Unity IL2CPP) — **Steam, Epic Games, or Xbox Game Pass** editions are all supported
- [BepInEx 6.x for Unity IL2CPP](https://github.com/BepInEx/BepInEx)
- [NVDA](https://www.nvaccess.org/) or JAWS screen reader
- [Tolk](https://github.com/dkager/tolk) screen reader library (bundled with [releases](../../releases))

## Quick Start

### One-Click Install (Recommended)

1. Download **Touchline-FM26-Installer.zip** from the [Releases page](../../releases/latest)
2. Extract the ZIP anywhere on your computer
3. Double-click **`install.bat`** — it does everything automatically:
   - Finds your FM26 installation (Steam, Epic, or Xbox Game Pass)
   - Downloads and installs BepInEx (mod framework)
   - Downloads and installs Tolk (screen reader bridge)
   - Installs the Touchline accessibility mod
4. Start **NVDA** (or JAWS), then launch FM26
5. You should hear "Touchline accessibility mod loaded"

### Manual Install

1. Install BepInEx 6.x in your FM26 game folder
2. Run the game once to generate interop assemblies
3. Download `TouchlineMod.dll` from [Releases](../../releases) and `Tolk.dll` from the Tolk project
4. Place both in `<FM26 folder>/BepInEx/plugins/TouchlineMod/`
5. Start NVDA, then launch FM26
6. You should hear "Touchline accessibility mod loaded"

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

## Keyboard Shortcuts

| Key Combination | Action |
|----------------|--------|
| Ctrl+Shift+D | Toggle debug mode |
| Ctrl+Shift+S | Deep scan UI (saves TouchlineUIScan.txt) |
| Ctrl+Shift+W | "Where am I?" — Announce current focus |
| Ctrl+Shift+M | Read match score, minute, and commentary |
| Ctrl+Shift+R | Read entire visible screen |
| Ctrl+Shift+H | Help — List all shortcuts |
| Escape | Stop speech |
| Arrow Keys | Navigate (uses FM26's built-in nav) |
| Enter / Space | Activate focused element |

## Configuration

After first run, edit `BepInEx/config/com.touchline.fm26accessibility.cfg`:

```ini
[Speech]
Enabled = true
InterruptOnNew = true
AnnounceElementType = true
AnnounceElementState = true

[Navigation]
AutoReadOnFocus = true
AnnounceTableHeaders = true
ReadFullTableRow = true
FocusChangeDelay = 0.1

[Debug]
DebugMode = false
LogUIHierarchy = false
```

## Building from Source

Requires [.NET 6.0 SDK](https://dotnet.microsoft.com/download/dotnet/6.0) or later.

```bash
git clone https://github.com/MadnessInnsmouth/psychic-chainsaw.git
cd psychic-chainsaw
dotnet build TouchlineMod.sln -c Release
```

For a full build against the game's assemblies, set `FM26_PATH`:

```bash
export FM26_PATH="/path/to/Football Manager 26"
dotnet build TouchlineMod.sln -c Release
```

See [BUILDING.md](BUILDING.md) for complete build instructions.

## Project Structure

```
psychic-chainsaw/
├── install.bat                 # One-click installer (double-click to run)
├── install.ps1                 # PowerShell installer script
├── src/TouchlineMod/           # C# BepInEx plugin (the actual mod)
│   ├── Plugin.cs               # BepInEx entry point
│   ├── Core/                   # Speech output, text cleaning, manager
│   ├── Navigation/             # Focus tracking, accessible elements
│   ├── UI/                     # UI scanning, text extraction
│   ├── Patches/                # Harmony patches for FM26 events & match day
│   └── Config/                 # BepInEx configuration
├── libs/                       # Game library reference info
├── TouchlineMod.sln            # .NET solution file
├── INSTALL.md                  # Installation guide
├── BUILDING.md                 # Build from source guide
└── README.md                   # This file
```

## How It Works

Touchline monitors FM26's `FMNavigationManager.CurrentFocus` property to detect when the player navigates to a new UI element via keyboard. When focus changes:

1. **FocusTracker** detects the new focused `GameObject`
2. **TextExtractor** reads text from Unity UI components (Text, TextMeshPro, FM custom labels)
3. **TextCleaner** strips rich text markup for clean output
4. **AccessibleElement** builds a structured announcement (name, type, state, position)
5. **SpeechOutput** sends the announcement to NVDA/JAWS via Tolk, or to Windows SAPI

This approach leverages the game's existing keyboard navigation rather than implementing custom navigation, ensuring compatibility with game updates.

## Roadmap

- [x] Core plugin architecture (BepInEx 6, Harmony, IL2CPP)
- [x] Speech output (Tolk + SAPI fallback)
- [x] Focus tracking and announcements
- [x] Table header and row reading
- [x] UI deep scanner for debugging
- [x] Configurable via BepInEx config
- [x] One-click installer (install.bat)
- [x] Match day live commentary narration
- [x] Full screen reading (Ctrl+Shift+R)
- [x] Dynamic content detection (popups, dialogs, notifications)
- [x] List position tracking ("X of Y")
- [x] Parent context in announcements (screen/panel names)
- [ ] Tactics screen enhanced navigation
- [ ] Transfer market accessibility
- [ ] Audio cues for key events
- [ ] Braille display output via Tolk

## Acknowledgments

- [BepInEx](https://github.com/BepInEx/BepInEx) — Unity modding framework
- [Tolk](https://github.com/dkager/tolk) — Screen reader abstraction library
- [HarmonyX](https://github.com/BepInEx/HarmonyX) — Runtime method patching
- The FM modding community for documenting FM26's UI internals

## License

MIT License — See [LICENSE](LICENSE) for details.

---

**Version**: 0.3.0  
**Status**: Functional BepInEx plugin — download from the [Releases page](../../releases/latest), run `install.bat`, and play  
**Supported Stores**: Steam, Epic Games, Xbox Game Pass  
**Last Updated**: February 2026
