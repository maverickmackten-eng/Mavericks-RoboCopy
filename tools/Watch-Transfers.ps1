#Requires -Version 5.1
# Watch-Transfers.ps1 — background transfer booster for Mavericks-RoboCopy.
#
# How it works:
#   1. Every 30 seconds, measure write throughput on every local drive.
#   2. Also scan all top-level windows for an Explorer copy/move dialog.
#   3. Two consecutive polls that both show a large transfer = confirmed.
#   4. On confirmation, read LastSource/LastDest from Mavericks-RoboCopy
#      settings.json and verify the destination drive is the hot one.
#   5. Run robocopy /MT:16 /E /R:0 /W:0 in the background — robocopy's
#      default timestamp+size comparison skips files Explorer already
#      finished, handles locked mid-write files gracefully (R:0 → skip),
#      and races ahead on everything not started yet.
#   6. Logs every action to %LOCALAPPDATA%\Mavericks-RoboCopy\booster.log
#
# Run manually:    .\Watch-Transfers.ps1
# Install as task: .\Install-TransferBooster.ps1
# Uninstall:       .\Remove-TransferBooster.ps1

param(
    [int]$PollSeconds      = 30,      # how often to check
    [double]$ThresholdMBps = 10.0,   # MB/s write rate to qualify as "large transfer"
    [int]$Threads          = 16,      # robocopy /MT value
    [switch]$Verbose                  # extra console output
)

Set-StrictMode -Version 2

# ── Paths ────────────────────────────────────────────────────────────────────
$settingsPath = "$env:APPDATA\Mavericks-RoboCopy\settings.json"
$logDir       = "$env:LOCALAPPDATA\Mavericks-RoboCopy"
$boosterLog   = Join-Path $logDir 'booster.log'
$rcLogDir     = Join-Path $logDir 'logs'

if (-not (Test-Path $logDir))   { [void](New-Item -ItemType Directory -Path $logDir   -Force) }
if (-not (Test-Path $rcLogDir)) { [void](New-Item -ItemType Directory -Path $rcLogDir -Force) }

function Write-Log([string]$msg, [string]$level = 'INFO') {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  [$level]  $msg"
    Add-Content -Path $boosterLog -Value $line -Encoding utf8 -ErrorAction SilentlyContinue
    if ($Verbose -or $level -eq 'WARN' -or $level -eq 'ERROR') { Write-Host $line }
}

# ── Win32: enumerate all top-level window titles (to find Explorer copy dialogs)
if (-not ('MavBooster.WinEnum' -as [type])) {
    Add-Type -Namespace 'MavBooster' -Name 'WinEnum' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool EnumWindows(EnumWindowsProc fn, System.IntPtr lp);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern int GetWindowText(System.IntPtr h, System.Text.StringBuilder s, int n);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern uint GetWindowThreadProcessId(System.IntPtr h, out uint pid);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool IsWindowVisible(System.IntPtr h);
public delegate bool EnumWindowsProc(System.IntPtr h, System.IntPtr l);

public static System.Collections.Generic.List<string> GetVisibleTitles(System.Collections.Generic.IEnumerable<int> pids) {
    var set = new System.Collections.Generic.HashSet<int>(pids);
    var out = new System.Collections.Generic.List<string>();
    EnumWindows((h, l) => {
        if (!IsWindowVisible(h)) return true;
        uint p; GetWindowThreadProcessId(h, out p);
        if (set.Contains((int)p)) {
            var sb = new System.Text.StringBuilder(512);
            GetWindowText(h, sb, 512);
            if (sb.Length > 0) out.Add(sb.ToString());
        }
        return true;
    }, System.IntPtr.Zero);
    return out;
}
'@
}

# ── Detect an Explorer copy/move dialog by scanning all explorer window titles ──
function Test-ExplorerTransferDialog {
    try {
        $pids = @(Get-Process explorer -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
        if (-not $pids) { return $false }
        $titles = [MavBooster.WinEnum]::GetVisibleTitles($pids)
        return ($titles | Where-Object { $_ -match '^(Copying|Moving|File Operation)' }).Count -gt 0
    } catch { return $false }
}

# ── Get per-drive write throughput (MB/s) ────────────────────────────────────
function Get-HotWriteDrives([double]$thresholdMBps) {
    try {
        $samples = Get-Counter '\LogicalDisk(*)\Disk Write Bytes/sec' -ErrorAction SilentlyContinue
        if (-not $samples) { return @() }
        return $samples.CounterSamples |
            Where-Object {
                $_.InstanceName -notmatch '^(_Total|HarddiskVolume\d*)$' -and
                $_.CookedValue -gt ($thresholdMBps * 1MB)
            } |
            ForEach-Object { $_.InstanceName.Trim(':').ToUpper() }
    } catch { return @() }
}

# ── Check if Mavericks-RoboCopy is already running a transfer ────────────────
function Test-RoboCopyAlreadyRunning {
    # Mavericks-RoboCopy launches robocopy.exe as a child process
    return (Get-Process robocopy -ErrorAction SilentlyContinue).Count -gt 0
}

# ── Read last-used source/dest from Mavericks-RoboCopy settings.json ─────────
function Get-SavedPaths {
    if (-not (Test-Path $settingsPath)) { return $null }
    try {
        $s = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($s.LastSource -and $s.LastDest) {
            return @{ Source = [string]$s.LastSource; Dest = [string]$s.LastDest }
        }
    } catch {}
    return $null
}

# ── Send a Windows toast notification (best-effort, silent on failure) ────────
function Send-Toast([string]$title, [string]$body) {
    try {
        $xml = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$([System.Security.SecurityElement]::Escape($title))</text>
      <text>$([System.Security.SecurityElement]::Escape($body))</text>
    </binding>
  </visual>
</toast>
"@
        $xdoc = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType=WindowsRuntime]::new()
        $xdoc.LoadXml($xml)
        $toast = [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType=WindowsRuntime]::new($xdoc)
        $mgr   = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime]
        $notifier = $mgr::CreateToastNotifier('Mavericks-RoboCopy Booster')
        $notifier.Show($toast)
    } catch {}
}

# ── Launch the robocopy boost ─────────────────────────────────────────────────
function Start-BoostJob([string]$src, [string]$dst) {
    $logFile = Join-Path $rcLogDir ("boost-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
    $rcArgs  = @(
        $src.TrimEnd('\'), $dst.TrimEnd('\'),
        '/E',            # include subdirs
        "/MT:$Threads",  # parallel threads
        '/R:0', '/W:0',  # no retry/wait on locked files — skip immediately
        '/NP',           # no per-file % (cleaner log)
        '/BYTES',        # sizes as plain bytes (consistent with app)
        '/TEE',          # stdout + log simultaneously
        "/UNILOG+:$logFile"  # unicode log, append
    )
    Write-Log "BOOST START  src='$src'  dst='$dst'  threads=$Threads  log=$logFile"
    $proc = Start-Process robocopy.exe -ArgumentList $rcArgs -WindowStyle Hidden -PassThru -ErrorAction Stop
    Write-Log "BOOST PID $($proc.Id) launched"
    return $proc
}

# ─────────────────────────────────────────────────────────────────────────────
#  Main loop
# ─────────────────────────────────────────────────────────────────────────────
Write-Log "Transfer Booster started  PID=$PID  poll=${PollSeconds}s  threshold=${ThresholdMBps}MB/s  threads=$Threads"

$pendingCount = 0      # consecutive polls with transfer detected
$boostProc    = $null  # currently running boost robocopy process

while ($true) {
    try {
        # 1. If a boost is running, check if it finished
        if ($boostProc -and $boostProc.HasExited) {
            Write-Log "BOOST DONE  exit=$($boostProc.ExitCode)"
            $boostProc = $null
            $pendingCount = 0
        }

        # 2. Don't start another boost if one is running or robocopy is already active
        $alreadyBoosting = ($boostProc -and -not $boostProc.HasExited)
        $rcRunning       = Test-RoboCopyAlreadyRunning

        if (-not $alreadyBoosting -and -not $rcRunning) {

            # 3. Detection signals
            $hotDrives     = Get-HotWriteDrives $ThresholdMBps
            $dialogPresent = Test-ExplorerTransferDialog

            $signalActive = ($hotDrives.Count -gt 0) -or $dialogPresent

            if ($Verbose) {
                Write-Log "Poll: hotDrives=[$($hotDrives -join ',')] dialog=$dialogPresent pending=$pendingCount" 'DEBUG'
            }

            if ($signalActive) {
                $pendingCount++
                Write-Log "Transfer signal detected (poll $pendingCount/2)  drives=[$($hotDrives -join ',')]  dialog=$dialogPresent"

                if ($pendingCount -ge 2) {
                    # 4. Confirmed — resolve source/dest
                    $paths = Get-SavedPaths

                    if ($paths) {
                        $destDrive = [System.IO.Path]::GetPathRoot($paths.Dest).TrimEnd('\').Replace(':','').ToUpper()

                        # Verify: destination drive is the one taking writes (or no hot drives — dialog-only confirmation)
                        $driveMatches = ($hotDrives.Count -eq 0) -or ($destDrive -in $hotDrives)

                        if ($driveMatches -and (Test-Path $paths.Source) -and $paths.Dest) {
                            Write-Log "Destination drive '$destDrive' confirmed hot. Boosting."
                            try {
                                $boostProc    = Start-BoostJob $paths.Source $paths.Dest
                                $pendingCount = 0
                                Send-Toast 'RoboCopy Boost Active' "Boosting transfer to $($paths.Dest) using $Threads threads"
                            } catch {
                                Write-Log "Failed to start boost: $_" 'ERROR'
                                $pendingCount = 0
                            }
                        } else {
                            Write-Log "Drive mismatch or source not found (settings: src='$($paths.Source)' dest='$($paths.Dest)' destDrive='$destDrive' hotDrives='$($hotDrives -join ',')')" 'WARN'
                            Send-Toast 'Large Transfer Detected' "Open Mavericks-RoboCopy to boost with $Threads threads"
                            $pendingCount = 0
                        }
                    } else {
                        Write-Log 'Transfer detected but no saved source/dest in settings.json' 'WARN'
                        Send-Toast 'Large Transfer Detected' 'Open Mavericks-RoboCopy to set source/dest and boost with 16 threads'
                        $pendingCount = 0
                    }
                }
            } else {
                # Signal gone — reset
                if ($pendingCount -gt 0) {
                    Write-Log "Transfer signal cleared (was $pendingCount). Resetting."
                }
                $pendingCount = 0
            }
        }
    } catch {
        Write-Log "Unhandled error in poll loop: $_" 'ERROR'
    }

    Start-Sleep -Seconds $PollSeconds
}
