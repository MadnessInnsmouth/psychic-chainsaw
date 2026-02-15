# ============================================================
# Touchline - FM26 Accessibility Mod - One-Click Installer
# ============================================================
#
# This script automatically:
#   1. Finds your Football Manager 2026 installation
#   2. Installs BepInEx 6 (mod framework)
#   3. Installs Tolk (screen reader bridge)
#   4. Installs Touchline (the accessibility mod)
#   5. Launches FM26 once to generate required files
#
# Usage: Right-click install.ps1 -> "Run with PowerShell"
#   Or:  Double-click install.bat (which calls this script)
#
# Requirements: Windows 10/11, Football Manager 2026 (Steam, Epic, or Xbox Game Pass)
# ============================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Speed up Invoke-WebRequest

# --- Script Configuration ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Logging Configuration ---
$LogFile = Join-Path $ScriptDir "touchline-installer.log"

# Clear previous log file and start fresh
if (Test-Path $LogFile) {
    Remove-Item $LogFile -Force -ErrorAction SilentlyContinue
}

# Initialize log file with timestamp and system info
$logHeader = @"
============================================================
Touchline Installer Log
============================================================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
PowerShell Version: $($PSVersionTable.PSVersion)
OS: $([System.Environment]::OSVersion.VersionString)
User: $env:USERNAME
Computer: $env:COMPUTERNAME
Script Directory: $ScriptDir
============================================================

"@

Add-Content -Path $LogFile -Value $logHeader -ErrorAction SilentlyContinue

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
}

# --- Version Configuration ---
$BepInExVersion = "6.0.0-pre.2"
$BepInExUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$BepInExVersion/BepInEx-Unity.IL2CPP-win-x64-$BepInExVersion.zip"
$TouchlineReleasesApi = "https://api.github.com/repos/MadnessInnsmouth/psychic-chainsaw/releases/latest"
$TolkRawBase = "https://raw.githubusercontent.com/dkager/tolk/master/libs/x64"

# --- Colours and output ---
function Write-Step($msg) { 
    Write-Host "`n>> $msg" -ForegroundColor Cyan
    Write-Log $msg "STEP"
}
function Write-Ok($msg) { 
    Write-Host "   [OK] $msg" -ForegroundColor Green
    Write-Log $msg "OK"
}
function Write-Warn($msg) { 
    Write-Host "   [!] $msg" -ForegroundColor Yellow
    Write-Log $msg "WARN"
}
function Write-Err($msg) { 
    Write-Host "   [ERROR] $msg" -ForegroundColor Red
    Write-Log $msg "ERROR"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Touchline - FM26 Accessibility Mod Installer" -ForegroundColor White
Write-Host "  Making Football Manager 2026 accessible for everyone" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Log "=== INSTALLATION STARTED ===" "INFO"

try {

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

Write-Log "Searching for FM26 in common locations..." "INFO"

# Also try to read Steam library folders from libraryfolders.vdf
$steamConfigPath = "$env:ProgramFiles (x86)\Steam\steamapps\libraryfolders.vdf"
if (Test-Path $steamConfigPath) {
    Write-Log "Found Steam library config at: $steamConfigPath" "INFO"
    $vdfContent = Get-Content $steamConfigPath -Raw
    $pathMatches = [regex]::Matches($vdfContent, '"path"\s+"([^"]+)"')
    Write-Log "Found $($pathMatches.Count) Steam library paths in config" "INFO"
    foreach ($match in $pathMatches) {
        $libPath = $match.Groups[1].Value -replace '\\\\', '\'
        $steamPaths += "$libPath\steamapps\common\Football Manager 26"
        Write-Log "  Added Steam library path: $libPath" "INFO"
    }
} else {
    Write-Log "Steam library config not found at: $steamConfigPath" "INFO"
}

# Epic Games common locations
$steamPaths += @(
    "$env:ProgramFiles\Epic Games\FootballManager26",
    "$env:ProgramFiles (x86)\Epic Games\FootballManager26"
)

# Xbox Game Pass / Microsoft Store locations
$steamPaths += @(
    "$env:ProgramFiles\WindowsApps\SEGAEuropeLtd.FootballManager26*",
    "$env:LOCALAPPDATA\Packages\SEGAEuropeLtd.FootballManager26*\LocalCache\Local"
)

# Expand wildcards for Xbox Game Pass paths (folder names include version IDs)
$expandedPaths = @()
foreach ($path in $steamPaths) {
    if ($path -match '\*') {
        $resolved = Resolve-Path $path -ErrorAction SilentlyContinue
        if ($resolved) {
            $expandedPaths += $resolved.Path
        }
    } else {
        $expandedPaths += $path
    }
}
$steamPaths = $expandedPaths

foreach ($path in $steamPaths) {
    Write-Log "Checking path: $path" "INFO"
    if (Test-Path "$path\Football Manager 26.exe") {
        $FM26Path = $path
        Write-Log "Found FM26 at: $FM26Path" "INFO"
        break
    }
    # Also check for fm.exe variant
    if (Test-Path "$path\fm.exe") {
        $FM26Path = $path
        Write-Log "Found FM26 (fm.exe) at: $FM26Path" "INFO"
        break
    }
}

# If not found, ask the user
if (-not $FM26Path) {
    Write-Warn "Could not auto-detect Football Manager 2026."
    Write-Log "FM26 auto-detection failed. Prompting user for path." "WARN"
    Write-Host ""
    Write-Host "   Please enter the full path to your FM26 folder" -ForegroundColor White
    Write-Host '   Example: C:\Program Files (x86)\Steam\steamapps\common\Football Manager 26' -ForegroundColor Gray
    Write-Host ""
    $FM26Path = Read-Host "   FM26 path"
    $FM26Path = $FM26Path.Trim('"').Trim()
    Write-Log "User provided path: $FM26Path" "INFO"
    if (-not (Test-Path $FM26Path)) {
        Write-Err "Path not found: $FM26Path"
        Write-Log "User-provided path does not exist: $FM26Path" "ERROR"
        Write-Host "   Please check the path and try again."
        Read-Host "Press Enter to exit"
        exit 1
    }
    # Verify this is actually the FM26 folder by checking for game executable
    $testExe = @(Get-ChildItem "$FM26Path\*.exe" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Football Manager*" -or $_.Name -like "fm.exe" } | Select-Object -First 1)
    if ($testExe.Count -eq 0) {
        Write-Err "No Football Manager executable found in: $FM26Path"
        Write-Log "No FM executable found at user-provided path: $FM26Path" "ERROR"
        Write-Host "   Please check the path and try again."
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Log "Verified FM26 executable at user-provided path" "INFO"
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
    Write-Log "BepInEx already installed at: $bepInExCoreDll" "INFO"
} else {
    Write-Log "BepInEx not found. Starting installation..." "INFO"
    $bepInExInstalled = $false

    # Check for a bundled BepInEx zip in the installer directory
    $localBepZips = @(Get-ChildItem -Path (Join-Path $ScriptDir "BepInEx-Unity.IL2CPP-win-x64*.zip") -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if ($localBepZips.Count -gt 0) {
        $bepZip = $localBepZips[0].FullName
        Write-Host "   Found bundled BepInEx archive: $bepZip" -ForegroundColor White
        Write-Log "Found local BepInEx archive: $bepZip" "INFO"
        Expand-Archive -Path $bepZip -DestinationPath $FM26Path -Force
        Write-Ok "BepInEx installed from bundled archive"
        Write-Log "Extracted BepInEx to: $FM26Path" "INFO"
        $bepInExInstalled = $true
    }

    # Download from GitHub if no local archive was found
    if (-not $bepInExInstalled) {
        Write-Host "   Downloading BepInEx $BepInExVersion..." -ForegroundColor White
        Write-Log "Downloading BepInEx from: $BepInExUrl" "INFO"
        $bepZip = Join-Path $env:TEMP "bepinex_fm26.zip"
        try {
            Invoke-WebRequest -Uri $BepInExUrl -OutFile $bepZip -UseBasicParsing
            Write-Log "Downloaded BepInEx to: $bepZip" "INFO"
            Expand-Archive -Path $bepZip -DestinationPath $FM26Path -Force
            Write-Log "Extracted BepInEx to: $FM26Path" "INFO"
            Remove-Item $bepZip -ErrorAction SilentlyContinue
            Write-Ok "BepInEx $BepInExVersion installed"
            $bepInExInstalled = $true
        } catch {
            Write-Err "Failed to download BepInEx: $($_.Exception.Message)"
            Write-Log "Failed to download BepInEx: $($_.Exception.Message)" "ERROR"
            Write-Host "   Please download BepInEx manually from:" -ForegroundColor Yellow
            Write-Host "   https://github.com/BepInEx/BepInEx/releases" -ForegroundColor Yellow
            Write-Host "   Extract it into: $FM26Path" -ForegroundColor Yellow
            Write-Host "   Then re-run this installer." -ForegroundColor Yellow
        }
    }
}

# ============================================================
# Step 3: Generate interop assemblies (run game once if needed)
# ============================================================
Write-Step "Checking interop assemblies..."

$interopDir = Join-Path $FM26Path "BepInEx\interop"

if ((Test-Path $interopDir) -and (@(Get-ChildItem "$interopDir\*.dll" -ErrorAction SilentlyContinue)).Count -gt 0) {
    Write-Ok "Interop assemblies already generated"
} else {
    # Verify that the BepInEx doorstop (winhttp.dll) is in place — without it
    # BepInEx cannot bootstrap and interop generation will silently fail.
    $doorstopDll = Join-Path $FM26Path "winhttp.dll"
    if (-not (Test-Path $doorstopDll)) {
        Write-Warn "winhttp.dll (BepInEx doorstop) is missing from the game folder."
        Write-Host "   BepInEx cannot start without it. Please re-install BepInEx and try again." -ForegroundColor Yellow
    }

    Write-Host "   BepInEx needs to run once to generate interop assemblies." -ForegroundColor White
    Write-Host "   The game will launch, generate files, and may close on its own." -ForegroundColor White
    Write-Host "   NOTE: It is normal for the game to start and then shut down automatically" -ForegroundColor Yellow
    Write-Host "         on the first run. BepInEx must generate interop assemblies and the" -ForegroundColor Yellow
    Write-Host "         game will exit during this process. This is expected behaviour." -ForegroundColor Yellow
    Write-Host ""

    $gameExe = Get-ChildItem "$FM26Path\*.exe" | Where-Object { $_.Name -notlike "Unins*" -and $_.Name -notlike "crash*" } | Select-Object -First 1
    if ($gameExe) {
        Write-Log "Found game executable: $($gameExe.FullName)" "INFO"
        $maxAttempts = 2
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            if ($attempt -gt 1) {
                Write-Host ""
                Write-Host "   Retrying interop generation (attempt $attempt of $maxAttempts)..." -ForegroundColor Yellow
                Write-Log "Retrying interop generation (attempt $attempt of $maxAttempts)" "INFO"
            }

            Write-Host "   Press Enter to launch FM26..." -ForegroundColor Yellow
            Read-Host

            try {
                Write-Log "Launching game: $($gameExe.FullName)" "INFO"
                $gameProcess = Start-Process $gameExe.FullName -WorkingDirectory $FM26Path -PassThru -ErrorAction Stop
                Write-Host "   Game launched (PID: $($gameProcess.Id)). Waiting for interop generation..." -ForegroundColor Gray
                Write-Log "Game process started with PID: $($gameProcess.Id)" "INFO"
            } catch {
                Write-Err "Failed to start game: $($_.Exception.Message)"
                Write-Log "Failed to start game: $($_.Exception.Message)" "ERROR"
                Write-Host "   Error details: $($_.CategoryInfo.Category) - $($_.FullyQualifiedErrorId)" -ForegroundColor Gray
                Write-Log "Error category: $($_.CategoryInfo.Category)" "ERROR"
                Write-Log "Error ID: $($_.FullyQualifiedErrorId)" "ERROR"
                Write-Host "   This can happen if the game requires administrator privileges or if antivirus is blocking it." -ForegroundColor Yellow
                if ($attempt -lt $maxAttempts) {
                    Write-Host "   Will retry..." -ForegroundColor Yellow
                }
                continue
            }
            Write-Host "   This may take 30-60 seconds. The game will likely close on its own." -ForegroundColor Gray

            # Wait up to 2 minutes (120000ms) for the game process to exit
            $exited = $gameProcess.WaitForExit(120000)
            if (-not $exited) {
                Write-Host "   Game is still running. Please close it when ready." -ForegroundColor Yellow
                Write-Log "Game process still running after 2 minutes" "INFO"
                Read-Host "   Press Enter after you've closed the game"
            } else {
                Write-Host "   Game process has exited." -ForegroundColor Gray
                Write-Log "Game process exited with code: $($gameProcess.ExitCode)" "INFO"
                # BepInEx writes interop assemblies asynchronously after the game
                # process exits; allow enough time for disk I/O to complete.
                Start-Sleep -Seconds 5
            }

            # Check whether BepInEx actually ran by looking for its log file
            $bepLogFile = Join-Path $FM26Path "BepInEx\LogOutput.log"
            if (-not (Test-Path $bepLogFile)) {
                Write-Warn "BepInEx log file not found — BepInEx may not have loaded."
                Write-Log "BepInEx log file not found at: $bepLogFile" "WARN"
                Write-Host "   Ensure winhttp.dll is in the game folder alongside the game .exe." -ForegroundColor Yellow
            } else {
                Write-Log "BepInEx log file found at: $bepLogFile" "INFO"
            }

            # Verify interop assemblies were generated
            if ((Test-Path $interopDir) -and (@(Get-ChildItem "$interopDir\*.dll" -ErrorAction SilentlyContinue)).Count -gt 0) {
                $interopCount = @(Get-ChildItem "$interopDir\*.dll" -ErrorAction SilentlyContinue).Count
                Write-Ok "Interop assemblies generated successfully"
                Write-Log "Generated $interopCount interop assemblies in: $interopDir" "INFO"
                break
            } else {
                if ($attempt -lt $maxAttempts) {
                    Write-Warn "Interop assemblies not found after game run."
                    Write-Log "Interop assemblies not found in: $interopDir" "WARN"
                    Write-Host "   BepInEx may need one more launch to finish generating them." -ForegroundColor Yellow
                } else {
                    Write-Warn "Interop assemblies not found after $maxAttempts attempts."
                    Write-Log "Interop assemblies not found after $maxAttempts attempts" "WARN"
                    Write-Host "   This can happen if BepInEx didn't fully initialise." -ForegroundColor Yellow
                    Write-Host "   Try launching FM26 once more from Steam, let it close, then re-run this installer." -ForegroundColor Yellow
                    if (Test-Path $bepLogFile) {
                        Write-Host "   Check $bepLogFile for errors." -ForegroundColor Yellow
                    }
                }
            }
        }
    } else {
        Write-Warn "Could not find game executable. Please run FM26 once manually, then re-run this installer."
        Write-Log "No game executable found in: $FM26Path" "WARN"
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

# Auto-extract tolk-x64.zip if present but not yet extracted
$tolkZip = Join-Path $ScriptDir "tolk-x64.zip"
$tolkDir = Join-Path $ScriptDir "tolk-x64"
if ((Test-Path $tolkZip) -and -not (Test-Path $tolkDir)) {
    Write-Host "   Extracting bundled tolk-x64.zip..." -ForegroundColor White
    Write-Log "Extracting tolk-x64.zip to: $tolkDir" "INFO"
    try {
        Expand-Archive -Path $tolkZip -DestinationPath $tolkDir -Force
        Write-Ok "Extracted tolk-x64.zip"
    } catch {
        Write-Warn "Failed to extract tolk-x64.zip: $($_.Exception.Message)"
        Write-Log "Failed to extract tolk-x64.zip: $($_.Exception.Message)" "ERROR"
    }
}

$tolkDll = Join-Path $pluginDir "Tolk.dll"
if (Test-Path $tolkDll) {
    Write-Ok "Tolk.dll is already installed"
} else {
    $tolkInstalled = $false

    # Check for extracted tolk-x64 directory in the installer folder
    # (may come pre-extracted in release package, or auto-extracted from zip above)
    $localTolkDll = Join-Path $tolkDir "Tolk.dll"
    if ((Test-Path $tolkDir) -and (Test-Path $localTolkDll)) {
        Write-Host "   Installing Tolk from bundled files..." -ForegroundColor White
        $tolkDlls = Get-ChildItem "$tolkDir\*.dll" -ErrorAction SilentlyContinue
        foreach ($dll in $tolkDlls) {
            Copy-Item $dll.FullName -Destination (Join-Path $pluginDir $dll.Name) -Force
            Write-Log "Copied $($dll.Name) to plugin folder" "INFO"
        }
        Write-Ok "Tolk installed from bundled files ($($tolkDlls.Count) DLL(s) copied)"
        $tolkInstalled = $true
    }

    # Download companion DLLs from GitHub as a fallback
    if (-not $tolkInstalled) {
        Write-Host "   Tolk not found in installer directory. Downloading companion DLLs..." -ForegroundColor White
        Write-Log "Tolk not found locally. Attempting download..." "INFO"
        $companionFiles = @("nvdaControllerClient64.dll", "SAAPI64.dll")
        foreach ($fileName in $companionFiles) {
            try {
                $destPath = Join-Path $pluginDir $fileName
                Invoke-WebRequest -Uri "$TolkRawBase/$fileName" -OutFile $destPath -UseBasicParsing
                Write-Ok "Downloaded $fileName"
            } catch {
                Write-Warn "Could not download $fileName"
                Write-Log "Failed to download $fileName : $($_.Exception.Message)" "ERROR"
            }
        }
        Write-Warn "Tolk.dll itself cannot be downloaded automatically (no pre-built release available)."
        Write-Host "   Please download the complete installer from:" -ForegroundColor Yellow
        Write-Host "   https://github.com/MadnessInnsmouth/psychic-chainsaw/releases" -ForegroundColor Yellow
        Write-Host "   Or place Tolk.dll in: $pluginDir" -ForegroundColor Yellow
    }
}

# ============================================================
# Step 5: Install TouchlineMod.dll
# ============================================================
Write-Step "Installing Touchline accessibility mod..."

$modDll = Join-Path $pluginDir "TouchlineMod.dll"

if (Test-Path $modDll) {
    Write-Ok "TouchlineMod.dll is already installed"
} else {
    $modInstalled = $false

    # Check for TouchlineMod.dll bundled in the installer directory
    $localModDll = Join-Path $ScriptDir "TouchlineMod.dll"
    if (Test-Path $localModDll) {
        Copy-Item $localModDll -Destination $modDll -Force
        Write-Ok "Installed TouchlineMod.dll from installer directory"
        Write-Log "Copied TouchlineMod.dll from: $localModDll" "INFO"
        $modInstalled = $true
    }

    # Try downloading from GitHub releases as a fallback
    if (-not $modInstalled) {
        try {
            Write-Host "   Downloading TouchlineMod.dll from latest release..." -ForegroundColor White
            Write-Log "Downloading TouchlineMod.dll from: $TouchlineReleasesApi" "INFO"
            $releaseInfo = Invoke-RestMethod -Uri $TouchlineReleasesApi -UseBasicParsing -ErrorAction Stop
            $asset = $releaseInfo.assets | Where-Object { $_.name -eq "TouchlineMod.dll" } | Select-Object -First 1
            if ($asset) {
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $modDll -UseBasicParsing
                Write-Ok "Downloaded TouchlineMod.dll (v$($releaseInfo.tag_name))"
                Write-Log "Downloaded TouchlineMod.dll from release $($releaseInfo.tag_name)" "INFO"
                $modInstalled = $true
            } else {
                Write-Log "No TouchlineMod.dll asset found in latest release" "WARN"
            }
        } catch {
            Write-Log "Failed to download from GitHub: $($_.Exception.Message)" "ERROR"
        }
    }

    if (-not $modInstalled) {
        Write-Warn "Could not find TouchlineMod.dll."
        Write-Host "   Please download from: https://github.com/MadnessInnsmouth/psychic-chainsaw/releases" -ForegroundColor Yellow
        Write-Host "   Place TouchlineMod.dll in: $pluginDir" -ForegroundColor Yellow
        Write-Host "   Then re-run this installer." -ForegroundColor Yellow
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

$interopDir = Join-Path $FM26Path "BepInEx\interop"
if ((Test-Path $interopDir) -and (@(Get-ChildItem "$interopDir\*.dll" -ErrorAction SilentlyContinue)).Count -gt 0) {
    Write-Ok "Interop assemblies: Generated"
} else {
    Write-Warn "Interop assemblies: NOT FOUND"
    Write-Host "   Launch the game once to generate them — the game will exit automatically on the first run." -ForegroundColor Yellow
}

if (Test-Path $tolkDll) {
    Write-Ok "Tolk: Installed"
} else {
    Write-Err "Tolk: NOT FOUND"
    $allGood = $false
}

$nvdaDll = Join-Path $pluginDir "nvdaControllerClient64.dll"
if (Test-Path $nvdaDll) {
    Write-Ok "NVDA controller: Installed"
} else {
    Write-Warn "NVDA controller: NOT FOUND (NVDA support may not work)"
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
Write-Log "=== INSTALLATION COMPLETED ===" "INFO"

} catch {
    Write-Err "An unexpected error occurred during installation:"
    Write-Err $_.Exception.Message
    Write-Log "FATAL ERROR: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    Write-Host ""
    Write-Host "   Full error details have been logged to:" -ForegroundColor Yellow
    Write-Host "   $LogFile" -ForegroundColor White
    Write-Host ""
    Write-Host "   Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Check the log file for detailed error information" -ForegroundColor Gray
    Write-Host "   2. See INSTALL.md for troubleshooting guidance" -ForegroundColor Gray
    Write-Host "   3. Report issues at: https://github.com/MadnessInnsmouth/psychic-chainsaw/issues" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

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
    Write-Log "Installation completed with errors" "WARN"
}

Write-Host ""
Write-Host "  Log file: $LogFile" -ForegroundColor White
Write-Host "  Share this file when reporting issues." -ForegroundColor Gray

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
