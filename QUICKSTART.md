# Touchline Quick Start Guide

Get the FM26 accessibility mod running in under a minute.

## One-Click Install

1. Download the latest release from [Releases](../../releases)
2. **Double-click `install.bat`** — it does everything automatically
3. Start **NVDA**, then launch FM26
4. You should hear "Touchline accessibility mod loaded"

That's it! The installer finds FM26, downloads BepInEx and Tolk, and sets everything up.

## Prerequisites (Manual Install Only)

- Football Manager 26 installed
- [BepInEx 6.x IL2CPP](https://github.com/BepInEx/BepInEx/releases)
- [NVDA screen reader](https://www.nvaccess.org/)
- [Tolk.dll](https://github.com/dkager/tolk/releases) (x64)

## Manual Install

1. **BepInEx**: Extract into your FM26 game folder, run the game once, then close it.

2. **Touchline**: Copy `TouchlineMod.dll` and `Tolk.dll` to:
   ```
   <FM26 folder>/BepInEx/plugins/TouchlineMod/
   ```

3. **Launch**: Start NVDA, then launch FM26. You should hear "Touchline accessibility mod loaded".

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys | Navigate UI elements |
| Enter / Space | Activate element |
| Ctrl+Shift+W | "Where am I?" |
| Ctrl+Shift+M | Match score and commentary |
| Ctrl+Shift+R | Read entire screen |
| Ctrl+Shift+H | Help |
| Ctrl+Shift+D | Toggle debug mode |
| Ctrl+Shift+S | Deep scan UI |
| Escape | Stop speech |

## Configuration

Edit `BepInEx/config/com.touchline.fm26accessibility.cfg` to adjust speech, navigation, and debug settings.

## Building from Source

```bash
dotnet build TouchlineMod.sln -c Release
```

For full details, see [INSTALL.md](INSTALL.md) and [BUILDING.md](BUILDING.md).

## Running the Python Prototype

The `prototype/` directory contains the original proof-of-concept:

```bash
cd prototype
pip install pyttsx3
python demo.py
```

---

**Version**: 0.3.0  
**Status**: BepInEx plugin ready for testing
