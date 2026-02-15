# Game Library References

This directory is a placeholder for FM26 game libraries needed for building with full game integration.

## When building without the game (CI/development)

The project will automatically use NuGet packages for BepInEx APIs when the game
DLLs are not found. This allows the project to compile for development purposes.

## When building against the real game

1. Set the `FM26_PATH` environment variable to your FM26 installation directory:
   ```
   set FM26_PATH=C:\Program Files (x86)\Steam\steamapps\common\Football Manager 26
   ```

2. Make sure BepInEx 6.x is installed in the game directory and the game has been
   run at least once (to generate interop assemblies).

3. Optionally place `Tolk.dll` (x64) in this directory or in the game's
   `BepInEx/plugins/TouchlineMod/` folder for screen reader integration.

## Required assemblies (auto-detected from game)

The build system looks for these in `<FM26_PATH>/BepInEx/`:

### BepInEx Core (`core/`)
- `BepInEx.Core.dll`
- `BepInEx.Unity.IL2CPP.dll`
- `Il2CppInterop.Runtime.dll`
- `0Harmony.dll`

### Unity Interop (`interop/`)
- `UnityEngine.dll`
- `UnityEngine.CoreModule.dll`
- `UnityEngine.UI.dll`
- `UnityEngine.UIModule.dll`
- `UnityEngine.IMGUIModule.dll`
- `UnityEngine.InputLegacyModule.dll`
- `Unity.InputSystem.dll`

### FM26 Game Assemblies (`interop/`)
- `FM.UI.dll`
- `SI.Core.dll`
- `SI.UI.dll`

## Tolk (Screen Reader Library)

The upstream Tolk repository (https://github.com/dkager/tolk) provides source code but does
not publish pre-built releases. The Touchline release workflow builds Tolk from source and
bundles it as `tolk-x64.zip`. You can also download the latest bundle from the
[Releases page](../../../releases).

Place the x64 `Tolk.dll` in the game's plugin folder alongside `TouchlineMod.dll`.
