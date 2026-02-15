# Building Touchline from Source

## Prerequisites

- [.NET 6.0 SDK](https://dotnet.microsoft.com/download/dotnet/6.0) or later
- Football Manager 26 installed with BepInEx 6.x (for full build)
- Git

## Quick Build (Without Game)

For development and CI, the project can compile using NuGet packages as stand-ins
for the game's DLLs. This mode validates code correctness but the output DLL
won't include game-specific integrations.

```bash
git clone https://github.com/MadnessInnsmouth/psychic-chainsaw.git
cd psychic-chainsaw
dotnet restore TouchlineMod.sln
dotnet build TouchlineMod.sln -c Release
```

The output DLL will be at: `src/TouchlineMod/bin/Release/net6.0/TouchlineMod.dll`

## Full Build (With Game)

For a production build that references the actual game assemblies:

### 1. Set Game Path

Set the `FM26_PATH` environment variable to your FM26 installation:

**Windows (PowerShell):**
```powershell
$env:FM26_PATH = "C:\Program Files (x86)\Steam\steamapps\common\Football Manager 26"
```

**Windows (CMD):**
```cmd
set FM26_PATH=C:\Program Files (x86)\Steam\steamapps\common\Football Manager 26
```

**Linux (Proton/Wine):**
```bash
export FM26_PATH="$HOME/.steam/steam/steamapps/common/Football Manager 26"
```

### 2. Ensure BepInEx is Installed

BepInEx 6.x must be installed in the game folder and the game must have been run
at least once to generate the interop assemblies in `BepInEx/interop/`.

### 3. Build

```bash
dotnet build TouchlineMod.sln -c Release
```

The build automatically copies `TouchlineMod.dll` to `<FM26_PATH>/BepInEx/plugins/TouchlineMod/`.

## Project Structure

```
src/TouchlineMod/
├── Plugin.cs                  # BepInEx plugin entry point
├── TouchlineMod.csproj        # Project file with dual-mode references
├── Core/
│   ├── AccessibilityManager.cs # Central coordinator MonoBehaviour
│   ├── SpeechOutput.cs        # TTS via Tolk (NVDA/JAWS) + SAPI fallback
│   └── TextCleaner.cs         # Rich text cleanup for screen readers
├── Navigation/
│   ├── AccessibleElement.cs   # Data model for accessible UI elements
│   └── FocusTracker.cs        # Monitors focus changes in FM26's UI
├── UI/
│   ├── UIScanner.cs           # Deep-scans Unity UI hierarchy
│   └── TextExtractor.cs       # Extracts readable text from UI components
├── Patches/
│   └── FocusPatches.cs        # Harmony patches for FM26 navigation events
└── Config/
    └── TouchlineConfig.cs     # BepInEx configuration entries
```

## How the Dual-Mode Build Works

The `.csproj` file detects whether the game is installed:

- **Game found** (`UseGameRefs=true`): References actual DLLs from `BepInEx/core/` and
  `BepInEx/interop/`. The output is a fully functional mod.
- **Game not found** (`UseGameRefs=false`): Uses NuGet packages (`BepInEx.Core`,
  `HarmonyX`) for compilation. Unity and game types are accessed via reflection,
  so the code compiles but some features require the real game to function.

## Running Tests

```bash
dotnet test TouchlineMod.sln
```

Note: Most functionality requires the game runtime to test. Use the debug mode
(Ctrl+Shift+D in-game) and UI scanner (Ctrl+Shift+S) for runtime testing.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure the project builds with `dotnet build`
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.
