# Distribution Guide - Bundling Options

This guide explains the different ways to distribute the Touchline mod installer and the pros/cons of each approach.

## Option 1: Separate Zips (Current GitHub Releases Approach)

**Files distributed separately:**
- `install.bat` + `install.ps1` (installer scripts)
- `TouchlineMod.dll` (via GitHub releases)
- `tolk-x64.zip` (via GitHub releases)
- BepInEx (downloaded from BepInEx repository)

**Pros:**
- Small download size for the installer scripts
- Users only download what they need
- Easier to update individual components
- Complies with licensing (BepInEx has its own release)

**Cons:**
- Requires internet connection during installation
- Multiple download sources (can fail if one is unavailable)
- More complex installation process
- GitHub release must exist or installer will fail

**When to use:**
- For GitHub releases where bandwidth is a concern
- When you want users to always get the latest versions
- When components update at different rates

## Option 2: Single Bundled Zip (Recommended for Easy Distribution)

**All files in one package:**
- `install.bat` + `install.ps1` (installer scripts)
- `TouchlineMod.dll` (pre-included)
- `tolk-x64.zip` (pre-included)
- `BepInEx-Unity.IL2CPP-win-x64.zip` (optional, adds ~40 MB)

**Created with:**
```powershell
.\package-installer.ps1
```

**Pros:**
- ✅ **Works completely offline** - no internet required
- ✅ **Single download** - users get everything at once
- ✅ **Faster installation** - no downloads during install
- ✅ **More reliable** - doesn't depend on external URLs
- ✅ **Better user experience** - just extract and run
- ✅ **Installer still searches for existing files** - won't reinstall if found

**Cons:**
- Larger download size (5-10 MB without BepInEx, 45-50 MB with BepInEx)
- Need to rebuild package when any component updates
- May include older versions if not updated regularly

**When to use:**
- For end users who want simplicity
- For offline/restricted network environments
- For distribution via USB drives or local networks
- When reliability is more important than download size

## Option 3: Hybrid Approach (Best of Both Worlds)

**Offer both distribution methods:**
1. Small installer package (Option 1) for online users
2. Full bundled package (Option 2) for offline users

**Distribution:**
- GitHub Releases: Both packages available
  - `Touchline-FM26-Installer-Online.zip` (~100 KB)
  - `Touchline-FM26-Installer-Complete.zip` (~5-10 MB)
  - Optional: `Touchline-FM26-Installer-Full.zip` (~50 MB with BepInEx)

**The installer automatically:**
1. Searches local system for existing DLLs first
2. Uses bundled files if available
3. Downloads from internet if needed

**Pros:**
- Users choose based on their needs
- Works in all scenarios
- Maximum flexibility

**Cons:**
- Need to maintain multiple packages
- More complex release process

**When to use:**
- For public releases where user needs vary
- When you want maximum accessibility
- Recommended approach for production

## Recommendation

**For this project, use Option 3 (Hybrid Approach):**

1. **Create packages:**
   ```powershell
   # Online-only installer (small)
   Copy-Item install.bat Touchline-Online\
   Copy-Item install.ps1 Touchline-Online\
   Compress-Archive Touchline-Online\* Touchline-FM26-Installer-Online.zip
   
   # Complete offline installer (medium)
   .\package-installer.ps1
   # Creates Touchline-FM26-Installer.zip with TouchlineMod + Tolk
   
   # Full offline installer with BepInEx (large)
   # Place BepInEx zip in current directory first, then:
   .\package-installer.ps1
   # Rename output to Touchline-FM26-Installer-Full.zip
   ```

2. **Upload to GitHub Releases:**
   - All three packages
   - Individual DLLs (TouchlineMod.dll, tolk-x64.zip)
   - Clear descriptions of each package

3. **Update README:**
   - Recommend complete package for most users
   - Online package for advanced users or bandwidth concerns
   - Full package for completely offline installations

## Technical Details

### How the Installer Handles Bundled Files

The improved installer uses a **multi-strategy approach**:

```
For each required component:
  1. Check if already installed in target location → DONE
  2. Search entire local system for existing installations → Use local copy
  3. Check for bundled files in installer directory → Use bundled files
  4. Download from internet → Use downloaded files
  5. If all fail → Clear error message with manual instructions
```

This means:
- Bundled installer works offline ✅
- Online installer still works (downloads when needed) ✅
- If user has files elsewhere, installer finds and uses them ✅
- No duplicate downloads or installations ✅

### Package Size Comparison

| Package Type | Size | Contents |
|-------------|------|----------|
| Online installer | ~100 KB | Just scripts |
| Complete installer | ~5-10 MB | Scripts + TouchlineMod + Tolk |
| Full installer | ~45-50 MB | Scripts + TouchlineMod + Tolk + BepInEx |

### Licensing Considerations

- **TouchlineMod**: Your code, MIT license - ✅ Can bundle
- **Tolk**: You build from source, bundled in releases - ✅ Can bundle
- **BepInEx**: External project with LGPL-2.1 - ⚠️ Best to let users download or provide separately

## Conclusion

**For maximum user convenience and reliability, bundle all DLLs except BepInEx.**

Users can either:
- Download complete package (5-10 MB) for offline installation
- Download online package (100 KB) and let installer download what's needed
- Place BepInEx zip alongside installer for fully offline installation

The flexible installer handles all scenarios automatically!
