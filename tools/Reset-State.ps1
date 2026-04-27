#Requires -Version 5.1
# Reset-State.ps1 — wipe all runtime state for a clean reproducible launch.
# Use before each test cycle so old errors don't pollute new runs.
#
#   .\Reset-State.ps1              — clears everything including settings.json
#   .\Reset-State.ps1 -KeepSettings — clears logs only, keeps last source/dest

param([switch]$KeepSettings)

$local   = "$env:LOCALAPPDATA\Mavericks-RoboCopy"
$roaming = "$env:APPDATA\Mavericks-RoboCopy"

Remove-Item "$local\crash.log"    -Force -ErrorAction SilentlyContinue
Remove-Item "$local\sessions.log" -Force -ErrorAction SilentlyContinue
Remove-Item "$local\logs\*"       -Force -ErrorAction SilentlyContinue
Write-Host "Cleared: crash.log, sessions.log, logs/" -ForegroundColor Green

if (-not $KeepSettings) {
    Remove-Item "$roaming\settings.json" -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared: settings.json" -ForegroundColor Green
} else {
    Write-Host "Kept:    settings.json (-KeepSettings)" -ForegroundColor Yellow
}

Write-Host "Done. Clean state ready for next launch." -ForegroundColor Cyan
