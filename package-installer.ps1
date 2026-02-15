# ============================================================
# Touchline - Installer Package Builder
# ============================================================
#
# This script creates a complete installer package containing:
#   1. install.bat and install.ps1 (installer scripts)
#   2. TouchlineMod.dll (the mod itself)
#   3. tolk-x64.zip (screen reader library bundle)
#   4. BepInEx-Unity.IL2CPP-win-x64.zip (optional - if available)
#
# The packaged installer can run completely offline if all
# dependencies are included.
#
# Usage: ./package-installer.ps1
#
# Output: Creates "Touchline-FM26-Installer.zip" in the current directory
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Touchline Installer Package Builder" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Determine script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path $env:TEMP "touchline_installer_package"
$outputZip = Join-Path $scriptDir "Touchline-FM26-Installer.zip"

# Clean up previous build
if (Test-Path $outputDir) {
    Remove-Item $outputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

Write-Host ">> Packaging installer files..." -ForegroundColor Cyan
Write-Host ""

# Copy core installer files
Write-Host "   [1/5] Copying installer scripts..." -ForegroundColor White
Copy-Item (Join-Path $scriptDir "install.bat") -Destination $outputDir -Force
Copy-Item (Join-Path $scriptDir "install.ps1") -Destination $outputDir -Force
Write-Host "   [OK] Installer scripts copied" -ForegroundColor Green

# Copy TouchlineMod.dll if available
Write-Host ""
Write-Host "   [2/5] Looking for TouchlineMod.dll..." -ForegroundColor White
$modDllPaths = @(
    (Join-Path $scriptDir "src\TouchlineMod\bin\Release\net6.0\TouchlineMod.dll"),
    (Join-Path $scriptDir "src\TouchlineMod\bin\Debug\net6.0\TouchlineMod.dll"),
    (Join-Path $scriptDir "TouchlineMod.dll")
)

$modDllFound = $false
foreach ($path in $modDllPaths) {
    if (Test-Path $path) {
        Copy-Item $path -Destination $outputDir -Force
        Write-Host "   [OK] TouchlineMod.dll copied from build" -ForegroundColor Green
        $modDllFound = $true
        break
    }
}

if (-not $modDllFound) {
    Write-Host "   [!] TouchlineMod.dll not found - users will need to download from release" -ForegroundColor Yellow
}

# Copy tolk-x64 directory or zip if available
Write-Host ""
Write-Host "   [3/5] Looking for Tolk libraries..." -ForegroundColor White
$tolkZip = Join-Path $scriptDir "tolk-x64.zip"
$tolkDir = Join-Path $scriptDir "tolk-x64"

$tolkFound = $false
if (Test-Path $tolkZip) {
    Copy-Item $tolkZip -Destination $outputDir -Force
    Write-Host "   [OK] tolk-x64.zip copied" -ForegroundColor Green
    $tolkFound = $true
} elseif (Test-Path $tolkDir) {
    # Create zip from directory
    $destZip = Join-Path $outputDir "tolk-x64.zip"
    Compress-Archive -Path "$tolkDir\*" -DestinationPath $destZip -Force
    Write-Host "   [OK] tolk-x64.zip created from directory" -ForegroundColor Green
    $tolkFound = $true
}

if (-not $tolkFound) {
    Write-Host "   [!] Tolk libraries not found - users will need to download from release" -ForegroundColor Yellow
}

# Copy BepInEx zip if available (optional)
Write-Host ""
Write-Host "   [4/5] Looking for BepInEx package..." -ForegroundColor White
$bepInExZips = Get-ChildItem "$scriptDir\BepInEx-Unity.IL2CPP-win-x64*.zip" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1

if ($bepInExZips) {
    Copy-Item $bepInExZips.FullName -Destination $outputDir -Force
    Write-Host "   [OK] BepInEx package copied ($($bepInExZips.Name))" -ForegroundColor Green
    Write-Host "       NOTE: Including BepInEx (~40 MB) makes the installer fully offline-capable" -ForegroundColor Gray
} else {
    Write-Host "   [!] BepInEx package not found - installer will download it when needed" -ForegroundColor Yellow
}

# Create README for the installer package
Write-Host ""
Write-Host "   [5/5] Creating README..." -ForegroundColor White
$readmeContent = @"
# Touchline - FM26 Accessibility Mod Installer

## Quick Start

1. Extract this ZIP to any location on your computer
2. Double-click **install.bat**
3. Follow the on-screen instructions

## What's Included

This installer package contains:
- **install.bat** / **install.ps1** - Automated installation scripts
- **TouchlineMod.dll** - The accessibility mod (if pre-built)
- **tolk-x64.zip** - Screen reader integration library (if bundled)
- **BepInEx package** - Mod framework (if bundled)

## Installation Process

The installer will:
1. Find your Football Manager 2026 installation
2. Install BepInEx 6 (mod framework)
3. Install Tolk (screen reader bridge)
4. Install Touchline (the accessibility mod)

## Offline Installation

This installer can work **completely offline** if all dependencies are bundled.
If files are not included in this package, the installer will:
1. First search your computer for existing installations
2. Download missing files from the internet if needed

## Requirements

- Windows 10/11
- Football Manager 2026 (Steam, Epic Games, or Xbox Game Pass)
- NVDA or JAWS screen reader

## Support

- GitHub: https://github.com/MadnessInnsmouth/psychic-chainsaw
- Issues: https://github.com/MadnessInnsmouth/psychic-chainsaw/issues

## License

MIT License - See repository for details
"@

Set-Content -Path (Join-Path $outputDir "README.txt") -Value $readmeContent -Force
Write-Host "   [OK] README.txt created" -ForegroundColor Green

# Create the final package
Write-Host ""
Write-Host ">> Creating installer package..." -ForegroundColor Cyan
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

Compress-Archive -Path "$outputDir\*" -DestinationPath $outputZip -Force

# Clean up temp directory
Remove-Item $outputDir -Recurse -Force

# Show results
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Package created successfully!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Output: $outputZip" -ForegroundColor White

$zipSize = (Get-Item $outputZip).Length / 1MB
Write-Host "  Size: $([Math]::Round($zipSize, 2)) MB" -ForegroundColor White

Write-Host ""
Write-Host "  Distribution Options:" -ForegroundColor Cyan
Write-Host "  1. Upload to GitHub Releases for users to download" -ForegroundColor Gray
Write-Host "  2. Share directly with users for offline installation" -ForegroundColor Gray
Write-Host ""

Write-Host "  What's Next:" -ForegroundColor Cyan
Write-Host "  - Users extract the ZIP anywhere on their computer" -ForegroundColor Gray
Write-Host "  - Users double-click install.bat" -ForegroundColor Gray
Write-Host "  - Installer handles everything automatically" -ForegroundColor Gray
Write-Host ""
