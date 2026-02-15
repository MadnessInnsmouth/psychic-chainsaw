# Project Touchline - Implementation Summary

## Overview

Touchline is a BepInEx plugin for Football Manager 2026 that provides screen reader
accessibility for blind and visually impaired players. The mod hooks into FM26's
Unity IL2CPP runtime to read UI elements and send announcements to screen readers
(NVDA/JAWS) via the Tolk library.

## Architecture

The mod is built as a BepInEx 6 plugin targeting .NET 6.0. It uses:
- **BepInEx** for plugin loading and configuration
- **HarmonyX** for runtime method patching
- **Tolk** for screen reader integration (NVDA, JAWS)
- **Windows SAPI** as a TTS fallback when no screen reader is detected

### Components

| Component | File | Purpose |
|-----------|------|---------|
| Plugin entry | `Plugin.cs` | BepInEx lifecycle, initialization |
| Accessibility manager | `Core/AccessibilityManager.cs` | Coordinates all features, handles hotkeys |
| Speech output | `Core/SpeechOutput.cs` | Tolk + SAPI TTS with fallback chain |
| Text cleaner | `Core/TextCleaner.cs` | Strips Unity rich text tags |
| Focus tracker | `Navigation/FocusTracker.cs` | Monitors `FMNavigationManager.CurrentFocus` |
| Accessible element | `Navigation/AccessibleElement.cs` | Data model for UI announcements |
| UI scanner | `UI/UIScanner.cs` | Deep-scans Unity hierarchy for debugging |
| Text extractor | `UI/TextExtractor.cs` | Extracts text from Unity/FM components |
| Focus patches | `Patches/FocusPatches.cs` | Harmony patches for focus events |
| Configuration | `Config/TouchlineConfig.cs` | BepInEx config entries |

### Previous Work (Prototype)

The `prototype/` directory contains the original Python proof-of-concept with
simulated FM26 screens using pyttsx3. This was used to validate accessibility
patterns before building the real BepInEx mod.

---

**Version**: 0.2.0
**Status**: BepInEx plugin ready for testing
**Date**: February 2026
