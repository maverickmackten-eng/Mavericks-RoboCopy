#Requires -Version 5.1
# Remove-TransferBooster.ps1 — uninstall the Mavericks-TransferBooster scheduled task.
#
# Run as Administrator:   .\Remove-TransferBooster.ps1

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TaskName = 'Mavericks-TransferBooster'
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# ── Elevation check ───────────────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning 'Not running as Administrator. Re-launching elevated...'
    Start-Process pwsh.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -TaskName `"$TaskName`"" -Wait
    exit
}

# ── Stop the running task instance first ──────────────────────────────────────
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    if ($task.State -eq 'Running') {
        if ($PSCmdlet.ShouldProcess($TaskName, 'Stop running task instance')) {
            Stop-ScheduledTask -TaskName $TaskName
            Write-Host "Stopped running task '$TaskName'." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Task '$TaskName' not found — nothing to remove." -ForegroundColor Yellow
}

# ── Kill any orphaned Watch-Transfers.ps1 processes ──────────────────────────
$watchers = Get-CimInstance Win32_Process -Filter "Name = 'pwsh.exe' OR Name = 'powershell.exe'" |
    Where-Object { $_.CommandLine -like '*Watch-Transfers.ps1*' }

if ($watchers) {
    foreach ($w in $watchers) {
        if ($PSCmdlet.ShouldProcess("PID $($w.ProcessId)", 'Kill orphaned Watch-Transfers.ps1 process')) {
            Stop-Process -Id $w.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Host "Killed orphaned process PID $($w.ProcessId)." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host 'No orphaned Watch-Transfers.ps1 processes found.' -ForegroundColor Gray
}

# ── Kill any orphaned robocopy boost processes ────────────────────────────────
# Booster launches robocopy.exe -WindowStyle Hidden — kill those too so no ghost copies keep running.
$rcBoost = Get-Process robocopy -ErrorAction SilentlyContinue
if ($rcBoost) {
    if ($PSCmdlet.ShouldProcess("$($rcBoost.Count) robocopy process(es)", 'Kill boost robocopy processes')) {
        $rcBoost | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "Killed $($rcBoost.Count) robocopy process(es)." -ForegroundColor Yellow
    }
}

# ── Unregister the task ───────────────────────────────────────────────────────
if ($task) {
    if ($PSCmdlet.ShouldProcess($TaskName, 'Unregister scheduled task')) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed scheduled task '$TaskName'." -ForegroundColor Green
    }
}

Write-Host ''
Write-Host 'Transfer Booster removed.' -ForegroundColor Cyan
Write-Host "  Log history preserved at: $env:LOCALAPPDATA\Mavericks-RoboCopy\booster.log"
Write-Host "  To reinstall: .\Install-TransferBooster.ps1"
