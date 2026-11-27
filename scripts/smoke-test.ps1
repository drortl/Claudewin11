<#
  Windows smoke test for a desktop app (WinForms, WPF, or any .exe).
  Runs on a GitHub Actions windows-latest machine (a real Windows Server VM).

  Usage:
    .\scripts\smoke-test.ps1 -ExePath path\to\App.exe [-Seconds 15] [-AppArgs "..."]

  Checks that the app:
    1. starts and is still running after -Seconds,
    2. has a window that responds (not hung),
    3. left no crash in the Windows Application event log (.NET Runtime / Application Error),
    4. closes cleanly when asked.
  Saves smoke-screenshot.png and smoke-report.txt in the current folder.
#>
param(
    [Parameter(Mandatory = $true)][string]$ExePath,
    [int]$Seconds = 15,
    [string]$AppArgs = ""
)

$ErrorActionPreference = "Stop"
$failed = $false
$report = New-Object System.Collections.Generic.List[string]
function Fail($msg) { Write-Host "::error::$msg"; $script:failed = $true; $report.Add("FAIL: $msg") }
function Ok($msg)   { Write-Host "OK: $msg"; $report.Add("OK: $msg") }

$exe = (Resolve-Path $ExePath).Path
$name = [System.IO.Path]::GetFileNameWithoutExtension($exe)
$start = Get-Date
Write-Host "Starting $exe"

if ($AppArgs) { $p = Start-Process -FilePath $exe -ArgumentList $AppArgs -PassThru }
else          { $p = Start-Process -FilePath $exe -PassThru }

# Wait for the main window (up to 30 s)
$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline -and -not $p.HasExited) {
    $p.Refresh()
    if ($p.MainWindowHandle -ne 0) { break }
    Start-Sleep -Milliseconds 500
}
if ($p.HasExited) { Fail "app exited during startup (exit code $($p.ExitCode))" }
elseif ($p.MainWindowHandle -eq 0) { Fail "no window appeared within 30 s" }
else { Ok "window appeared: '$($p.MainWindowTitle)'" }

if (-not $p.HasExited) {
    Start-Sleep -Seconds $Seconds
    $p.Refresh()
    if ($p.HasExited) { Fail "app exited after start (exit code $($p.ExitCode))" }
    else {
        Ok "still running after $Seconds s ($([math]::Round($p.WorkingSet64 / 1MB)) MB RAM)"
        if ($p.Responding) { Ok "window is responding" } else { Fail "window is not responding (hung)" }
    }
}

# Screenshot of the whole screen
try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $bmp.Save((Join-Path (Get-Location) "smoke-screenshot.png"))
    $g.Dispose(); $bmp.Dispose()
    Ok "screenshot saved"
} catch { Write-Host "Screenshot skipped: $_" }

# Ask the app to close like a user would
if (-not $p.HasExited) {
    [void]$p.CloseMainWindow()
    if ($p.WaitForExit(10000)) { Ok "closed cleanly (exit code $($p.ExitCode))" }
    else { Fail "did not close within 10 s, killing it"; Stop-Process -Id $p.Id -Force }
}

# Crashes recorded by Windows
Start-Sleep -Seconds 2
$events = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Level = 2; StartTime = $start } -ErrorAction SilentlyContinue |
    Where-Object { ($_.ProviderName -in '.NET Runtime', 'Application Error', 'Windows Error Reporting') -and $_.Message -match [regex]::Escape($name) }
if ($events) {
    Fail "crash recorded in the Windows event log"
    $events | Select-Object -First 3 | ForEach-Object { Write-Host $_.Message; $report.Add($_.Message) }
} else { Ok "no crash in the Windows event log" }

$report | Set-Content -Path "smoke-report.txt"
if ($failed) { Write-Host "::error::Smoke test FAILED"; exit 1 }
Write-Host "Smoke test passed"
exit 0
