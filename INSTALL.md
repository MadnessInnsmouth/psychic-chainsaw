# Installing Touchline - FM26 Accessibility Mod

## One-Click Install (Recommended)

The easiest way to install Touchline is the one-click installer:

1. Download the latest release from [Releases](../../releases) or clone the repository
2. **Double-click `install.bat`** — that's it!

The installer automatically:
- Finds your Football Manager 2026 installation (Steam, Epic Games, or Xbox Game Pass)
- Downloads and installs BepInEx 6 (the mod framework)
- Downloads and installs Tolk (screen reader bridge for NVDA/JAWS)
- Installs the Touchline accessibility mod

After installation:
1. Start **NVDA** (or JAWS) screen reader
2. Launch **Football Manager 2026**
3. You should hear "Touchline accessibility mod loaded"

> **Note**: If the installer can't find FM26 automatically, it will ask you to enter the path.

---

## Manual Installation

If you prefer to install manually, follow these steps:

## Prerequisites

- **Football Manager 26** (Steam, Epic Games, or Xbox Game Pass)
- **BepInEx 6.x** for Unity IL2CPP
- **NVDA screen reader** (recommended) or **JAWS**
- **Tolk.dll** (for screen reader integration)

## Step 1: Install BepInEx

1. Download **BepInEx 6.x IL2CPP** from:
   - [BepInEx GitHub Releases](https://github.com/BepInEx/BepInEx/releases) (choose the `BepInEx_UnityIL2CPP_x64` package)
   - Or [Thunderstore BepInExPack for FM26](https://thunderstore.io/c/football-manager-26/p/BepInEx/BepInExPack_FootballManager26/)

2. Extract the contents into your FM26 game folder:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\Football Manager 26\
   ```
   After extraction, you should see a `BepInEx` folder alongside `Football Manager 26.exe`.

3. **Run the game once** and then close it. This generates the BepInEx configuration
   and interop assemblies needed by mods.

4. Verify that `BepInEx/interop/` contains `.dll` files (these are auto-generated).

## Step 2: Install Tolk (Screen Reader Library)

1. Download `tolk-x64.zip` from this project's [Releases page](../../releases) (it is bundled with each release).
2. Extract the DLLs (`Tolk.dll`, `nvdaControllerClient64.dll`, `SAAPI64.dll`) from the archive.
3. Place them in:
   ```
   <FM26 folder>\BepInEx\plugins\TouchlineMod\
   ```

> **Note**: The upstream Tolk repository (https://github.com/dkager/tolk) does not publish
> pre-built releases. Touchline builds Tolk from source and bundles it automatically.

## Step 3: Install Touchline

### Option A: Download Release (Recommended)

1. Download `TouchlineMod.dll` from the [Releases page](../../releases).
2. Create the plugin folder:
   ```
   <FM26 folder>\BepInEx\plugins\TouchlineMod\
   ```
3. Copy `TouchlineMod.dll` into that folder.

### Option B: Build from Source

See [BUILDING.md](BUILDING.md) for instructions.

## Step 4: Launch and Verify

1. Start your **NVDA** (or JAWS) screen reader.
2. Launch **Football Manager 26**.
3. You should hear "Touchline accessibility mod loaded" when the game starts.
4. After a few seconds, the mod begins tracking UI focus.

## Keyboard Shortcuts

### Mod Controls

| Key Combination | Action |
|----------------|--------|
| **Ctrl+Shift+D** | Toggle debug mode |
| **Ctrl+Shift+S** | Deep scan UI (saves to `TouchlineUIScan.txt`) |
| **Ctrl+Shift+W** | "Where am I?" - Announce current focus with context |
| **Ctrl+Shift+M** | Read match score, minute, and commentary |
| **Ctrl+Shift+R** | Read entire visible screen |
| **Ctrl+Shift+H** | Announce help / keyboard shortcuts |
| **Escape** | Stop speech |

### Game Navigation

The mod works with FM26's built-in keyboard navigation:

| Key | Action |
|-----|--------|
| **Arrow Keys** | Navigate between UI elements |
| **Enter / Space** | Activate the focused element |
| **Tab** | Move to next element |
| **Shift+Tab** | Move to previous element |

## Configuration

After first run, a config file is created at:
```
<FM26 folder>\BepInEx\config\com.touchline.fm26accessibility.cfg
```

You can edit this file to customize:
- **Speech**: Enable/disable speech, interrupt behavior, element type/state announcements
- **Navigation**: Auto-read on focus, table headers, row reading, focus delay
- **Debug**: Debug mode, UI hierarchy logging

## Troubleshooting

### No speech output
- Ensure NVDA (or JAWS) is running before launching the game.
- Verify `Tolk.dll` (x64) is in the plugin folder.
- Check `BepInEx/LogOutput.log` for error messages from Touchline.

### Mod not loading
- Verify BepInEx is installed correctly (look for `BepInEx/LogOutput.log` after launching).
- Make sure `TouchlineMod.dll` is in `BepInEx/plugins/TouchlineMod/`.
- Check the BepInEx log for loading errors.

### Focus not tracked
- FM26's keyboard navigation must be active (use Tab/arrows to navigate).
- Try pressing Ctrl+Shift+W to check if the mod detects the current focus.
- Run Ctrl+Shift+S to deep-scan the UI and check `TouchlineUIScan.txt`.

### Xbox Game Pass / Microsoft Store
- The installer auto-detects Game Pass installations. If it can't find FM26, enter the path manually when prompted.
- Xbox Game Pass installs may use a `WindowsApps` folder with restricted permissions. If you get an access error, try running `install.bat` as administrator (right-click → "Run as administrator").

## Uninstalling

1. Delete the `BepInEx/plugins/TouchlineMod/` folder.
2. Optionally delete the config: `BepInEx/config/com.touchline.fm26accessibility.cfg`.
