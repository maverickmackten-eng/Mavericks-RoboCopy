# =====================================================================
#  Mavericks-RoboCopy — PORT to Mav-AppTemplate framework
#  -----------------------------------------------------------------
#  Same functionality as the original ~1700-line app, written using
#  the Mav-AppTemplate framework. This file is the LOGIC of the app
#  — file picking, robocopy invocation, live stats — without any
#  layout pixel arithmetic.
#
#  All the layout/DPI/dock-order/picker headaches live in the module
#  (Mav-AppTemplate.psm1) and are solved once. This file just declares
#  the shape and wires the click handlers.
# =====================================================================

[CmdletBinding()]
param(
    [string]$Source = '',
    [string]$Destination = ''
)

# ── Session-start marker — written before ANYTHING else, including the trap.
# Proves the process launched even when it dies silently before the trap fires.
$_sessLog = "$env:LOCALAPPDATA\Mavericks-RoboCopy\sessions.log"
$null = New-Item -ItemType Directory -Force -Path (Split-Path $_sessLog) -ErrorAction SilentlyContinue
Add-Content -Path $_sessLog -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  PID=$PID  PSv=$($PSVersionTable.PSVersion)  exe=$($PSHOME)" -ErrorAction SilentlyContinue

# Need WinForms loaded BEFORE the trap so MessageBox is available
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

# ─────────────────────────────────────────────────────────────────────
#  Crash log — every uncaught exception writes here so we always have
#  a paper trail when the window mysteriously closes.
# ─────────────────────────────────────────────────────────────────────
$script:CrashLog = Join-Path $env:LOCALAPPDATA 'Mavericks-RoboCopy\crash.log'
$crashDir = Split-Path -Parent $script:CrashLog
if (-not (Test-Path $crashDir)) { New-Item -ItemType Directory -Path $crashDir -Force | Out-Null }

function Log-Crash {
    param([string]$Where, $Err)
    $when = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $msg  = "=== $when · $Where ===`n"
    if ($Err -is [System.Management.Automation.ErrorRecord]) {
        $msg += "$($Err.Exception.GetType().FullName): $($Err.Exception.Message)`n"
        $msg += "$($Err.ScriptStackTrace)`n"
    } else {
        $msg += "$Err`n"
    }
    try { Add-Content -Path $script:CrashLog -Value ($msg + "`n") -Encoding utf8 } catch {}
}

trap {
    Log-Crash 'top-level' $_
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "Mavericks-RoboCopy hit an error:`n`n$($_.Exception.Message)`n`nDetails written to:`n$script:CrashLog",
            'Mavericks-RoboCopy — error', 'OK', 'Error') | Out-Null
    } catch {}
    break   # was: continue — break stops cascading null-reference echoes of the first real error
}

# Locate framework — prefer the copy bundled next to this script (self-contained)
$frameworkRoot = $PSScriptRoot
$localPsd = Join-Path $frameworkRoot 'Mav-AppTemplate.psd1'
if (-not (Test-Path $localPsd)) {
    foreach ($candidate in @('F:\Mav-AppTemplate', (Join-Path (Split-Path -Parent $PSScriptRoot) 'Mav-AppTemplate'))) {
        if (Test-Path (Join-Path $candidate 'Mav-AppTemplate.psd1')) {
            $frameworkRoot = $candidate
            $localPsd = Join-Path $candidate 'Mav-AppTemplate.psd1'
            break
        }
    }
}
if (-not (Test-Path $localPsd)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Mav-AppTemplate.psd1 not found.`n`nLooked in:`n  $PSScriptRoot`n  F:\Mav-AppTemplate`n`nCopy Mav-AppTemplate.psd1 + .psm1 next to this script and try again.",
        'Missing dependency', 'OK', 'Error') | Out-Null
    return
}
Import-Module $localPsd -Force

# Pre-flight: verify every function the app will call is actually exported.
# Throws immediately with a clear message naming the missing function(s).
Test-MavFrameworkHealth -RequiredFunctions @(
    'Initialize-MavApp', 'New-MavForm',
    'Add-MavPathRow', 'Add-MavRadioGroup', 'Add-MavOptionsGroup',
    'Add-MavStatsRow', 'Add-MavTabbedLogPanel', 'Add-MavProgressRow',
    'Add-MavButtonBar', 'Set-MavStatus', 'Set-MavButtonReady',
    'Get-MavButtonReady', 'Show-MavApp', 'Add-MavRecent'
)

Initialize-MavApp -Theme Inferno

# ─────────────────────────────────────────────────────────────────────
#  Native: NtSuspend / NtResume for real Pause / Resume
# ─────────────────────────────────────────────────────────────────────
if (-not ('Mav.NtPower' -as [type])) {
    Add-Type -Namespace 'Mav' -Name 'NtPower' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("ntdll.dll")]
public static extern int NtSuspendProcess(System.IntPtr h);
[System.Runtime.InteropServices.DllImport("ntdll.dll")]
public static extern int NtResumeProcess(System.IntPtr h);
'@ -PassThru | Out-Null
}

# ─────────────────────────────────────────────────────────────────────
#  Settings persistence
# ─────────────────────────────────────────────────────────────────────
$SettingsDir  = Join-Path $env:APPDATA 'Mavericks-RoboCopy'
$SettingsPath = Join-Path $SettingsDir 'settings.json'
function Load-Settings {
    if (-not (Test-Path $SettingsPath)) { return @{ Presets = @{} } }
    try {
        $h = Get-Content $SettingsPath -Raw | ConvertFrom-Json -AsHashtable
        if (-not $h.Presets) { $h.Presets = @{} }
        return $h
    } catch { return @{ Presets = @{} } }
}
function Save-Settings([hashtable]$s) {
    if (-not (Test-Path $SettingsDir)) { New-Item -ItemType Directory -Path $SettingsDir | Out-Null }
    $s | ConvertTo-Json -Depth 6 | Set-Content -Path $SettingsPath -Encoding utf8
}
$Settings = Load-Settings

# ─────────────────────────────────────────────────────────────────────
#  Run state
# ─────────────────────────────────────────────────────────────────────
$State = [ordered]@{
    Process       = $null
    Started       = $null
    IsDryRun      = $false
    Cancelled     = $false
    Paused        = $false
    FilesSeen     = 0
    BytesSeen     = [int64]0
    TotalFiles    = 0          # populated by pre-scan
    TotalBytes    = [int64]0   # populated by pre-scan
    InitialEta    = $null      # TimeSpan, computed from pre-scan + threads
    LastTickAt    = $null
    LastTickBytes = [int64]0
    SpeedSamples  = New-Object System.Collections.ArrayList
    LastDest      = ''
    ExtCounts     = @{}          # extension → files successfully transferred
    ExtBytes      = @{}          # extension → bytes successfully transferred
    FoldersSeen   = 0            # new directories created in destination
    FailedFiles   = 0            # files that hit a copy error
    FailedBytes   = [int64]0
    ExtFailed     = @{}          # extension → failed file count
    SummaryTotal  = 0            # from robocopy's own "Files :" summary line (authoritative)
    SummaryCopied = 0
    SummaryFailed = 0
    SummarySkipped= 0
}

$script:RcShared          = $null
$script:RcPS              = $null
$script:RcRS              = $null
$script:RcCompletionFired = $false

function Format-Bytes([int64]$b) {
    if ($b -lt 1KB) { return "$b B" }
    if ($b -lt 1MB) { return ("{0:N1} KB" -f ($b / 1KB)) }
    if ($b -lt 1GB) { return ("{0:N1} MB" -f ($b / 1MB)) }
    if ($b -lt 1TB) { return ("{0:N2} GB" -f ($b / 1GB)) }
    return ("{0:N2} TB" -f ($b / 1TB))
}
function Format-Duration([TimeSpan]$ts) {
    if ($ts.TotalHours -ge 1) { return ("{0}:{1:D2}:{2:D2}" -f [int]$ts.TotalHours, $ts.Minutes, $ts.Seconds) }
    return ("{0}:{1:D2}" -f $ts.Minutes, $ts.Seconds)
}

# ═════════════════════════════════════════════════════════════════════
#  BUILD THE FORM — declarative, no pixel math
# ═════════════════════════════════════════════════════════════════════
$app = New-MavForm `
    -Title 'Mavericks-RoboCopy' `
    -Subtitle 'fast file transfer · pause·resume·throttle · cut+paste support' `
    -Version 'v5.0' `
    -Width 1280 -Height 1280

# ── Source / Destination
$srcInit = if ($Source) { $Source } elseif ($Settings.LastSource) { [string]$Settings.LastSource } else { '' }
$dstInit = if ($Destination) { $Destination } elseif ($Settings.LastDest) { [string]$Settings.LastDest } else { '' }
$src = Add-MavPathRow $app -Title 'SOURCE'      -Description 'pick the folder to copy/move FROM' -InitialText $srcInit
$dst = Add-MavPathRow $app -Title 'DESTINATION' -Description 'pick the folder to copy/move TO'   -InitialText $dstInit

# ── Mode (Copy / Move / Mirror with destructive confirms)
$mode = Add-MavRadioGroup $app -Title 'Mode' -Choices @(
    @{ Key='Copy';   Label='📄 COPY — originals stay';        ColorName='Text' }
    @{ Key='Move';   Label='✂  MOVE — cut+paste';             ColorName='Warn';
       Confirm='MOVE mode copies files then DELETES them from the source. Like cut-and-paste — no undo.`n`nProceed?' }
    @{ Key='Mirror'; Label='🗑 MIRROR — sync, deletes extras'; ColorName='Bad';
       Confirm='MIRROR makes the destination an EXACT copy of the source. Anything in dest NOT in source will be DELETED.`n`nProceed?' }
)

# ── Options
$opts = Add-MavOptionsGroup $app -Title 'Options' -Height 70 -Items @(
    @{ Type='Numeric';  Name='Threads';     LabelText='Threads (/MT):'; Default=$(if($Settings.Threads){[int]$Settings.Threads}else{16}); Min=1; Max=128 }
    @{ Type='CheckBox'; Name='Subdirs';     Label='Include subfolders (/E)';     Default=$(if($null -ne $Settings.IncludeSubdirs){[bool]$Settings.IncludeSubdirs}else{$true}) }
    @{ Type='CheckBox'; Name='Verbose';     Label='Verbose (/V)';                Default=$(if($null -ne $Settings.Verbose){[bool]$Settings.Verbose}else{$true}) }
    @{ Type='CheckBox'; Name='Restartable'; Label='Restartable (/Z)';            Default=$(if($null -ne $Settings.Restartable){[bool]$Settings.Restartable}else{$false}) }
)

# ── Excludes + filters
$filt = Add-MavOptionsGroup $app -Title 'Filters' -Height 70 -Items @(
    @{ Type='TextBox';  Name='Excludes'; LabelText='Excludes:'; Default=$(if($Settings.Excludes){[string]$Settings.Excludes}else{''}); Width=560 }
    @{ Type='Numeric';  Name='Days';     LabelText='Newer than (days):'; Default=0; Min=0; Max=36500; Width=60 }
    @{ Type='Numeric';  Name='IPG';      LabelText='Throttle (ms):'; Default=0; Min=0; Max=9999; Width=60 }
)

$post = Add-MavOptionsGroup $app -Title 'After' -Height 70 -Items @(
    @{ Type='CheckBox'; Name='Prescan';  Label='Pre-scan for accurate ETA'; Default=$(if($null -ne $Settings.Prescan){[bool]$Settings.Prescan}else{$false}) }
    @{ Type='CheckBox'; Name='OpenDest'; Label='Open destination when done'; Default=$(if($null -ne $Settings.OpenDestWhenDone){[bool]$Settings.OpenDestWhenDone}else{$false}) }
)

# ── Live stats — caption-above-value columns
$stats = Add-MavStatsRow $app -Captions @('FILES','TOTAL','COPIED','ELAPSED','SPEED','ETA') -Height 80

# ── Progress bar with current-file detail underneath
$prog = Add-MavProgressRow $app -Height 88

# ── Tabbed log: Full / Simplified / Warnings / Errors
$log = Add-MavTabbedLogPanel $app -Title '⚒ FORGE OUTPUT  ·  Full / Simplified / Warnings / Errors' -Height 320

# ── Bottom buttons
$btns = Add-MavButtonBar $app -Buttons @(
    @{ Key='Clear';     Text='🗑 Clear';        Side='Left' }
    @{ Key='Export';    Text='💾 Export Log';   Side='Left' }
    @{ Key='OpenLog';   Text='📁 Open Log Folder'; Side='Left' }
    @{ Key='OpenDest';  Text='📂 Open Destination'; Side='Left'; Disabled=$true }
    @{ Key='Cancel';    Text='✕ Cancel';        Side='Right'; ColorName='Bad'; Disabled=$true }
    @{ Key='Pause';     Text='⏸ Pause';         Side='Right'; ColorName='Warn'; Disabled=$true }
    @{ Key='DryRun';    Text='👁 Dry Run';       Side='Right' }
    @{ Key='Go';        Text='▶ COPY';          Side='Right'; Primary=$true }
)

# ─────────────────────────────────────────────────────────────────────
#  Backend log file — one .log per app launch in %LOCALAPPDATA%
# ─────────────────────────────────────────────────────────────────────
$script:LogDir = Join-Path $env:LOCALAPPDATA 'Mavericks-RoboCopy\logs'
if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null }
$script:CurrentLogFile = Join-Path $script:LogDir ("transfer-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
& $log.SetLogFile $script:CurrentLogFile
& $log.Append "Mavericks-RoboCopy started — log file: $script:CurrentLogFile" $app.Theme.TextDim @('Full')

# ─────────────────────────────────────────────────────────────────────
#  Robocopy execution + live updates
# ─────────────────────────────────────────────────────────────────────
function Color-For-Line([string]$line) {
    if ($line -match '^\s*\*EXTRA')                    { return $app.Theme.Ember }
    if ($line -match 'New File|^\s*Newer')             { return $app.Theme.Good }   # transferred → green
    if ($line -match 'Older|Mismatch|Skipped')         { return $app.Theme.Warn }   # not copied → orange
    if ($line -match 'Same')                           { return $app.Theme.TextDim }
    if ($line -match 'ERROR|FAILED|Access denied')     { return $app.Theme.Bad }
    return $app.Theme.Text
}

# Map a robocopy line → which log tabs it should appear in
function Channels-For-Line([string]$line) {
    $chan = @('Full')
    if ($line -match 'ERROR|FAILED|Access denied|Cannot access') {
        # Copy errors → Errors + Simplified
        $chan += 'Errors'; $chan += 'Simplified'
    } elseif ($line -match 'Older|Mismatch|Skipped|^\s*\*EXTRA') {
        # Files not copied or unexpected extras → Warnings only
        $chan += 'Warnings'
    } elseif ($line -match 'New File|^\s*Newer|━{5,}|═{5,}|Started :|Ended :|Source :|Dest :|Files\s*:|Bytes\s*:|Dirs\s*:|Speed\s*:|TRANSFER COMPLETE|DRY RUN COMPLETE|CANCELLED') {
        # Successful transfers and summary lines → Simplified (clean view)
        $chan += 'Simplified'
    }
    return $chan
}

# ETA: pre-run heuristic uses thread/size baseline; live ETA uses measured speed
#   throughput_mb_s ≈ baseline × thread_factor
#   thread_factor = 1 + 0.6·log10(threads)   (caps the diminishing return)
#   baseline default ≈ 50 MB/s (USB 3 / typical SATA SSD), gets refined by measured speed
function Estimate-Initial-Eta([int64]$totalBytes, [int]$threads, [double]$baselineMBps = 50.0) {
    if ($totalBytes -le 0 -or $threads -lt 1) { return $null }
    $tf = 1.0 + (0.6 * [Math]::Log10([Math]::Max(1, $threads)))
    $effectiveMBps = $baselineMBps * $tf
    $bps = $effectiveMBps * 1MB
    $secs = $totalBytes / $bps
    return [TimeSpan]::FromSeconds([Math]::Ceiling($secs))
}

function Parse-RcSize([string]$s) {
    if ($s -match '([\d,.]+)\s*([kKmMgG])?') {
        $num = [double]($Matches[1] -replace ',','')
        $mul = switch ($Matches[2]) {
            { $_ -in 'k','K' } { 1KB }
            { $_ -in 'm','M' } { 1MB }
            { $_ -in 'g','G' } { 1GB }
            default { 1 }
        }
        return [int64]($num * $mul)
    }
    return [int64]0
}

function Update-TransferStats([string]$line) {
    # ── Successfully transferred file: "New File" (new) or "Newer" (overwrite)
    # "Older" is intentionally excluded — in Copy mode, Older = source is stale, file is SKIPPED.
    # With /BYTES the size is always plain digits; without /BYTES it may be "1.1 m" etc.
    if ($line -match '^\s*(?:New File|Newer)\s+([\d,.]+\s*[kKmMgG]?)\s+(.+)$') {
        $bytes = Parse-RcSize $Matches[1].Trim()
        $path  = $Matches[2].Trim()
        $ext   = [System.IO.Path]::GetExtension($path).ToLower()
        if (-not $ext) { $ext = '(no ext)' }
        $State.FilesSeen++
        $State.BytesSeen += $bytes
        if (-not $State.ExtCounts.ContainsKey($ext)) {
            $State.ExtCounts[$ext] = 0
            $State.ExtBytes[$ext]  = [int64]0
        }
        $State.ExtCounts[$ext]++
        $State.ExtBytes[$ext] += $bytes
    }

    # ── Failed copy: robocopy error line that names the file being copied
    elseif ($line -match 'ERROR \d+.*(?:Copying File|Creating File|Moving File)\s+(.+)$') {
        $path  = $Matches[1].Trim()
        $ext   = [System.IO.Path]::GetExtension($path).ToLower()
        if (-not $ext) { $ext = '(no ext)' }
        $State.FailedFiles++
        if (-not $State.ExtFailed.ContainsKey($ext)) { $State.ExtFailed[$ext] = 0 }
        $State.ExtFailed[$ext]++
    }

    # ── New directory created in destination (only "New Dir", not "*EXTRA Dir")
    elseif ($line -match '^\s*New Dir\s') { $State.FoldersSeen++ }

    # ── Robocopy summary table — authoritative count of what actually happened
    # Format: "   Files :   Total   Copied   Skipped  Mismatch   FAILED   Extras"
    elseif ($line -match '^\s*Files\s*:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)') {
        $State.SummaryTotal    = [int]$Matches[1]
        $State.SummaryCopied   = [int]$Matches[2]
        $State.SummarySkipped  = [int]$Matches[3]
        # Matches[4] = Mismatch
        $State.SummaryFailed   = [int]$Matches[5]
    }
}

function Handle-RcCompletion {
    $statsTimer.Stop()

    $exit = -1
    try {
        if ($State.Process)       { $exit = $State.Process.ExitCode }
        elseif ($script:RcShared) { $exit = $script:RcShared.ExitCode }
    } catch {}

    $dur = (Get-Date) - $State.Started

    # Prefer the authoritative summary-table counts parsed from robocopy output.
    # Fall back to our live-counted values if the summary line was never received.
    $copiedCount = if ($State.SummaryCopied -gt 0) { $State.SummaryCopied } else { $State.FilesSeen }
    $failedCount = if ($State.SummaryCopied -gt 0) { $State.SummaryFailed } else { $State.FailedFiles }

    $verdict = switch ($exit) {
        0 { @('Already in sync — nothing to copy.', $app.Theme.Warn, $false) }
        1 { @('Files copied successfully.', $app.Theme.Good, $true) }
        2 { @('Done — extra files exist in destination.', $app.Theme.Warn, $true) }
        3 { @('Files copied + extras in destination.', $app.Theme.Good, $true) }
        { $_ -in 4,5,6,7 } { @("Done with some mismatches/extras (exit $exit).", $app.Theme.Warn, $true) }
        default { @("FAILED (exit $exit).", $app.Theme.Bad, $false) }
    }
    $tag = if ($State.Cancelled) {'CANCELLED'} elseif ($State.IsDryRun) {'DRY RUN COMPLETE'} else {'TRANSFER COMPLETE'}

    # ── Header ────────────────────────────────────────────────────────────
    & $log.Append '' $app.Theme.Text @('Full','Simplified')
    & $log.Append ('═' * 90) $app.Theme.AccentDim @('Full','Simplified')
    & $log.Append ("  $tag  ·  $(Format-Duration $dur)  ·  exit $exit") $verdict[1] @('Full','Simplified')
    & $log.Append ("  $($verdict[0])") $verdict[1] @('Full','Simplified')

    # ── Totals row ────────────────────────────────────────────────────────
    & $log.Append '' $app.Theme.Text @('Full','Simplified')
    $copiedLine = "  COPIED    $copiedCount file(s)   $(Format-Bytes $State.BytesSeen)"
    if ($State.TotalBytes -gt 0) { $copiedLine += "  of $(Format-Bytes $State.TotalBytes) total" }
    & $log.Append $copiedLine $app.Theme.Good @('Full','Simplified')

    if ($failedCount -gt 0) {
        & $log.Append ("  FAILED    $failedCount file(s)") $app.Theme.Bad @('Full','Simplified','Errors')
    }
    if ($State.SummarySkipped -gt 0) {
        & $log.Append ("  SKIPPED   $($State.SummarySkipped) file(s)  (already up-to-date or excluded)") $app.Theme.Warn @('Full','Simplified')
    }
    if ($State.FoldersSeen -gt 0) {
        & $log.Append ("  DIRS      $($State.FoldersSeen) new folder(s) created") $app.Theme.TextDim @('Full','Simplified')
    }

    # ── File-type breakdown (top 15 by file count) ────────────────────────
    if ($State.ExtCounts.Count -gt 0) {
        & $log.Append '' $app.Theme.Text @('Full','Simplified')
        & $log.Append ('─' * 52) $app.Theme.AccentDim @('Full','Simplified')
        & $log.Append ("  {'EXT',-12}  {'FILES',6}   {'DATA MOVED',12}") $app.Theme.AccentDim @('Full','Simplified')
        & $log.Append ('─' * 52) $app.Theme.AccentDim @('Full','Simplified')

        $State.ExtCounts.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 15 |
            ForEach-Object {
                $ext   = $_.Key.TrimStart('.').ToUpper()
                $cnt   = $_.Value
                $bytes = Format-Bytes $State.ExtBytes[$_.Key]
                $failed = if ($State.ExtFailed.ContainsKey($_.Key)) { "  ($($State.ExtFailed[$_.Key]) failed)" } else { '' }
                & $log.Append ("  {0,-12}  {1,6}   {2,12}{3}" -f $ext, $cnt, $bytes, $failed) `
                    $app.Theme.TextDim @('Full','Simplified')
            }

        # Show file types that ONLY failed (not in ExtCounts)
        $State.ExtFailed.GetEnumerator() | Where-Object { -not $State.ExtCounts.ContainsKey($_.Key) } |
            Sort-Object Value -Descending |
            ForEach-Object {
                $ext = $_.Key.TrimStart('.').ToUpper()
                & $log.Append ("  {0,-12}  {1,6}   {'— all failed',12}" -f $ext, $_.Value) `
                    $app.Theme.Bad @('Full','Simplified')
            }

        $remaining = $State.ExtCounts.Count - 15
        if ($remaining -gt 0) {
            & $log.Append ("  … and $remaining more type(s) — see Full tab") $app.Theme.TextDim @('Simplified')
        }
        & $log.Append ('─' * 52) $app.Theme.AccentDim @('Full','Simplified')
    }

    & $log.Append ("  Log: $script:CurrentLogFile") $app.Theme.TextDim @('Full')
    & $log.Append ('═' * 90) $app.Theme.AccentDim @('Full','Simplified')

    # ── Status bar + progress ─────────────────────────────────────────────
    $statusText = "$tag  ·  $copiedCount copied"
    if ($failedCount -gt 0) { $statusText += "  ·  $failedCount FAILED" }
    Set-MavStatus -App $app -Text $statusText -Color $verdict[1]
    try { $prog.Bar.Value = if ($exit -ge 0 -and $exit -le 7) { 100 } else { $prog.Bar.Value } } catch {}
    try { $prog.Detail.Text = "$tag — $copiedCount file(s), $(Format-Bytes $State.BytesSeen)$(if($failedCount -gt 0){" · $failedCount FAILED"})" } catch {}

    if ($verdict[2] -and -not $State.Cancelled) {
        try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
        if ($post.Controls.OpenDest.Checked -and (Test-Path $dst.TextBox.Text)) {
            Start-Process explorer.exe -ArgumentList $dst.TextBox.Text
        }
    }

    try { Add-MavRecent -Bucket 'SOURCE'      -Path $src.TextBox.Text } catch {}
    try { Add-MavRecent -Bucket 'DESTINATION' -Path $dst.TextBox.Text } catch {}

    Set-MavButtonReady $btns.Go $true
    Set-MavButtonReady $btns.DryRun $true
    Set-MavButtonReady $btns.Pause $false
    $btns.Pause.Text = '⏸ Pause'
    Set-MavButtonReady $btns.Cancel $false
    Set-MavButtonReady $btns.OpenDest (Test-Path $dst.TextBox.Text)
    $app.Form.Cursor = 'Default'
    $State.Process  = $null
    $State.LastDest = $dst.TextBox.Text

    $Settings.LastSource       = $src.TextBox.Text
    $Settings.LastDest         = $dst.TextBox.Text
    $Settings.Threads          = [int]$opts.Controls.Threads.Value
    $Settings.IncludeSubdirs   = [bool]$opts.Controls.Subdirs.Checked
    $Settings.Verbose          = [bool]$opts.Controls.Verbose.Checked
    $Settings.Restartable      = [bool]$opts.Controls.Restartable.Checked
    $Settings.Excludes         = $filt.Controls.Excludes.Text
    $Settings.Prescan          = [bool]$post.Controls.Prescan.Checked
    $Settings.OpenDestWhenDone = [bool]$post.Controls.OpenDest.Checked
    Save-Settings $Settings

    try { if ($script:RcPS) { $script:RcPS.Stop(); $script:RcPS.Dispose() }; $script:RcPS = $null } catch {}
    try { if ($script:RcRS) { $script:RcRS.Close(); $script:RcRS.Dispose() }; $script:RcRS = $null } catch {}
}

function Build-RobocopyArgs([bool]$dryRun) {
    $s = $src.TextBox.Text.Trim().TrimEnd('\','/')
    $d = $dst.TextBox.Text.Trim().TrimEnd('\','/')
    $a = @($s, $d)
    if ($opts.Controls.Subdirs.Checked) { $a += '/E' }
    $a += "/MT:$([int]$opts.Controls.Threads.Value)"
    $a += '/R:1','/W:1','/NP','/TEE','/BYTES'
    if ($opts.Controls.Verbose.Checked)     { $a += '/V' }
    if ($opts.Controls.Restartable.Checked) { $a += '/Z' }
    if ($mode.Radios.Mirror.Checked) { $a += '/MIR' }
    elseif ($mode.Radios.Move.Checked) { $a += '/MOV' }
    if ($dryRun) { $a += '/L' }
    if ([int]$filt.Controls.Days.Value -gt 0) { $a += "/MAXAGE:$([int]$filt.Controls.Days.Value)" }
    if ([int]$filt.Controls.IPG.Value -gt 0)  { $a += "/IPG:$([int]$filt.Controls.IPG.Value)" }
    foreach ($pat in ($filt.Controls.Excludes.Text -split ',|;')) {
        $p = $pat.Trim(); if (-not $p) { continue }
        if ($p.Contains('*') -or $p.Contains('?')) { $a += '/XF', $p } else { $a += '/XD', $p }
    }
    return ,$a
}

function Validate {
    $s = $src.TextBox.Text.Trim(); $d = $dst.TextBox.Text.Trim()
    if (-not $s) { return 'Source is empty.' }
    if (-not $d) { return 'Destination is empty.' }
    if (-not (Test-Path $s)) { return "Source doesn't exist: $s" }
    if ($s -eq $d) { return 'Source and destination are the same folder.' }
    return $null
}

# Pre-scan: count source files + total bytes via `robocopy /L /NFL /NJH`
# so we have an accurate denominator for progress + initial ETA.
function PreScan-Source([string]$src) {
    $totalFiles = 0; $totalBytes = [int64]0
    try {
        $output = & robocopy.exe $src 'NUL' /L /E /NFL /NJH /R:0 /W:0 /BYTES 2>$null
        # The summary contains: "   Files :     5     5     0 ..." and "   Bytes :    60 ..."
        foreach ($line in $output) {
            if ($line -match '^\s*Files\s*:\s*(\d+)\s+') { $totalFiles = [int]$Matches[1] }
            elseif ($line -match '^\s*Bytes\s*:\s*(\d+)\s+') { $totalBytes = [int64]$Matches[1] }
        }
    } catch {}
    return @{ Files = $totalFiles; Bytes = $totalBytes }
}

# Stats + output drain timer — fires every 300ms on the UI thread
$statsTimer = New-Object System.Windows.Forms.Timer
$statsTimer.Interval = 300
$statsTimer.Add_Tick({
    # ── Drain the output queue (filled by background runspace) ──────────
    if ($script:RcShared) {
        $line = [string]::Empty
        while ($script:RcShared.Queue.TryDequeue([ref]$line)) {
            if ($line.Length -lt 3) { continue }           # safety: must have prefix + data
            $isErr = $line.StartsWith('E:')
            $data  = $line.Substring(2)
            if (-not $data) { continue }
            $color = if ($isErr) { $app.Theme.Bad } else { Color-For-Line $data }
            $chan  = if ($isErr) { @('Full','Errors') } else { Channels-For-Line $data }
            & $log.Append $data $color $chan
            Update-TransferStats $data    # runs for both stdout and stderr (error lines update FailedFiles)
        }

        # ── Completion: process exited + queue empty + not yet handled ───
        if ($script:RcShared.Done -and $script:RcShared.Queue.IsEmpty -and -not $script:RcCompletionFired) {
            $script:RcCompletionFired = $true
            try { Handle-RcCompletion } catch { Log-Crash 'Handle-RcCompletion' $_ }
            return
        }
    }

    # ── Live stats row (only meaningful while process is still running) ──
    if (-not $State.Process -or $State.Process.HasExited) { return }
    $now     = Get-Date
    $elapsed = $now - $State.Started
    $stats.Values.ELAPSED.Text = (Format-Duration $elapsed)
    $stats.Values.FILES.Text   = "$($State.FilesSeen)"
    $stats.Values.COPIED.Text  = (Format-Bytes $State.BytesSeen)

    # Rolling speed (last 6 samples)
    $speedBps = 0
    if ($State.LastTickAt) {
        $dt = ($now - $State.LastTickAt).TotalSeconds
        if ($dt -gt 0) {
            $delta = $State.BytesSeen - $State.LastTickBytes
            [void]$State.SpeedSamples.Add($delta / $dt)
            while ($State.SpeedSamples.Count -gt 6) { $State.SpeedSamples.RemoveAt(0) }
            $speedBps = ($State.SpeedSamples | Measure-Object -Average).Average
        }
    }
    if ($State.Paused) {
        $stats.Values.SPEED.Text = 'PAUSED'
    } elseif ($speedBps -gt 0) {
        $stats.Values.SPEED.Text = (Format-Bytes ([int64]$speedBps)) + '/s'
    }

    # Progress + ETA — only if pre-scan ran
    if ($State.TotalBytes -gt 0) {
        $stats.Values.TOTAL.Text = (Format-Bytes $State.TotalBytes)
        $pct = [Math]::Min(100, [int](($State.BytesSeen / $State.TotalBytes) * 100))
        try { $prog.Bar.Value = $pct } catch {}
        $remaining = $State.TotalBytes - $State.BytesSeen
        if ($speedBps -gt 0 -and $remaining -gt 0) {
            $eta = [TimeSpan]::FromSeconds([Math]::Ceiling($remaining / $speedBps))
            $stats.Values.ETA.Text = (Format-Duration $eta)
        } elseif ($State.InitialEta) {
            $stats.Values.ETA.Text = (Format-Duration $State.InitialEta) + ' (est.)'
        }
        $prog.Detail.Text = "$($State.FilesSeen)/$($State.TotalFiles) files  ·  $pct% complete  ·  $(Format-Bytes $State.BytesSeen)/$(Format-Bytes $State.TotalBytes)"
    } elseif ($State.InitialEta) {
        $stats.Values.ETA.Text = (Format-Duration $State.InitialEta) + ' (est.)'
    }

    $State.LastTickAt    = $now
    $State.LastTickBytes = $State.BytesSeen
}.GetNewClosure())

function Run-Robocopy([bool]$dryRun) {
    $err = Validate
    if ($err) {
        [System.Windows.Forms.MessageBox]::Show($app.Form, $err, 'Cannot start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    $rcArgs = Build-RobocopyArgs $dryRun

    # Start a fresh per-run log file in %LOCALAPPDATA%\Mavericks-RoboCopy\logs
    $script:CurrentLogFile = Join-Path $script:LogDir ("transfer-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
    & $log.SetLogFile $script:CurrentLogFile
    & $log.Clear

    # Pre-scan: walk the source via robocopy /L to get accurate file count + total bytes
    $threads = [int]$opts.Controls.Threads.Value
    $State.TotalFiles = 0; $State.TotalBytes = [int64]0; $State.InitialEta = $null
    $stats.Values.TOTAL.Text = '—'
    & $log.Append ('━' * 90) $app.Theme.AccentDim @('Full','Simplified')
    & $log.Append ("Pre-scanning $($src.TextBox.Text) for size + file count…") $app.Theme.Lava @('Full','Simplified')
    Set-MavStatus -App $app -Text 'Pre-scanning source…' -Color $app.Theme.Lava
    $app.Form.Refresh()
    try {
        $scan = PreScan-Source $src.TextBox.Text
        $State.TotalFiles = [int]$scan.Files
        $State.TotalBytes = [int64]$scan.Bytes
        $State.InitialEta = Estimate-Initial-Eta $State.TotalBytes $threads
        & $log.Append ("Pre-scan: $($State.TotalFiles) files · $(Format-Bytes $State.TotalBytes) total") $app.Theme.Good @('Full','Simplified')
        if ($State.InitialEta) {
            & $log.Append ("Initial ETA estimate (with /MT:$threads, baseline 50 MB/s × thread factor): $(Format-Duration $State.InitialEta)") $app.Theme.TextDim @('Full','Simplified')
            $stats.Values.ETA.Text = (Format-Duration $State.InitialEta) + ' (est.)'
        }
        $stats.Values.TOTAL.Text = (Format-Bytes $State.TotalBytes)
    } catch {
        & $log.Append "Pre-scan failed: $($_.Exception.Message) (continuing anyway, ETA will be unavailable)" $app.Theme.Warn @('Full','Warnings')
    }

    & $log.Append ('━' * 90) $app.Theme.AccentDim @('Full','Simplified')
    & $log.Append ($(if ($dryRun) {'⌖ DRY RUN'} else {'🔥 COPYING'}) + '  ·  robocopy ' + ($rcArgs -join ' ')) $app.Theme.Lava @('Full','Simplified')
    & $log.Append ('━' * 90) $app.Theme.AccentDim @('Full','Simplified')

    # Reset progress
    try { $prog.Bar.Value = 0 } catch {}
    try { $prog.Detail.Text = "Starting…  $($State.TotalFiles) files queued  ·  $(Format-Bytes $State.TotalBytes) total" } catch {}

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'robocopy.exe'
    # Build a quoted argument STRING (works in both PowerShell 5.1 and 7+).
    # ArgumentList is null in 5.1, which is why the previous version crashed.
    $quoted = foreach ($a in $rcArgs) {
        if ($a -match '\s') { '"' + ($a -replace '"','\"') + '"' } else { $a }
    }
    $psi.Arguments = $quoted -join ' '
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi; $proc.EnableRaisingEvents = $true

    # ── Thread-safe queue: background runspace enqueues lines, UI timer drains
    $script:RcShared = [hashtable]::Synchronized(@{
        Queue    = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
        Done     = $false
        ExitCode = -1
    })
    $script:RcCompletionFired = $false

    # Background runspace: NOT blocked by Application.Run(), so Register-ObjectEvent
    # actions fire correctly. Only .NET + PS-safe operations inside.
    $bgCode = {
        param($shared, $proc)
        try {
            Get-EventSubscriber -SourceIdentifier 'rc-bg-*' -ErrorAction SilentlyContinue |
                Unregister-Event -Force -ErrorAction SilentlyContinue

            Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived `
                -SourceIdentifier 'rc-bg-out' -MessageData $shared -Action {
                $d = $Event.SourceEventArgs.Data
                if ($null -ne $d) { $Event.MessageData.Queue.Enqueue('O:' + $d) }
            } | Out-Null

            Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived `
                -SourceIdentifier 'rc-bg-err' -MessageData $shared -Action {
                $d = $Event.SourceEventArgs.Data
                if ($null -ne $d) { $Event.MessageData.Queue.Enqueue('E:' + $d) }
            } | Out-Null

            $proc.BeginOutputReadLine()
            $proc.BeginErrorReadLine()

            # Loop until process exits — Start-Sleep yields to the PS event pump so
            # the Register-ObjectEvent actions above fire and enqueue lines.
            do { Start-Sleep -Milliseconds 150 } while (-not $proc.HasExited)
            Start-Sleep -Milliseconds 500   # flush remaining buffered events

            Get-EventSubscriber -SourceIdentifier 'rc-bg-*' -ErrorAction SilentlyContinue |
                Unregister-Event -Force -ErrorAction SilentlyContinue
        } catch {
            $shared.Queue.Enqueue('E:BG ERROR: ' + $_.Exception.Message)
        }
        $shared.ExitCode = $proc.ExitCode
        $shared.Done = $true
    }

    $State.Process = $proc; $State.Started = Get-Date
    $State.IsDryRun = $dryRun; $State.Cancelled = $false; $State.Paused = $false
    $State.FilesSeen = 0; $State.BytesSeen = [int64]0
    $State.LastTickAt = Get-Date; $State.LastTickBytes = [int64]0
    $State.SpeedSamples.Clear()
    $State.ExtCounts.Clear(); $State.ExtBytes.Clear(); $State.FoldersSeen = 0
    $State.FailedFiles = 0; $State.FailedBytes = [int64]0; $State.ExtFailed.Clear()
    $State.SummaryTotal = 0; $State.SummaryCopied = 0; $State.SummaryFailed = 0; $State.SummarySkipped = 0

    foreach ($k in @('FILES','TOTAL','COPIED','ELAPSED','SPEED','ETA')) {
        $stats.Values[$k].Text = '—'
    }
    if ($State.TotalBytes -gt 0) { $stats.Values.TOTAL.Text = (Format-Bytes $State.TotalBytes) }

    Set-MavButtonReady $btns.Go $false
    Set-MavButtonReady $btns.DryRun $false
    Set-MavButtonReady $btns.Pause (-not $dryRun)
    Set-MavButtonReady $btns.Cancel $true
    Set-MavButtonReady $btns.OpenDest $false
    $app.Form.Cursor = 'AppStarting'
    Set-MavStatus -App $app -Text "Running $(if($dryRun){'dry run'}else{'transfer'})…" -Color $app.Theme.Lava

    [void]$proc.Start()

    # Launch background runspace AFTER process starts (BeginOutputReadLine is called inside bgCode)
    if ($script:RcPS) { try { $script:RcPS.Stop(); $script:RcPS.Dispose() } catch {}; $script:RcPS = $null }
    if ($script:RcRS) { try { $script:RcRS.Close(); $script:RcRS.Dispose() } catch {}; $script:RcRS = $null }
    $rcRS = [runspacefactory]::CreateRunspace(); $rcRS.Open()
    $rcPS = [PowerShell]::Create(); $rcPS.Runspace = $rcRS
    [void]$rcPS.AddScript($bgCode).AddArgument($script:RcShared).AddArgument($proc)
    $script:RcHandle = $rcPS.BeginInvoke()
    $script:RcPS = $rcPS
    $script:RcRS = $rcRS

    $statsTimer.Start()
}

# ─────────────────────────────────────────────────────────────────────
#  Click handlers
# ─────────────────────────────────────────────────────────────────────
$btns.Go.Add_Click({
    if (-not (Get-MavButtonReady $btns.Go)) { return }
    try {
        Run-Robocopy $false
    } catch {
        Log-Crash 'COPY click' $_
        [System.Windows.Forms.MessageBox]::Show($app.Form,
            "Couldn't start the copy:`n`n$($_.Exception.Message)`n`nDetails: $script:CrashLog",
            'Cannot start', 'OK', 'Error') | Out-Null
        Set-MavButtonReady $btns.Go $true
        Set-MavButtonReady $btns.DryRun $true
        Set-MavStatus -App $app -Text 'Error — see message.' -Color $app.Theme.Bad
    }
}.GetNewClosure())

$btns.DryRun.Add_Click({
    if (-not (Get-MavButtonReady $btns.DryRun)) { return }
    try {
        Run-Robocopy $true
    } catch {
        Log-Crash 'DRY RUN click' $_
        [System.Windows.Forms.MessageBox]::Show($app.Form,
            "Couldn't start the dry run:`n`n$($_.Exception.Message)`n`nDetails: $script:CrashLog",
            'Cannot start', 'OK', 'Error') | Out-Null
        Set-MavButtonReady $btns.Go $true
        Set-MavButtonReady $btns.DryRun $true
        Set-MavStatus -App $app -Text 'Error — see message.' -Color $app.Theme.Bad
    }
}.GetNewClosure())

$btns.Pause.Add_Click({
    if (-not (Get-MavButtonReady $btns.Pause)) { return }
    if (-not $State.Process -or $State.Process.HasExited) { return }
    if (-not $State.Paused) {
        try { [void][Mav.NtPower]::NtSuspendProcess($State.Process.Handle) } catch {}
        $State.Paused = $true; $btns.Pause.Text = '▶ Resume'
        Set-MavStatus -App $app -Text 'PAUSED — click Resume' -Color $app.Theme.Warn
    } else {
        try { [void][Mav.NtPower]::NtResumeProcess($State.Process.Handle) } catch {}
        $State.Paused = $false; $btns.Pause.Text = '⏸ Pause'
        Set-MavStatus -App $app -Text 'Resumed.' -Color $app.Theme.Lava
    }
}.GetNewClosure())

$btns.Cancel.Add_Click({
    if (-not (Get-MavButtonReady $btns.Cancel)) { return }
    if ($State.Process -and -not $State.Process.HasExited) {
        $State.Cancelled = $true
        if ($State.Paused) { try { [void][Mav.NtPower]::NtResumeProcess($State.Process.Handle) } catch {} }
        try { $State.Process.Kill($true) } catch {}
        Set-MavStatus -App $app -Text 'Cancelling…' -Color $app.Theme.Warn
    }
}.GetNewClosure())

$btns.Clear.Add_Click({
    & $log.Clear
    foreach ($k in @('FILES','TOTAL','COPIED','ELAPSED','SPEED','ETA')) { $stats.Values[$k].Text = '—' }
    try { $prog.Bar.Value = 0; $prog.Detail.Text = 'idle' } catch {}
    Set-MavStatus -App $app -Text 'Log cleared.' -Color $app.Theme.TextDim
}.GetNewClosure())

$btns.Export.Add_Click({
    $dest = & $log.Export $app.Form
    if ($dest) {
        Set-MavStatus -App $app -Text "Log exported: $dest" -Color $app.Theme.Good
    }
}.GetNewClosure())

$btns.OpenLog.Add_Click({
    if (Test-Path $script:LogDir) {
        Start-Process explorer.exe -ArgumentList $script:LogDir
    } else {
        Set-MavStatus -App $app -Text 'Log folder not found yet.' -Color $app.Theme.Warn
    }
}.GetNewClosure())

$btns.OpenDest.Add_Click({
    if (-not (Get-MavButtonReady $btns.OpenDest)) { return }
    $d = if ($State.LastDest) { $State.LastDest } else { $dst.TextBox.Text }
    if ($d -and (Test-Path $d)) { Start-Process explorer.exe -ArgumentList $d }
}.GetNewClosure())

$app.Form.Add_FormClosing({
    $statsTimer.Stop()
    if ($State.Process -and -not $State.Process.HasExited) {
        $r = [System.Windows.Forms.MessageBox]::Show($app.Form,
            'A copy is still running. Cancel and close?', 'Run in progress',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($r -ne 'Yes') { $_.Cancel = $true; $statsTimer.Start(); return }
        if ($State.Paused) { try { [void][Mav.NtPower]::NtResumeProcess($State.Process.Handle) } catch {} }
        try { $State.Process.Kill($true) } catch {}
    }
    try { if ($script:RcPS) { $script:RcPS.Stop(); $script:RcPS.Dispose() }; $script:RcPS = $null } catch {}
    try { if ($script:RcRS) { $script:RcRS.Close(); $script:RcRS.Dispose() }; $script:RcRS = $null } catch {}
}.GetNewClosure())

Show-MavApp $app
