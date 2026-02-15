@echo off
:: Touchline FM26 Accessibility Mod - One-Click Installer
:: This script downloads and installs everything needed to make
:: Football Manager 2026 accessible via screen readers.
::
:: Just double-click this file to install.

echo ============================================================
echo  Touchline - FM26 Accessibility Mod Installer
echo  Making Football Manager 2026 accessible for everyone
echo ============================================================
echo.

:: Check for PowerShell and run the real installer
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: PowerShell is required but was not found.
    echo Please install PowerShell or run install.ps1 manually.
    pause
    exit /b 1
)

:: Run the PowerShell installer with bypass execution policy
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"

echo.
echo Press any key to close...
pause >nul
