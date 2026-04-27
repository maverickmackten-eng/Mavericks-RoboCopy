#Requires -Version 5.1
# Tail-CrashLog.ps1 — keep open in a second terminal while testing.
# Every crash entry appears here the moment it's written.

$log = "$env:LOCALAPPDATA\Mavericks-RoboCopy\crash.log"

if (-not (Test-Path $log)) {
    Write-Host "Crash log not found yet: $log" -ForegroundColor Yellow
    Write-Host "Waiting for it to be created (launch the app once)..." -ForegroundColor DarkGray
    while (-not (Test-Path $log)) { Start-Sleep -Milliseconds 500 }
    Write-Host "Found. Tailing..." -ForegroundColor Green
}

Write-Host "=== Tailing $log  (Ctrl+C to stop) ===" -ForegroundColor Cyan
Get-Content -Path $log -Wait
