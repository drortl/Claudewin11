# Sets up this environment for building the .NET WinForms apps in this
# workspace (PDF editor, UniversalThreadGenerator, Mask for video,
# PanTiltRS485Controller):
#   - .NET 8 SDK
#   - Microsoft Edge WebView2 Runtime (needed by the PDF editor's
#     HTML-to-PDF feature; preinstalled on current Windows 10/11 but
#     checked here in case it's missing)
#
# Target: Windows 11 with winget available (preinstalled on current
# Windows 11; also present on up-to-date Windows 10).
#
# Usage (run from an elevated PowerShell prompt):
#   .\setup.ps1
#
# Re-running is safe: each step is skipped if its target already exists.

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget was not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
}

# ---- .NET 8 SDK -----------------------------------------------------------
Write-Step "Checking .NET 8 SDK"
$dotnetSdks = @()
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    $dotnetSdks = dotnet --list-sdks 2>$null
}
if ($dotnetSdks | Where-Object { $_ -like "8.*" }) {
    Write-Host ".NET 8 SDK already installed:"
    $dotnetSdks | Where-Object { $_ -like "8.*" } | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Step "Installing .NET 8 SDK (winget)"
    winget install --id Microsoft.DotNet.SDK.8 --accept-source-agreements --accept-package-agreements
}

# ---- WebView2 Runtime ------------------------------------------------------
Write-Step "Checking Microsoft Edge WebView2 Runtime"
$webview2Key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
if (Test-Path $webview2Key) {
    $version = (Get-ItemProperty -Path $webview2Key -Name pv -ErrorAction SilentlyContinue).pv
    Write-Host "WebView2 Runtime already installed: $version"
} else {
    Write-Step "Installing Microsoft Edge WebView2 Runtime (winget)"
    winget install --id Microsoft.EdgeWebView2Runtime --accept-source-agreements --accept-package-agreements
}

Write-Step "Done"
Write-Host "Open a new PowerShell window so PATH changes from the installers take effect, then verify with:"
Write-Host "  dotnet --list-sdks"
