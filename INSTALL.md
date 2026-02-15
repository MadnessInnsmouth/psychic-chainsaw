# Installing Touchline - FM26 Accessibility Mod

## One-Click Install (Recommended)

The easiest way to install Touchline is the one-click installer:

1. Download the latest release ZIP from [Releases](../../releases)
2. **Extract the ZIP** to any folder on your computer (e.g. your Desktop or Downloads)
3. **Double-click `install.bat`** inside the extracted folder — that's it!

> **Important**: You must extract the ZIP first. The installer cannot run from inside a ZIP file. Right-click the ZIP and choose "Extract All", then open the extracted folder and double-click `install.bat`.

The installer automatically:
- Finds your Football Manager 2026 installation (Steam, Epic Games, or Xbox Game Pass)
- Uses the DLL files bundled in the extracted installer folder (Tolk.dll, TouchlineMod.dll, etc.)
- Downloads any missing files from the internet only if not found in the installer folder
- Installs BepInEx 6 (the mod framework)
- Installs Tolk (screen reader bridge for NVDA/JAWS)
- Installs the Touchline accessibility mod

After installation:
1. Start **NVDA** (or JAWS) screen reader
2. Launch **Football Manager 2026**
3. You should hear "Touchline accessibility mod loaded"

> **Note**: On the very first launch after installing BepInEx, the game will start and then **shut down automatically**. This is normal — BepInEx needs to generate interop assemblies. Simply launch the game again and it will work normally.

> **Note**: If the installer can't find FM26 automatically, it will ask you to enter the path.

## Offline Installation

The installer is designed to work **completely offline** if you have the bundled installer package:

### What's included in the installer ZIP:
- **install.bat** / **install.ps1** — Installer scripts
- **TouchlineMod.dll** — The accessibility mod
- **tolk-x64.zip** — Screen reader library bundle (Tolk.dll + companion DLLs)

### To install offline:
1. Extract the installer ZIP to any folder
2. Ensure the bundled files (TouchlineMod.dll, tolk-x64.zip) are in the same folder as install.bat
3. Run `install.bat` — the installer uses the files from its own folder first

> **Note**: The installer only searches its own folder for DLL files. It does **not** scan your entire system.

### Creating a bundled installer:
Run `package-installer.ps1` to create a single ZIP containing everything:
```powershell
.\package-installer.ps1
```

This creates `Touchline-FM26-Installer.zip` with all dependencies included for fully offline installation.

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

### Installer Issues

If the installer fails or behaves unexpectedly:
- Check the **installer log file** at `touchline-installer.log` (in the same folder as `install.bat`)
- The log contains detailed information about each installation step, including errors and system information
- Share the contents of this log file when reporting issues — it helps diagnose problems quickly
- The log file is automatically cleared each time you run the installer, so it always contains fresh information

### Game starts but closes immediately
- **On the very first launch after installing BepInEx**, the game will start and then shut down automatically. This is expected — BepInEx generates interop assemblies on the first run and the game exits during this process. Simply launch the game again and it will work normally.
- **On the second launch**, if the game still closes, check that `BepInEx/interop/` contains `.dll` files. If not, try running the game once more — BepInEx sometimes needs two launches to finish generating everything.
- If the game keeps closing, check `BepInEx/LogOutput.log` for errors.
- Make sure you're using the correct BepInEx version (Unity IL2CPP x64).
- Verify `winhttp.dll` (the BepInEx doorstop) exists in your FM26 game folder next to the game `.exe`.

### NVDA not detected
- Ensure NVDA is running **before** launching the game.
- Verify that **both** `Tolk.dll` **and** `nvdaControllerClient64.dll` are in the `BepInEx/plugins/TouchlineMod/` folder. Tolk.dll needs the NVDA controller DLL to communicate with NVDA.
- Check `BepInEx/LogOutput.log` for messages from Touchline about screen reader detection.

### No speech output
- Ensure NVDA (or JAWS) is running before launching the game.
- Verify `Tolk.dll` (x64) and its companion DLLs (`nvdaControllerClient64.dll`, `SAAPI64.dll`) are all in the plugin folder.
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
