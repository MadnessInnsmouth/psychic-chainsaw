@echo off
:: Create all distribution packages for Touchline installer

echo ============================================================
echo  Touchline - Create Distribution Packages
echo ============================================================
echo.
echo This will create three installer packages:
echo   1. Online installer (scripts only, ~100 KB)
echo   2. Complete installer (scripts + DLLs, ~5-10 MB)
echo   3. Full installer (all + BepInEx if available, ~50 MB)
echo.
pause

:: Run the PowerShell packaging script
powershell -ExecutionPolicy Bypass -File "%~dp0package-installer.ps1"

echo.
echo ============================================================
echo  All packages created successfully!
echo ============================================================
echo.
echo Check the current directory for:
echo   - Touchline-FM26-Installer.zip (Complete package)
echo.
echo To create the online-only package, see DISTRIBUTION.md
echo.
pause
