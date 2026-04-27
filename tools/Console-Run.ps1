#Requires -Version 5.1
# Console-Run.ps1 — run robocopy with the same logic as the GUI, but CLI-only.
# Use this to test the file-transfer layer without the WinForms GUI getting in the way.
#
# Examples:
#   .\Console-Run.ps1 -Source C:\Users\ACER\Desktop\testfolder-1 -Destination F:\testfolder-2
#   .\Console-Run.ps1 -Source C:\… -Destination F:\… -DryRun -Subdirs -Threads 8
#   .\Console-Run.ps1 -Source C:\… -Destination F:\… -Mode Mirror

param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Destination,
    [ValidateSet('Copy','Move','Mirror')][string]$Mode = 'Copy',
    [int]$Threads    = 16,
    [switch]$Subdirs,
    [switch]$VerboseLog,
    [switch]$Restartable,
    [switch]$DryRun,
    [string]$Excludes = '',
    [int]$Days = 0,
    [int]$IPG  = 0
)

function Build-Args {
    $a = @($Source.TrimEnd('\','/'), $Destination.TrimEnd('\','/'))
    if ($Subdirs)      { $a += '/E' }
    $a += "/MT:$Threads"
    $a += '/R:1', '/W:1', '/NP', '/TEE'
    if ($VerboseLog)   { $a += '/V' }
    if ($Restartable)  { $a += '/Z' }
    if ($Mode -eq 'Mirror') { $a += '/MIR' }
    elseif ($Mode -eq 'Move') { $a += '/MOV' }
    if ($DryRun)       { $a += '/L' }
    if ($Days -gt 0)   { $a += "/MAXAGE:$Days" }
    if ($IPG -gt 0)    { $a += "/IPG:$IPG" }
    foreach ($pat in ($Excludes -split ',|;')) {
        $p = $pat.Trim(); if (-not $p) { continue }
        if ($p.Contains('*') -or $p.Contains('?')) { $a += '/XF', $p } else { $a += '/XD', $p }
    }
    return , $a
}

if (-not (Test-Path $Source)) { Write-Error "Source not found: $Source"; exit 1 }

$rcArgs = Build-Args
Write-Host "robocopy $($rcArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

& robocopy.exe @rcArgs
$exit = $LASTEXITCODE

Write-Host ""
$verdict = switch ($exit) {
    0       { "Already in sync (nothing copied)." }
    1       { "Files copied successfully." }
    2       { "Done — extra files exist in destination." }
    3       { "Files copied + extras in destination." }
    { $_ -in 4,5,6,7 } { "Done with some mismatches/extras (exit $exit)." }
    default { "FAILED (exit $exit). Check output above." }
}
Write-Host "Exit $exit — $verdict" -ForegroundColor $(if ($exit -le 7) { 'Green' } else { 'Red' })
exit $exit
