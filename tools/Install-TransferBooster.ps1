#Requires -Version 5.1
# Install-TransferBooster.ps1 — register Watch-Transfers.ps1 as a startup scheduled task.
#
# Run once (as Administrator):   .\Install-TransferBooster.ps1
# Remove:                        .\Remove-TransferBooster.ps1
#
# The task runs at user logon, hidden, under the current user account.
# It survives reboots and restarts if killed.

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TaskName       = 'Mavericks-TransferBooster',
    [double]$ThresholdMBps  = 10.0,
    [int]$PollSeconds       = 30,
    [int]$Threads           = 16
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# ── Resolve the watcher script path ──────────────────────────────────────────
$watcherScript = Join-Path $PSScriptRoot 'Watch-Transfers.ps1'
if (-not (Test-Path $watcherScript)) {
    Write-Error "Cannot find Watch-Transfers.ps1 at: $watcherScript"
    exit 1
}

# ── Elevation check ───────────────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning 'Not running as Administrator. Re-launching elevated...'
    $argStr = "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -TaskName `"$TaskName`" -ThresholdMBps $ThresholdMBps -PollSeconds $PollSeconds -Threads $Threads"
    Start-Process pwsh.exe -Verb RunAs -ArgumentList $argStr -Wait
    exit
}

# ── Build the scheduled task ──────────────────────────────────────────────────
$pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue)?.Source
if (-not $pwsh) { $pwsh = 'pwsh.exe' }   # rely on PATH if not found via Get-Command

$scriptArgs = "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass " +
              "-File `"$watcherScript`" " +
              "-PollSeconds $PollSeconds -ThresholdMBps $ThresholdMBps -Threads $Threads"

$action  = New-ScheduledTaskAction  -Execute $pwsh -Argument $scriptArgs
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Days 365) `
    -MultipleInstances   IgnoreNew `
    -RestartCount        3 `
    -RestartInterval     (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable

$principal = New-ScheduledTaskPrincipal `
    -UserId    ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive `
    -RunLevel  Highest

# ── Register (or update if exists) ───────────────────────────────────────────
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existing) {
    if ($PSCmdlet.ShouldProcess($TaskName, 'Update existing scheduled task')) {
        Set-ScheduledTask -TaskName $TaskName `
            -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
        Write-Host "Updated scheduled task '$TaskName'." -ForegroundColor Green
    }
} else {
    if ($PSCmdlet.ShouldProcess($TaskName, 'Register new scheduled task')) {
        Register-ScheduledTask `
            -TaskName   $TaskName `
            -Action     $action `
            -Trigger    $trigger `
            -Settings   $settings `
            -Principal  $principal `
            -Description 'Mavericks-RoboCopy background transfer booster — polls for large file transfers and assists with robocopy /MT:16.' | Out-Null
        Write-Host "Registered scheduled task '$TaskName'." -ForegroundColor Green
    }
}

# ── Start it immediately ──────────────────────────────────────────────────────
if ($PSCmdlet.ShouldProcess($TaskName, 'Start task now')) {
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Milliseconds 800
    $state = (Get-ScheduledTask -TaskName $TaskName).State
    Write-Host "Task state: $state" -ForegroundColor $(if ($state -eq 'Running') { 'Green' } else { 'Yellow' })
}

Write-Host ''
Write-Host 'Transfer Booster installed.' -ForegroundColor Cyan
Write-Host "  Polls every ${PollSeconds}s for writes >${ThresholdMBps} MB/s on any drive."
Write-Host "  Two consecutive detections → robocopy /MT:$Threads boost fires automatically."
Write-Host "  Log: $env:LOCALAPPDATA\Mavericks-RoboCopy\booster.log"
Write-Host "  To remove: .\Remove-TransferBooster.ps1"
