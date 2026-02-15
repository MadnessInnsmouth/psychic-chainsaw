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
# Requirements: Windows 10/11, Football Manager 2026 (Steam, Epic, or Xbox Game Pass)
# ============================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Speed up Invoke-WebRequest

# --- Script Configuration ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Logging Configuration ---
$LogFile = Join-Path $ScriptDir "touchline-installer.log"

# Clear previous log file if it exists
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
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
}

# --- Note: Manual extraction required ---
# If you downloaded a Touchline-FM26-Installer.zip file, please extract it manually
# before running this installer. The installer expects files to be already extracted.

# --- Version Configuration ---
$BepInExVersion = "6.0.0-pre.2"
$BepInExUrl = "https://github.com/BepInEx/BepInEx/releases/download/v$BepInExVersion/BepInEx-Unity.IL2CPP-win-x64-$BepInExVersion.zip"
$TouchlineReleasesApi = "https://api.github.com/repos/MadnessInnsmouth/psychic-chainsaw/releases/latest"
# Tolk DLLs should be provided in an extracted tolk-x64 folder alongside the installer.
# Fallback: download companion DLLs individually from the dkager/tolk repository.
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

# --- DLL Search Functions ---
# Searches the local file system for required DLL files
# This allows the installer to work offline if DLLs are already present
function Find-DllOnSystem {
    param(
        [string]$DllName,
        [string[]]$AdditionalSearchPaths = @()
    )
    
    Write-Host "   Searching for $DllName in installer directory..." -ForegroundColor Gray
    
    # Only search within the installer's own directory and its subdirectories.
    # The distribution zip includes a subfolder (e.g. tolk-x64) with the required DLLs,
    # so a recursive search of the script directory is sufficient.
    if ($ScriptDir -and (Test-Path $ScriptDir)) {
        $found = Get-ChildItem -Path $ScriptDir -Filter $DllName -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            Write-Host "   Found $DllName at: $($found.FullName)" -ForegroundColor Gray
            return $found.FullName
        }
    }
    
    # Also check any additional paths explicitly provided by the caller
    foreach ($path in $AdditionalSearchPaths) {
        if ($path -and (Test-Path $path)) {
            $found = Get-ChildItem -Path $path -Filter $DllName -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                Write-Host "   Found $DllName at: $($found.FullName)" -ForegroundColor Gray
                return $found.FullName
            }
        }
    }
    
    return $null
}

function Find-BepInExInstallation {
    Write-Host "   Searching for existing BepInEx installation..." -ForegroundColor Gray
    
    # Search for BepInEx.Core.dll which is the main indicator
    $bepInExDll = Find-DllOnSystem -DllName "BepInEx.Core.dll"
    if ($bepInExDll) {
        $bepInExDir = Split-Path -Parent $bepInExDll
        # Go up to the BepInEx root (core folder is inside BepInEx)
        if ($bepInExDir -match "\\core$") {
            $bepInExRoot = Split-Path -Parent $bepInExDir
            Write-Host "   Found BepInEx installation at: $bepInExRoot" -ForegroundColor Gray
            return $bepInExRoot
        }
    }
    
    return $null
}

function Copy-BepInExFromLocal {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    Write-Host "   Copying BepInEx from local installation..." -ForegroundColor White
    
    if (-not (Test-Path $SourcePath)) {
        return $false
    }
    
    try {
        # Copy BepInEx folder structure
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force -ErrorAction Stop
        
        # Also copy winhttp.dll (doorstop) if present
        $sourceRoot = Split-Path -Parent $SourcePath
        $winhttpSource = Join-Path $sourceRoot "winhttp.dll"
        if (Test-Path $winhttpSource) {
            Copy-Item -Path $winhttpSource -Destination (Join-Path (Split-Path -Parent $DestinationPath) "winhttp.dll") -Force
        }
        
        return $true
    } catch {
        Write-Warn "Failed to copy BepInEx: $_"
        return $false
    }
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
    
    # --- Strategy 1: Search for existing BepInEx installation on the system ---
    $existingBepInEx = Find-BepInExInstallation
    if ($existingBepInEx -and (Test-Path "$existingBepInEx\core\BepInEx.Core.dll")) {
        Write-Host "   Found existing BepInEx installation, copying to FM26..." -ForegroundColor White
        $targetBepInEx = Join-Path $FM26Path "BepInEx"
        if (Copy-BepInExFromLocal -SourcePath $existingBepInEx -DestinationPath $targetBepInEx) {
            Write-Ok "BepInEx installed from local copy"
            $bepInExInstalled = $true
        }
    }
    
    # --- Strategy 2: Look for BepInEx zip file locally ---
    if (-not $bepInExInstalled) {
        $localZips = @(
            (Join-Path $ScriptDir "BepInEx-Unity.IL2CPP-win-x64*.zip"),
            "$env:USERPROFILE\Downloads\BepInEx-Unity.IL2CPP-win-x64*.zip"
        )
        
        foreach ($zipPattern in $localZips) {
            $foundZips = @(Get-ChildItem -Path $zipPattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
            if ($foundZips.Count -gt 0) {
                $bepZip = $foundZips[0].FullName
                Write-Host "   Found local BepInEx archive: $bepZip" -ForegroundColor White
                Write-Host "   Installing BepInEx..." -ForegroundColor White
                Expand-Archive -Path $bepZip -DestinationPath $FM26Path -Force
                Write-Ok "BepInEx installed from local archive"
                $bepInExInstalled = $true
                break
            }
        }
    }
    
    # --- Strategy 3: Download from GitHub ---
    if (-not $bepInExInstalled) {
        Write-Host "   Downloading BepInEx 6..." -ForegroundColor White
        Write-Log "Attempting to download BepInEx from: $BepInExUrl" "INFO"
        $bepZip = Join-Path $env:TEMP "bepinex_fm26.zip"
        try {
            Invoke-WebRequest -Uri $BepInExUrl -OutFile $bepZip -UseBasicParsing
            Write-Ok "Downloaded BepInEx"
            Write-Log "Successfully downloaded BepInEx to: $bepZip" "INFO"
            Expand-Archive -Path $bepZip -DestinationPath $FM26Path -Force
            Write-Log "Successfully extracted BepInEx to: $FM26Path" "INFO"
            Remove-Item $bepZip -ErrorAction SilentlyContinue
            Write-Ok "BepInEx installed"
            $bepInExInstalled = $true
        } catch {
            Write-Warn "Could not download BepInEx from primary URL."
            Write-Log "Failed to download BepInEx: $($_.Exception.Message)" "ERROR"
            Write-Host "   Trying alternate URL..." -ForegroundColor Gray
            try {
                # Fallback: query GitHub API for the latest BepInEx 6 pre-release asset
                Write-Host "   Querying GitHub API for latest BepInEx release..." -ForegroundColor Gray
                Write-Log "Querying GitHub API for BepInEx releases..." "INFO"
                $bepReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/BepInEx/BepInEx/releases" -UseBasicParsing -ErrorAction Stop
                $bepRelease = $bepReleases | Where-Object { $_.tag_name -match "^v6\." } | Select-Object -First 1
                if (-not $bepRelease) {
                    throw "No BepInEx 6.x release found on GitHub"
                }
                Write-Log "Found BepInEx release: $($bepRelease.tag_name)" "INFO"
                $bepAsset = $bepRelease.assets | Where-Object { $_.name -match "IL2CPP-win-x64" } | Select-Object -First 1
                if (-not $bepAsset) {
                    throw "No matching BepInEx IL2CPP win-x64 asset found"
                }
                Write-Log "Downloading BepInEx asset: $($bepAsset.name)" "INFO"
                Invoke-WebRequest -Uri $bepAsset.browser_download_url -OutFile $bepZip -UseBasicParsing
                Write-Ok "Downloaded BepInEx from GitHub API (v$($bepRelease.tag_name))"
                Write-Log "Successfully downloaded BepInEx from GitHub API" "INFO"
                Expand-Archive -Path $bepZip -DestinationPath $FM26Path -Force
                Write-Log "Successfully extracted BepInEx to: $FM26Path" "INFO"
                Remove-Item $bepZip -ErrorAction SilentlyContinue
                Write-Ok "BepInEx installed"
                $bepInExInstalled = $true
            } catch {
                Write-Err "Failed to download BepInEx."
                Write-Log "Failed to download BepInEx from GitHub API: $($_.Exception.Message)" "ERROR"
                Write-Host "   Please download it manually from:" -ForegroundColor Yellow
                Write-Host "   https://github.com/BepInEx/BepInEx/releases" -ForegroundColor Yellow
                Write-Host "   Extract it into: $FM26Path" -ForegroundColor Yellow
                Write-Host "   Or place the BepInEx zip in: $ScriptDir" -ForegroundColor Yellow
                Write-Host "   Then re-run this installer." -ForegroundColor Yellow
            }
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

$tolkDll = Join-Path $pluginDir "Tolk.dll"
if (Test-Path $tolkDll) {
    Write-Ok "Tolk.dll is already installed"
} else {
    $tolkInstalled = $false

    # --- Strategy 1: Search for Tolk DLLs bundled with the installer ---
    Write-Host "   Searching for Tolk DLLs in installer directory..." -ForegroundColor White
    $localTolkDll = Find-DllOnSystem -DllName "Tolk.dll"
    if ($localTolkDll) {
        $localTolkDir = Split-Path -Parent $localTolkDll
        Write-Host "   Found Tolk at: $localTolkDir" -ForegroundColor Gray
        
        # Copy all DLLs from the same directory (Tolk + companions)
        $tolkDlls = Get-ChildItem "$localTolkDir\*.dll" -ErrorAction SilentlyContinue
        $copiedCount = 0
        foreach ($dll in $tolkDlls) {
            try {
                Copy-Item $dll.FullName -Destination (Join-Path $pluginDir $dll.Name) -Force -ErrorAction Stop
                $copiedCount++
            } catch {
                Write-Host "   Warning: Failed to copy $($dll.Name): $_" -ForegroundColor Yellow
            }
        }
        
        if ($copiedCount -gt 0) {
            Write-Ok "Tolk installed from installer directory ($copiedCount DLL(s) copied)"
            $tolkInstalled = $true
        }
    }

    # --- Strategy 2: Check for local Tolk DLLs bundled with the installer ---
    # Users should manually extract tolk-x64 folder if they have the zip file
    if (-not $tolkInstalled) {
        # Check for extracted tolk-x64 directory (must be manually extracted by user)
        $localTolkDir = Join-Path $ScriptDir "tolk-x64"
        $localTolkDll = Join-Path $localTolkDir "Tolk.dll"

        if (Test-Path $localTolkDll) {
            Write-Host "   Installing Tolk from local bundle..." -ForegroundColor White
            $companionDlls = Get-ChildItem "$localTolkDir\*.dll" -ErrorAction SilentlyContinue
            foreach ($dll in $companionDlls) {
                Copy-Item $dll.FullName -Destination (Join-Path $pluginDir $dll.Name) -Force
            }
            Write-Ok "Tolk installed from local bundle (with screen reader libraries)"
            $tolkInstalled = $true
        }
    }

    # --- Strategy 3: Download individual companion DLLs from dkager/tolk repo ---
    if (-not $tolkInstalled) {
        Write-Host "   Downloading Tolk companion DLLs from GitHub..." -ForegroundColor White
        $companionFiles = @("nvdaControllerClient64.dll", "SAAPI64.dll")
        $downloadedAny = $false
        foreach ($fileName in $companionFiles) {
            try {
                $destPath = Join-Path $pluginDir $fileName
                Invoke-WebRequest -Uri "$TolkRawBase/$fileName" -OutFile $destPath -UseBasicParsing
                $downloadedAny = $true
            } catch {
                Write-Warn "Could not download $fileName"
            }
        }
        if ($downloadedAny) {
            Write-Ok "Downloaded screen reader companion DLLs"
        }
        Write-Warn "Tolk.dll could not be downloaded automatically."
        Write-Host "   The Tolk project (github.com/dkager/tolk) does not publish pre-built releases." -ForegroundColor Yellow
        Write-Host "   Please obtain Tolk.dll (x64) by building from source or from the Touchline release:" -ForegroundColor Yellow
        Write-Host "   https://github.com/MadnessInnsmouth/psychic-chainsaw/releases" -ForegroundColor Yellow
        Write-Host "   Place it in: $pluginDir" -ForegroundColor Yellow
    }
}

# Ensure NVDA/JAWS companion DLLs are present alongside Tolk.dll.
# These can be missed if Tolk was installed from a source that only contained Tolk.dll.
if (Test-Path $tolkDll) {
    $requiredCompanions = @("nvdaControllerClient64.dll", "SAAPI64.dll")
    foreach ($companion in $requiredCompanions) {
        $companionPath = Join-Path $pluginDir $companion
        if (-not (Test-Path $companionPath)) {
            # Try to find it in the installer directory
            $found = Find-DllOnSystem -DllName $companion
            if ($found) {
                Copy-Item $found -Destination $companionPath -Force
                Write-Ok "Copied missing $companion to plugin folder"
            } else {
                # Try downloading from dkager/tolk repository
                try {
                    Invoke-WebRequest -Uri "$TolkRawBase/$companion" -OutFile $companionPath -UseBasicParsing
                    Write-Ok "Downloaded missing $companion"
                } catch {
                    Write-Warn "$companion not found — screen reader support for this backend may not work."
                }
            }
        }
    }
}

# ============================================================
# Step 5: Install TouchlineMod.dll
# ============================================================
Write-Step "Installing Touchline accessibility mod..."

$modDll = Join-Path $pluginDir "TouchlineMod.dll"
$downloadedMod = $false

# --- Strategy 1: Search for TouchlineMod.dll in installer directory ---
if (-not (Test-Path $modDll)) {
    $localModDll = Find-DllOnSystem -DllName "TouchlineMod.dll"
    if ($localModDll) {
        Write-Host "   Found TouchlineMod.dll at: $localModDll" -ForegroundColor Gray
        Copy-Item $localModDll -Destination $modDll -Force
        Write-Ok "Installed TouchlineMod.dll from installer directory"
        $downloadedMod = $true
    }
}

# --- Strategy 2: Try to download latest release from GitHub ---
if (-not $downloadedMod -and -not (Test-Path $modDll)) {
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
        Write-Host "   Release not available, checking local builds..." -ForegroundColor Gray
    }
}

# --- Strategy 3: Check for locally-built DLL ---
if (-not $downloadedMod -and -not (Test-Path $modDll)) {
    $localBuild = Join-Path $ScriptDir "src\TouchlineMod\bin\Release\net6.0\TouchlineMod.dll"
    $localBuildDebug = Join-Path $ScriptDir "src\TouchlineMod\bin\Debug\net6.0\TouchlineMod.dll"

    if (Test-Path $localBuild) {
        Copy-Item $localBuild -Destination $modDll -Force
        Write-Ok "Installed TouchlineMod.dll from local Release build"
    } elseif (Test-Path $localBuildDebug) {
        Copy-Item $localBuildDebug -Destination $modDll -Force
        Write-Ok "Installed TouchlineMod.dll from local Debug build"
    } else {
        Write-Warn "Could not find TouchlineMod.dll."
        Write-Host "   Please try one of the following:" -ForegroundColor Yellow
        Write-Host "   1. Download from: https://github.com/MadnessInnsmouth/psychic-chainsaw/releases" -ForegroundColor Yellow
        Write-Host "   2. Build from source: dotnet build TouchlineMod.sln -c Release" -ForegroundColor Yellow
        Write-Host "   3. Place TouchlineMod.dll in: $pluginDir" -ForegroundColor Yellow
        Write-Host "   Then re-run this installer." -ForegroundColor Yellow
    }
} elseif (Test-Path $modDll) {
    Write-Ok "TouchlineMod.dll is installed"
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
    Write-Host "   nvdaControllerClient64.dll must be in: $pluginDir" -ForegroundColor Yellow
    Write-Host "   It should have been installed alongside Tolk.dll." -ForegroundColor Yellow
    # Attempt to locate and copy the missing DLL as a recovery step
    $nvdaFound = Find-DllOnSystem -DllName "nvdaControllerClient64.dll"
    if ($nvdaFound) {
        Copy-Item $nvdaFound -Destination (Join-Path $pluginDir "nvdaControllerClient64.dll") -Force
        Write-Ok "NVDA controller: Recovered from $nvdaFound"
    }
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

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Installation log saved to:" -ForegroundColor Cyan
Write-Host "  $LogFile" -ForegroundColor White
Write-Host ""
Write-Host "  If you encounter issues, please share the log file contents" -ForegroundColor Gray
Write-Host "  to help diagnose the problem." -ForegroundColor Gray
Write-Host ""
