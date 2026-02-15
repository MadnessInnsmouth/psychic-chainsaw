# ============================================================
# Touchline - FM26 Accessibility Mod - One-Click Installer
# ============================================================
#
# This script automatically:
#   1. Finds your Football Manager 2026 installation
#   2. Downloads and installs BepInEx 6 (mod framework)
#   3. Downloads and installs Tolk (screen reader bridge)
#   4. Downloads and installs Touchline (the accessibility mod)
#   5. Launches FM26 once to generate required files
#
# Usage: Right-click install.ps1 -> "Run with PowerShell"
#   Or:  Double-click install.bat (which calls this script)
#
# Requirements: Windows 10/11, Football Manager 2026 (Steam or Epic)
# ============================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Speed up Invoke-WebRequest

# --- Version Configuration ---
$BepInExVersion = "6.0.0-be.762"
$BepInExUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$BepInExVersion/BepInEx-Unity.IL2CPP-win-x64-$BepInExVersion.zip"
$TolkUrl = "https://github.com/dkager/tolk/releases/latest/download/tolk-x64.zip"
$TouchlineReleasesApi = "https://api.github.com/repos/MadnessInnsmouth/psychic-chainsaw/releases/latest"

# --- Colours and output ---
function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "   [!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "   [ERROR] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Touchline - FM26 Accessibility Mod Installer" -ForegroundColor White
Write-Host "  Making Football Manager 2026 accessible for everyone" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# Step 1: Find Football Manager 2026
# ============================================================
Write-Step "Looking for Football Manager 2026..."

$FM26Path = $null

# Search common Steam library locations
$steamPaths = @(
    "$env:ProgramFiles (x86)\Steam\steamapps\common\Football Manager 26",
    "$env:ProgramFiles\Steam\steamapps\common\Football Manager 26",
    "C:\Steam\steamapps\common\Football Manager 26",
    "D:\SteamLibrary\steamapps\common\Football Manager 26",
    "E:\SteamLibrary\steamapps\common\Football Manager 26",
    "F:\SteamLibrary\steamapps\common\Football Manager 26"
)

# Also try to read Steam library folders from libraryfolders.vdf
$steamConfigPath = "$env:ProgramFiles (x86)\Steam\steamapps\libraryfolders.vdf"
if (Test-Path $steamConfigPath) {
    $vdfContent = Get-Content $steamConfigPath -Raw
    $pathMatches = [regex]::Matches($vdfContent, '"path"\s+"([^"]+)"')
    foreach ($match in $pathMatches) {
        $libPath = $match.Groups[1].Value -replace '\\\\', '\'
        $steamPaths += "$libPath\steamapps\common\Football Manager 26"
    }
}

# Epic Games common locations
$steamPaths += @(
    "$env:ProgramFiles\Epic Games\FootballManager26",
    "$env:ProgramFiles (x86)\Epic Games\FootballManager26"
)

foreach ($path in $steamPaths) {
    if (Test-Path "$path\Football Manager 26.exe") {
        $FM26Path = $path
        break
    }
    # Also check for fm.exe variant
    if (Test-Path "$path\fm.exe") {
        $FM26Path = $path
        break
    }
}

# If not found, ask the user
if (-not $FM26Path) {
    Write-Warn "Could not auto-detect Football Manager 2026."
    Write-Host ""
    Write-Host "   Please enter the full path to your FM26 folder" -ForegroundColor White
    Write-Host '   Example: C:\Program Files (x86)\Steam\steamapps\common\Football Manager 26' -ForegroundColor Gray
    Write-Host ""
    $FM26Path = Read-Host "   FM26 path"
    $FM26Path = $FM26Path.Trim('"').Trim()
    if (-not (Test-Path $FM26Path)) {
        Write-Err "Path not found: $FM26Path"
        Write-Host "   Please check the path and try again."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Ok "Found FM26 at: $FM26Path"

# ============================================================
# Step 2: Install BepInEx 6 (if not already present)
# ============================================================
Write-Step "Checking BepInEx installation..."

$bepInExCoreDll = Join-Path $FM26Path "BepInEx\core\BepInEx.Core.dll"
$bepInExDoorStop = Join-Path $FM26Path "winhttp.dll"

if ((Test-Path $bepInExCoreDll) -and (Test-Path $bepInExDoorStop)) {
    Write-Ok "BepInEx is already installed"
} else {
    Write-Host "   Downloading BepInEx 6..." -ForegroundColor White
    $bepZip = Join-Path $env:TEMP "bepinex_fm26.zip"
    try {
        Invoke-WebRequest -Uri $BepInExUrl -OutFile $bepZip -UseBasicParsing
        Write-Ok "Downloaded BepInEx"
    } catch {
        Write-Warn "Could not download BepInEx from primary URL."
        Write-Host "   Trying alternate URL..." -ForegroundColor Gray
        try {
            $altUrl = "https://builds.bepinex.dev/projects/bepinex_be/762/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.762%2B062d7d0.zip"
            Invoke-WebRequest -Uri $altUrl -OutFile $bepZip -UseBasicParsing
            Write-Ok "Downloaded BepInEx from alternate source"
        } catch {
            Write-Err "Failed to download BepInEx. Please download it manually from:"
            Write-Host "   https://github.com/BepInEx/BepInEx/releases" -ForegroundColor Yellow
            Write-Host "   Extract it into: $FM26Path" -ForegroundColor Yellow
            Read-Host "Press Enter to continue after manual install"
        }
    }

    if (Test-Path $bepZip) {
        Write-Host "   Installing BepInEx..." -ForegroundColor White
        Expand-Archive -Path $bepZip -DestinationPath $FM26Path -Force
        Remove-Item $bepZip -ErrorAction SilentlyContinue
        Write-Ok "BepInEx installed"
    }
}

# ============================================================
# Step 3: Generate interop assemblies (run game once if needed)
# ============================================================
Write-Step "Checking interop assemblies..."

$interopDir = Join-Path $FM26Path "BepInEx\interop"

if ((Test-Path $interopDir) -and (Get-ChildItem "$interopDir\*.dll" -ErrorAction SilentlyContinue).Count -gt 0) {
    Write-Ok "Interop assemblies already generated"
} else {
    Write-Host "   BepInEx needs to run once to generate interop assemblies." -ForegroundColor White
    Write-Host "   The game will launch briefly and then you should close it." -ForegroundColor White
    Write-Host ""

    $gameExe = Get-ChildItem "$FM26Path\*.exe" | Where-Object { $_.Name -notlike "Unins*" -and $_.Name -notlike "crash*" } | Select-Object -First 1
    if ($gameExe) {
        Write-Host "   Press Enter to launch FM26 (close it once you see the main menu)..." -ForegroundColor Yellow
        Read-Host

        Start-Process $gameExe.FullName -WorkingDirectory $FM26Path
        Write-Host "   Waiting for game to generate assemblies (this may take 30-60 seconds)..." -ForegroundColor Gray
        Write-Host "   Close the game when you see the main menu or title screen." -ForegroundColor Gray
        Write-Host ""
        Read-Host "   Press Enter after you've closed the game"
    } else {
        Write-Warn "Could not find game executable. Please run FM26 once manually, then re-run this installer."
    }
}

# ============================================================
# Step 4: Install Tolk (screen reader bridge)
# ============================================================
Write-Step "Installing Tolk (screen reader bridge)..."

$pluginDir = Join-Path $FM26Path "BepInEx\plugins\TouchlineMod"
if (-not (Test-Path $pluginDir)) {
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
}

$tolkDll = Join-Path $pluginDir "Tolk.dll"
if (Test-Path $tolkDll) {
    Write-Ok "Tolk.dll is already installed"
} else {
    Write-Host "   Downloading Tolk..." -ForegroundColor White
    $tolkZip = Join-Path $env:TEMP "tolk_fm26.zip"
    try {
        Invoke-WebRequest -Uri $TolkUrl -OutFile $tolkZip -UseBasicParsing
        # Extract and find x64 Tolk.dll
        $tolkExtract = Join-Path $env:TEMP "tolk_extract"
        if (Test-Path $tolkExtract) { Remove-Item $tolkExtract -Recurse -Force }
        Expand-Archive -Path $tolkZip -DestinationPath $tolkExtract -Force

        # Search for x64 Tolk.dll
        $tolkSrc = Get-ChildItem "$tolkExtract" -Recurse -Filter "Tolk.dll" |
            Where-Object { $_.DirectoryName -match "x64|64" } |
            Select-Object -First 1

        if (-not $tolkSrc) {
            # Fallback: just grab any Tolk.dll
            $tolkSrc = Get-ChildItem "$tolkExtract" -Recurse -Filter "Tolk.dll" | Select-Object -First 1
        }

        if ($tolkSrc) {
            Copy-Item $tolkSrc.FullName -Destination $tolkDll -Force
            Write-Ok "Tolk installed"
        } else {
            Write-Warn "Could not find Tolk.dll in the archive."
        }

        Remove-Item $tolkZip -ErrorAction SilentlyContinue
        Remove-Item $tolkExtract -Recurse -ErrorAction SilentlyContinue
    } catch {
        Write-Warn "Could not download Tolk automatically."
        Write-Host "   Please download Tolk.dll (x64) from: https://github.com/dkager/tolk/releases" -ForegroundColor Yellow
        Write-Host "   Place it in: $pluginDir" -ForegroundColor Yellow
    }
}

# ============================================================
# Step 5: Install TouchlineMod.dll
# ============================================================
Write-Step "Installing Touchline accessibility mod..."

$modDll = Join-Path $pluginDir "TouchlineMod.dll"

# Try to download latest release from GitHub
$downloadedMod = $false
try {
    Write-Host "   Checking for latest release..." -ForegroundColor White
    $releaseInfo = Invoke-RestMethod -Uri $TouchlineReleasesApi -UseBasicParsing -ErrorAction Stop
    $asset = $releaseInfo.assets | Where-Object { $_.name -eq "TouchlineMod.dll" } | Select-Object -First 1
    if ($asset) {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $modDll -UseBasicParsing
        Write-Ok "Downloaded TouchlineMod.dll (v$($releaseInfo.tag_name))"
        $downloadedMod = $true
    }
} catch {
    # Release not available — check for local build
}

if (-not $downloadedMod) {
    # Check if there's a locally-built DLL
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $localBuild = Join-Path $scriptDir "src\TouchlineMod\bin\Release\net6.0\TouchlineMod.dll"
    $localBuildDebug = Join-Path $scriptDir "src\TouchlineMod\bin\Debug\net6.0\TouchlineMod.dll"

    if (Test-Path $localBuild) {
        Copy-Item $localBuild -Destination $modDll -Force
        Write-Ok "Installed TouchlineMod.dll from local Release build"
    } elseif (Test-Path $localBuildDebug) {
        Copy-Item $localBuildDebug -Destination $modDll -Force
        Write-Ok "Installed TouchlineMod.dll from local Debug build"
    } elseif (Test-Path $modDll) {
        Write-Ok "TouchlineMod.dll is already installed"
    } else {
        Write-Warn "Could not find TouchlineMod.dll."
        Write-Host "   Build from source: dotnet build TouchlineMod.sln -c Release" -ForegroundColor Yellow
        Write-Host "   Then re-run this installer, or copy TouchlineMod.dll to:" -ForegroundColor Yellow
        Write-Host "   $pluginDir" -ForegroundColor Yellow
    }
}

# ============================================================
# Step 6: Verify installation
# ============================================================
Write-Step "Verifying installation..."

$allGood = $true

if (Test-Path $bepInExCoreDll) {
    Write-Ok "BepInEx: Installed"
} else {
    Write-Err "BepInEx: NOT FOUND"
    $allGood = $false
}

if (Test-Path $tolkDll) {
    Write-Ok "Tolk: Installed"
} else {
    Write-Err "Tolk: NOT FOUND"
    $allGood = $false
}

if (Test-Path $modDll) {
    Write-Ok "TouchlineMod: Installed"
} else {
    Write-Err "TouchlineMod: NOT FOUND"
    $allGood = $false
}

# ============================================================
# Done!
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host "  Installation complete!" -ForegroundColor Green
    Write-Host "" 
    Write-Host "  To play Football Manager 2026 with accessibility:" -ForegroundColor White
    Write-Host "    1. Start NVDA (or JAWS) screen reader" -ForegroundColor White
    Write-Host "    2. Launch Football Manager 2026" -ForegroundColor White
    Write-Host '    3. You should hear "Touchline accessibility mod loaded"' -ForegroundColor White
    Write-Host ""
    Write-Host "  Keyboard shortcuts:" -ForegroundColor White
    Write-Host "    Arrow keys     - Navigate menus and UI" -ForegroundColor Gray
    Write-Host "    Enter/Space    - Activate selected item" -ForegroundColor Gray
    Write-Host "    Ctrl+Shift+W   - Where am I? (read current element)" -ForegroundColor Gray
    Write-Host "    Ctrl+Shift+M   - Read match score and commentary" -ForegroundColor Gray
    Write-Host "    Ctrl+Shift+R   - Read entire visible screen" -ForegroundColor Gray
    Write-Host "    Ctrl+Shift+H   - List all keyboard shortcuts" -ForegroundColor Gray
    Write-Host "    Escape         - Stop speech" -ForegroundColor Gray
} else {
    Write-Host "  Installation incomplete - see errors above." -ForegroundColor Yellow
    Write-Host "  Fix the issues and run this installer again." -ForegroundColor Yellow
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
