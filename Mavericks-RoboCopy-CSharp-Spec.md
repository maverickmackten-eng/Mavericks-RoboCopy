# Mavericks-RoboCopy — Comprehensive Technical Specification for C# Rewrite

> **Purpose:** This document is the single-source-of-truth technical specification derived from reading every source file in the `Mavericks-RoboCopy` PowerShell project. Use it to build a functionally identical C#/WinForms replacement without referencing the original PowerShell sources.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Settings Persistence](#2-settings-persistence)
3. [Runtime State Object](#3-runtime-state-object)
4. [UI Component Hierarchy & Data Interfaces](#4-ui-component-hierarchy--data-interfaces)
5. [Mav-AppTemplate Framework](#5-mav-apptemplate-framework)
6. [Theme System (Inferno)](#6-theme-system-inferno)
7. [Font System](#7-font-system)
8. [Robocopy Argument Building](#8-robocopy-argument-building)
9. [Robocopy Output Parsing — All Regex Patterns](#9-robocopy-output-parsing--all-regex-patterns)
10. [Log Tab Routing](#10-log-tab-routing)
11. [Pre-Scan Mechanism](#11-pre-scan-mechanism)
12. [ETA Calculation Formula](#12-eta-calculation-formula)
13. [Speed Sampling Algorithm](#13-speed-sampling-algorithm)
14. [Live Stats Row Updates](#14-live-stats-row-updates)
15. [Progress Bar Logic](#15-progress-bar-logic)
16. [Pause/Resume Mechanism (NtSuspendProcess)](#16-pauseresume-mechanism-ntsuspendprocess)
17. [Cancel Mechanism](#17-cancel-mechanism)
18. [Process Lifecycle & Background Thread](#18-process-lifecycle--background-thread)
19. [File Type Breakdown Logic](#19-file-type-breakdown-logic)
20. [Completion Logic & Summary Output](#20-completion-logic--summary-output)
21. [Robocopy Exit Code Interpretation](#21-robocopy-exit-code-interpretation)
22. [Log Files & Paths](#22-log-files--paths)
23. [Crash Logging](#23-crash-logging)
24. [Console-Run.ps1 — CLI Differences](#24-console-runps1--cli-differences)
25. [Watch-Transfers.ps1 — Auto-Booster Service](#25-watch-transfersps1--auto-booster-service)
26. [Reset-State.ps1 — Test Cleanup Tool](#26-reset-stateps1--test-cleanup-tool)
27. [Tests (Pester) — Behaviors Verified](#27-tests-pester--behaviors-verified)
28. [Recent Paths Store](#28-recent-paths-store)
29. [DPI Awareness Setup](#29-dpi-awareness-setup)
30. [C# Rewrite — Component Checklist](#30-c-rewrite--component-checklist)

---

## 1. Project Structure

```
Mavericks-RoboCopy/
|-- Mavericks-RoboCopy.ps1       # Main GUI application (~830 lines)
|-- Mav-AppTemplate.psm1         # WinForms layout framework (~2800 lines)
|-- Mav-AppTemplate.psd1         # Module manifest
|-- tools/
|   |-- Console-Run.ps1          # CLI-only robocopy wrapper (no GUI)
|   |-- Watch-Transfers.ps1      # Background transfer booster service
|   |-- Reset-State.ps1          # Test/dev cleanup utility
|   |-- Install-TransferBooster.ps1
|   `-- Remove-TransferBooster.ps1
`-- tests/
    `-- Mavericks-RoboCopy.Tests.ps1  # Pester unit tests
```

---

## 2. Settings Persistence

**File:** `%APPDATA%\\Mavericks-RoboCopy\\settings.json`

Load: if file missing or JSON corrupt, return defaults with empty `Presets` dict.  
Save: after every completed transfer, UTF-8 encoding, depth=6.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `LastSource` | string | `""` | Last used source path |
| `LastDest` | string | `""` | Last used destination path |
| `Threads` | int | `16` | `/MT:N` thread count |
| `IncludeSubdirs` | bool | `true` | Whether `/E` is passed |
| `Verbose` | bool | `true` | Whether `/V` is passed |
| `Restartable` | bool | `false` | Whether `/Z` is passed |
| `Excludes` | string | `""` | Comma/semicolon-separated exclude patterns |
| `Prescan` | bool | `false` | (UI-only; pre-scan always runs in code) |
| `OpenDestWhenDone` | bool | `false` | Open Explorer on destination after copy |
| `Presets` | dict | `{}` | Reserved for future preset storage |

---

## 3. Runtime State Object

Reset at the start of each `Run-Robocopy` call.

| Property | C# Type | Description |
|----------|---------|-------------|
| `Process` | `Process` | Running robocopy.exe instance |
| `Started` | `DateTime` | When proc.Start() was called |
| `IsDryRun` | `bool` | True if /L was passed |
| `Cancelled` | `bool` | Set by Cancel button |
| `Paused` | `bool` | True while NtSuspendProcess is active |
| `FilesSeen` | `int` | Live count of successfully transferred files |
| `BytesSeen` | `long` | Live count of bytes transferred |
| `TotalFiles` | `int` | From pre-scan |
| `TotalBytes` | `long` | From pre-scan |
| `InitialEta` | `TimeSpan?` | Heuristic ETA computed from pre-scan |
| `LastTickAt` | `DateTime?` | Time of previous speed sample |
| `LastTickBytes` | `long` | BytesSeen at previous tick |
| `SpeedSamples` | `List<double>` | Rolling window, max 6 entries |
| `LastDest` | `string` | Saved at completion for Open Dest |
| `ExtCounts` | `Dictionary<string,int>` | Extension -> successful file count |
| `ExtBytes` | `Dictionary<string,long>` | Extension -> bytes transferred |
| `FoldersSeen` | `int` | New directories created in destination |
| `FailedFiles` | `int` | Files that hit a copy error |
| `FailedBytes` | `long` | Bytes of failed transfers |
| `ExtFailed` | `Dictionary<string,int>` | Extension -> failed file count |
| `SummaryTotal` | `int` | From robocopy "Files :" summary line |
| `SummaryCopied` | `int` | From robocopy "Files :" summary line |
| `SummaryFailed` | `int` | From robocopy "Files :" summary line |
| `SummarySkipped` | `int` | From robocopy "Files :" summary line |

> **Fallback rule:** `SummaryCopied`/`SummaryFailed` preferred over `FilesSeen`/`FailedFiles` if the summary table line was received.

---

## 4. UI Component Hierarchy & Data Interfaces

### 4.1 Form (`$app`)

`New-MavForm` — Size: 1280 x 1280. Title: `"Mavericks-RoboCopy"`. Subtitle: `"fast file transfer · pause·resume·throttle · cut+paste support"`. Version: `"v5.0"`.

### 4.2 Source Path Row (`$src`)

`Add-MavPathRow -Title 'SOURCE' -Description 'pick the folder to copy/move FROM'`

| Property | Type | Notes |
|----------|------|-------|
| `src.TextBox.Text` | string | Current source folder path |
| `src.BrowseButton` | Button | Opens IFileOpenDialog (FolderBrowserDialog fallback) |
| `src.RecentButton` | Button | ContextMenuStrip of recent paths |
| `src.GroupBox` | GroupBox | Outer container |
| `src.Bucket` | `"SOURCE"` | Key for recents store |

- Drag-drop supported (folder auto-fills TextBox)
- On TextBox Leave: if path exists on disk, adds to recents

### 4.3 Destination Path Row (`$dst`)

Identical to `$src`, Title = `"DESTINATION"`, Bucket = `"DESTINATION"`.

### 4.4 Mode Radio Group (`$mode`)

`Add-MavRadioGroup -Title 'Mode'`

| Key | Label | Color | Confirm Dialog |
|-----|-------|-------|----------------|
| `Copy` | `📄 COPY — originals stay` | Text | No |
| `Move` | `✂  MOVE — cut+paste` | Warn (orange) | Yes — warns source files deleted |
| `Mirror` | `🗑 MIRROR — sync, deletes extras` | Bad (red) | Yes — warns dest extras deleted |

Access: `mode.Radios["Copy"].Checked`, `.Move.Checked`, `.Mirror.Checked`

### 4.5 Options Group (`$opts`)

`Add-MavOptionsGroup -Title 'Options' -Height 70`

| Name | Control | Range | Default | Flag |
|------|---------|-------|---------|------|
| `Threads` | NumericUpDown | 1–128 | 16 | `/MT:N` |
| `Subdirs` | CheckBox | — | true | `/E` |
| `Verbose` | CheckBox | — | true | `/V` |
| `Restartable` | CheckBox | — | false | `/Z` |

### 4.6 Filters Group (`$filt`)

`Add-MavOptionsGroup -Title 'Filters' -Height 70`

| Name | Control | Default | Flag |
|------|---------|---------|------|
| `Excludes` | TextBox (w=560) | `""` | `/XD` or `/XF` per token |
| `Days` | NumericUpDown (0–36500) | 0 | `/MAXAGE:N` if > 0 |
| `IPG` | NumericUpDown (0–9999) | 0 | `/IPG:N` if > 0 |

### 4.7 Post Options Group (`$post`)

`Add-MavOptionsGroup -Title 'After' -Height 70`

| Name | Control | Default | Action |
|------|---------|---------|--------|
| `Prescan` | CheckBox | false | UI only; code always pre-scans |
| `OpenDest` | CheckBox | false | Open Explorer on dest after success |

### 4.8 Stats Row (`$stats`)

`Add-MavStatsRow -Captions @('FILES','TOTAL','COPIED','ELAPSED','SPEED','ETA') -Height 80`

Access: `stats.Values["FILES"].Text = "42"`  
All 6 value labels: Consolas 11pt Bold, foreground = Ember color.

| Caption | Value During Transfer |
|---------|----------------------|
| FILES | `FilesSeen.ToString()` |
| TOTAL | `FormatBytes(TotalBytes)` |
| COPIED | `FormatBytes(BytesSeen)` |
| ELAPSED | `FormatDuration(Now - Started)` |
| SPEED | Rolling 6-sample avg + "/s", or `"PAUSED"` |
| ETA | Live or `InitialEta + " (est.)"` |

### 4.9 Progress Row (`$prog`)

`Add-MavProgressRow -Height 88`

| Property | Description |
|----------|-------------|
| `prog.Bar` | ProgressBar, Continuous, 0–100 |
| `prog.Caption` | Label "PROGRESS" |
| `prog.Detail` | `"42/1000 files  ·  4% complete  ·  1.2 GB/30 GB"` |

### 4.10 Tabbed Log Panel (`$log`)

`Add-MavTabbedLogPanel -Height 320 -Tabs @('Full','Simplified','Warnings','Errors')`

| Member | Description |
|--------|-------------|
| `log.Append(line, color, channels[])` | Append to tab(s) + disk file |
| `log.Clear()` | Clear all tabs + reset count badges |
| `log.SetLogFile(path)` | Set disk log target |
| `log.Export(owner)` | SaveFileDialog to dump Full tab |
| `log.Tabs["Full"]` | RichTextBox — all output |
| `log.Tabs["Simplified"]` | RichTextBox — clean view |
| `log.Tabs["Warnings"]` | RichTextBox — skips/mismatches |
| `log.Tabs["Errors"]` | RichTextBox — copy errors |
| `log.Counts["Errors"]` | int — shown in tab badge `"Errors (3)"` |

### 4.11 Button Bar (`$btns`)

`Add-MavButtonBar` — all buttons accessed as `btns["KEY"]`

| Key | Label | Side | Initial | Color |
|-----|-------|------|---------|-------|
| `Go` | `▶ COPY` | Right | **Enabled** | Accent (red), Primary |
| `DryRun` | `👁 Dry Run` | Right | Enabled | Default |
| `Pause` | `⏸ Pause` | Right | **Disabled** | Warn (orange) |
| `Cancel` | `✕ Cancel` | Right | **Disabled** | Bad (red) |
| `Clear` | `🗑 Clear` | Left | Enabled | Default |
| `Export` | `💾 Export Log` | Left | Enabled | Default |
| `OpenLog` | `📁 Open Log Folder` | Left | Enabled | Default |
| `OpenDest` | `📂 Open Destination` | Left | **Disabled** | Default |

**Soft-disable** = cursor → `Cursors.No`, text color → 50% darkened; clicks are no-ops.

---

## 5. Mav-AppTemplate Framework

### Exported Functions Reference

| Function | Returns | Notes |
|----------|---------|-------|
| `Initialize-MavApp [-Theme Inferno]` | void | DPI setup + assemblies + theme. Must run before any form. |
| `New-MavForm` | `$app` object | Form with header/status/buttonbar/scrollable content |
| `Show-MavApp $app` | void | `Application.Run($app.Form)` |
| `Test-MavFrameworkHealth -RequiredFunctions` | void / throws | Pre-flight check; throws if any function missing |
| `Add-MavPathRow` | `{GroupBox, TextBox, RecentButton, BrowseButton, Bucket}` | |
| `Add-MavRadioGroup` | `{GroupBox, Radios: hashtable}` | |
| `Add-MavOptionsGroup` | `{GroupBox, Controls: hashtable, Flow}` | |
| `Add-MavStatsRow` | `{Panel, Values: hashtable}` | |
| `Add-MavProgressRow` | `{Panel, Bar, Caption, Detail}` | |
| `Add-MavTabbedLogPanel` | `{Panel, TabControl, Tabs, TextBox, Append, Clear, SetLogFile, Export, Counts}` | |
| `Add-MavLogPanel` | `{Panel, TextBox, Append}` | Single-tab version |
| `Add-MavButtonBar` | `hashtable<Key, Button>` | Also stored in `$app.Buttons` |
| `Set-MavButtonReady $btn $bool` | void | Enable / soft-disable |
| `Get-MavButtonReady $btn` | bool | True if button is ready |
| `Set-MavStatus -App -Text -Color` | void | Thread-safe via BeginInvoke |
| `Pick-FolderModern` | string / null | IFileOpenDialog + FolderBrowserDialog fallback |
| `Add-MavRecent -Bucket -Path` | void | Dedupe, max 12, newest-first |
| `Get-MavRecent -Bucket` | string[] | |
| `Clear-MavRecent [-Bucket]` | void | One bucket or all |

### Layout z-order Rule (critical for Dock=Fill)
WinForms processes Dock in REVERSE z-order (highest index docks first). Always set Fill child to index 0, docked edges to higher indices, then call `PerformLayout()`.

---

## 6. Theme System (Inferno)

Single built-in theme. All values are `System.Drawing.Color`.

| Key | Hex | Usage |
|-----|-----|-------|
| Bg | #0A0A0A | Form background |
| BgAlt | #140E0C | Header, button bar, status strip |
| BgPanel | #1C1210 | GroupBox interiors, input backgrounds |
| BgPanelHi | #281816 | Hover highlight |
| Border | #501812 | Button flat borders |
| Text | #E8E2DA | Primary text |
| TextDim | #8C7C74 | Secondary/dim text |
| TextFaint | #5A504C | Very faint text |
| Accent | #DC2626 | Primary button background |
| AccentDim | #8C1818 | Version label, divider lines |
| Lava | #FF5722 | Section headers, icon glyph |
| Ember | #FF8A1E | Stat values, Recent button, extra-file lines |
| Flame | #FFC83C | Warm yellow |
| Char | #3A1C18 | Dark panel variant |
| Good | #78C864 | Success / transferred files (green) |
| Warn | #E6B450 | Warnings, paused state (orange-yellow) |
| Bad | #E65050 | Errors, failed files (red) |

**Header glow:** `LinearGradientBrush(AccentDim -> Lava)`, horizontal, 3px bar at bottom of header.

---

## 7. Font System

| Key | Typeface | pt | Style | Usage |
|-----|----------|----|-------|-------|
| UI | Segoe UI | 9 | Regular | Default form font |
| UIB | Segoe UI | 9 | Bold | Section headers, buttons |
| UITitle | Segoe UI | 18 | Bold | App title |
| UISub | Segoe UI | 9 | Italic | Subtitle, stat captions |
| Mono | Consolas | 9 | Regular | Log RichTextBox, path TextBoxes |
| Stat | Consolas | 11 | Bold | Live stat value labels |

---

## 8. Robocopy Argument Building

Canonical logic (identical in GUI and Console-Run.ps1):

```
args = [
  source.TrimEnd('\\', '/'),
  dest.TrimEnd('\\', '/')
]

IF subdirs:         append "/E"
ALWAYS:             append "/MT:{threads}"
ALWAYS:             append "/R:1", "/W:1", "/NP", "/TEE"
GUI ONLY:           append "/BYTES"
IF verbose:         append "/V"
IF restartable:     append "/Z"
IF mode == Mirror:  append "/MIR"   (XOR with /MOV)
IF mode == Move:    append "/MOV"   (XOR with /MIR)
IF dryRun:          append "/L"
IF days > 0:        append "/MAXAGE:{days}"
IF ipg > 0:         append "/IPG:{ipg}"

FOR each token in Excludes.Split(',', ';'):
  token = token.Trim()
  IF empty: skip
  IF token contains '*' or '?': append "/XF", token
  ELSE:                          append "/XD", token
```

**Argument quoting (GUI only):** Build a single `Arguments` string; wrap each arg in `"..."` if it contains spaces. Do NOT use `ProcessStartInfo.ArgumentList` (unreliable in all target PowerShell versions).

---

## 9. Robocopy Output Parsing — All Regex Patterns

### 9.1 Line Color Assignment

| Regex | Color Key |
|-------|----------|
| `^\s*\*EXTRA` | Ember |
| `New File\|^\s*Newer` | Good |
| `Older\|Mismatch\|Skipped` | Warn |
| `Same` | TextDim |
| `ERROR\|FAILED\|Access denied` | Bad |
| (default) | Text |

### 9.2 Log Tab Channel Routing

| Match | Channels |
|-------|---------|
| `ERROR\|FAILED\|Access denied\|Cannot access` | Full, Errors, Simplified |
| `Older\|Mismatch\|Skipped\|^\s*\*EXTRA` | Full, Warnings |
| `New File\|^\s*Newer` or any summary/header marker | Full, Simplified |
| Everything else | Full only |

Summary/header markers (also routed to Simplified):
`━{5,}`, `═{5,}`, `Started :`, `Ended :`, `Source :`, `Dest :`, `Files\s*:`, `Bytes\s*:`, `Dirs\s*:`, `Speed\s*:`, `TRANSFER COMPLETE`, `DRY RUN COMPLETE`, `CANCELLED`

### 9.3 Transfer Stats (called on every output line)

**Successful file transfer:**
```
Pattern: ^\s*(?:New File|Newer)\s+([\d,.]+\s*[kKmMgG]?)\s+(.+)$
Group 1: size string (may have k/m/g suffix)
Group 2: file path
Action:  FilesSeen++
         BytesSeen += ParseSize(group1)
         ext = Path.GetExtension(group2).ToLower() || "(no ext)"
         ExtCounts[ext]++
         ExtBytes[ext] += size
```

**Failed copy:**
```
Pattern: ERROR \d+.*(?:Copying File|Creating File|Moving File)\s+(.+)$
Group 1: file path
Action:  FailedFiles++
         ExtFailed[ext]++
```

**New directory:**
```
Pattern: ^\s*New Dir\s
Action:  FoldersSeen++
```

**Robocopy summary table (authoritative counts):**
```
Pattern: ^\s*Files\s*:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)
Groups:  1=Total, 2=Copied, 3=Skipped, 4=Mismatch, 5=Failed, 6=Extras
Action:  SummaryTotal=G1; SummaryCopied=G2; SummarySkipped=G3; SummaryFailed=G5
```

### 9.4 Pre-Scan Output Parsing

Command: `robocopy.exe {src} NUL /L /E /NFL /NJH /R:0 /W:0 /BYTES`

```
Files:  ^\s*Files\s*:\s*(\d+)\s+   -> TotalFiles = int(G1)
Bytes:  ^\s*Bytes\s*:\s*(\d+)\s+   -> TotalBytes = long(G1)
```

### 9.5 Size String Parser

```
Pattern: ([\d,.]+)\s*([kKmMgG])?
Remove commas; parse as double.
Multiplier: k/K=1024, m/M=1048576, g/G=1073741824, default=1
Return: (long)(num * multiplier)
```

---

## 10. Log Tab Routing

Every `Append(line, color, channels[])` call:
1. Appends to each named tab's RichTextBox
2. Updates that tab's count badge: `"Errors"` -> `"Errors (3)"`
3. Writes line to disk log file (if `SetLogFile` was called) — unconditionally, regardless of channels

Channel assignment is determined by `ChannelsForLine(line)` (§9.2).

---

## 11. Pre-Scan Mechanism

Pre-scan **always runs** at the start of every transfer (the Prescan checkbox only affects UI display; `PreScan-Source` is unconditionally called).

**Command:** `robocopy.exe {source} NUL /L /E /NFL /NJH /R:0 /W:0 /BYTES`

- `/L` = list only, no actual copy
- `NUL` = dummy destination
- `/NFL /NJH` = suppress per-file and header output (summary lines only)
- `/R:0 /W:0` = fail fast

**Log output during pre-scan (Full + Simplified tabs):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ (90 chars)
Pre-scanning {source} for size + file count…
Pre-scan: {N} files · {size} total
Initial ETA estimate (with /MT:{N}, baseline 50 MB/s × thread factor): {H:MM}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ (90 chars)
```

On failure: logs `"Pre-scan failed: {msg} (continuing anyway, ETA will be unavailable)"` to Full + Warnings tabs. Transfer continues regardless.

**Returns:** `{ Files: int, Bytes: long }`

---

## 12. ETA Calculation Formula

### Initial ETA (heuristic, computed before transfer starts)

```
thread_factor  = 1.0 + (0.6 * Math.Log10(Math.Max(1, threads)))
effective_MBps = 50.0 * thread_factor        // 50 MB/s = USB3/SATA SSD baseline
bps            = effective_MBps * 1048576
secs           = totalBytes / bps
InitialEta     = TimeSpan.FromSeconds(Math.Ceiling(secs))
```

Example — 16 threads:
- `thread_factor = 1 + 0.6 * 1.204 = 1.722`
- `effective = 50 * 1.722 = 86.1 MB/s`

Display: `FormatDuration(InitialEta) + " (est.)"` — suffix signals it is a guess.

### Live ETA (updated every 300ms during transfer)

```
remaining = TotalBytes - BytesSeen
ETA       = TimeSpan.FromSeconds(Math.Ceiling(remaining / rollingAvgBps))
```

Falls back to `InitialEta` display if `rollingAvgBps == 0` or no pre-scan ran.

---

## 13. Speed Sampling Algorithm

- UI timer fires every **300ms**
- On each tick:
  1. `delta = BytesSeen - LastTickBytes`
  2. `dt = (DateTime.Now - LastTickAt).TotalSeconds`
  3. If `dt > 0`: append `delta / dt` to SpeedSamples
  4. Trim SpeedSamples to last **6 entries** (RemoveAt(0) while Count > 6)
  5. `speedBps = SpeedSamples.Average()`
- Display: `FormatBytes((long)speedBps) + "/s"`
- When paused: display `"PAUSED"` regardless of computed speed

---

## 14. Live Stats Row Updates

Timer fires every 300ms. Guard: only update while `State.Process != null && !State.Process.HasExited`.

| Label | Value |
|-------|-------|
| FILES | `State.FilesSeen.ToString()` |
| TOTAL | `FormatBytes(State.TotalBytes)` (or `"—"` if zero) |
| COPIED | `FormatBytes(State.BytesSeen)` |
| ELAPSED | `FormatDuration(DateTime.Now - State.Started)` |
| SPEED | Rolling avg + "/s" or `"PAUSED"` |
| ETA | Live formula (§12) or `InitialEta + " (est.)"` |

---

## 15. Progress Bar Logic

- Range: 0–100, `ProgressBarStyle.Continuous` (no marquee)
- Update: `Math.Min(100, (int)((BytesSeen / (double)TotalBytes) * 100))` — only if `TotalBytes > 0`
- Detail label: `"{FilesSeen}/{TotalFiles} files  ·  {pct}% complete  ·  {FormatBytes(BytesSeen)}/{FormatBytes(TotalBytes)}"`
- On completion (exit ≤ 7): force bar to 100
- On idle/clear: bar = 0, detail = `"idle"`

---

## 16. Pause/Resume Mechanism (NtSuspendProcess)

### P/Invoke (ntdll.dll)

```csharp
[DllImport("ntdll.dll")]
public static extern int NtSuspendProcess(IntPtr processHandle);

[DllImport("ntdll.dll")]
public static extern int NtResumeProcess(IntPtr processHandle);
```

### Pause Flow
1. User clicks Pause button (enabled only during active non-dry-run transfer)
2. `NtSuspendProcess(State.Process.Handle)` — suspends ALL threads of robocopy.exe
3. `State.Paused = true`
4. Button text: `"⏸ Pause"` → `"▶ Resume"`
5. Status bar: `"PAUSED — click Resume"` (Warn color)
6. SPEED stat: `"PAUSED"`

### Resume Flow
1. User clicks same button (now labeled `"▶ Resume"`)
2. `NtResumeProcess(State.Process.Handle)`
3. `State.Paused = false`
4. Button text: `"▶ Resume"` → `"⏸ Pause"`
5. Status bar: `"Resumed."` (Lava color)

### Cancel-While-Paused
Must resume first: `NtResumeProcess(handle)`, then `Process.Kill(entireProcessTree: true)`.

### Form-Close-While-Paused
Same: resume, then kill, inside FormClosing handler.

---

## 17. Cancel Mechanism

1. User clicks Cancel button (enabled only when process is running)
2. `State.Cancelled = true`
3. If `State.Paused`: call `NtResumeProcess` first
4. `State.Process.Kill(true)` — kills process tree
5. Status bar: `"Cancelling…"` (Warn color)
6. Completion handler: sets TAG = `"CANCELLED"` in summary header

---

## 18. Process Lifecycle & Background Thread

### Why a Background Thread?
`Application.Run()` blocks the UI thread. `Process.OutputDataReceived`/`ErrorDataReceived` handlers run on thread-pool threads and must enqueue output for the UI timer to drain safely on the UI thread.

### C# Implementation Pattern

```csharp
// Shared: background thread fills, UI timer drains
var outputQueue = new ConcurrentQueue<string>(); // prefix "O:" or "E:"
volatile bool done = false;
int exitCode = -1;

var psi = new ProcessStartInfo {
    FileName = "robocopy.exe",
    Arguments = BuildQuotedArgString(rcArgs),   // wrap spaces in "..."
    RedirectStandardOutput = true,
    RedirectStandardError  = true,
    UseShellExecute        = false,
    CreateNoWindow         = true,
    StandardOutputEncoding = Encoding.UTF8
};

var proc = new Process { StartInfo = psi, EnableRaisingEvents = true };
proc.OutputDataReceived += (s, e) => { if (e.Data != null) outputQueue.Enqueue("O:" + e.Data); };
proc.ErrorDataReceived  += (s, e) => { if (e.Data != null) outputQueue.Enqueue("E:" + e.Data); };

proc.Start();
proc.BeginOutputReadLine();
proc.BeginErrorReadLine();

Task.Run(() => {
    proc.WaitForExit();
    Thread.Sleep(500);    // flush buffered async events
    exitCode = proc.ExitCode;
    done = true;
});

// UI Timer (300ms):
uiTimer.Tick += (s, e) => {
    while (outputQueue.TryDequeue(out string raw)) {
        bool isErr = raw.StartsWith("E:");
        string line = raw.Substring(2);
        Color c = isErr ? theme.Bad : ColorForLine(line);
        string[] ch = isErr ? new[]{"Full","Errors"} : ChannelsForLine(line);
        logPanel.Append(line, c, ch);
        UpdateTransferStats(line);
    }
    if (done && outputQueue.IsEmpty && !completionFired) {
        completionFired = true;
        HandleCompletion(exitCode);
    }
    // Also update live stats if still running...
};
```

**Disposal:** After completion, stop the UI timer, dispose the `Process` object. No runspace/thread needs explicit disposal (Task completes naturally).

---

## 19. File Type Breakdown Logic

### Tracking (during transfer)
- On successful transfer: `ExtCounts[ext]++; ExtBytes[ext] += size`
- On failed copy: `ExtFailed[ext]++`
- Extension: `Path.GetExtension(filePath).ToLower()` — empty → `"(no ext)"`

### Post-Completion Display

Written to Full and Simplified tabs:

```
────────────────────────────────────────────────────
  EXT          FILES      DATA MOVED
────────────────────────────────────────────────────
  MP4             42      12.3 GB
  JPG            123       4.1 GB  (2 failed)
  (no ext)         5         800 KB
────────────────────────────────────────────────────
```

**Algorithm:**
1. Sort `ExtCounts` by value descending
2. Show top 15 extensions
3. Row format: `{ext.TrimStart('.').ToUpper(),-12}  {count,6}   {FormatBytes(bytes),12}` + optional `"  ({N} failed)"` suffix
4. After top-15 loop: show extensions that ONLY appear in `ExtFailed` (never in `ExtCounts`) with `"— all failed"` in data column, color = Bad
5. In Simplified tab only: if `ExtCounts.Count > 15`, append `"… and N more type(s) — see Full tab"`

---

## 20. Completion Logic & Summary Output

### Trigger
`HandleCompletion()` called when: `done == true AND outputQueue.IsEmpty AND !completionFired`  
Called from UI timer tick → always on UI thread, no Invoke needed.

### TAG Values
| Condition | TAG |
|-----------|-----|
| `State.Cancelled` | `CANCELLED` |
| `State.IsDryRun` | `DRY RUN COMPLETE` |
| Normal | `TRANSFER COMPLETE` |

### copiedCount / failedCount Selection
```csharp
int copiedCount = (State.SummaryCopied > 0) ? State.SummaryCopied : State.FilesSeen;
int failedCount = (State.SummaryCopied > 0) ? State.SummaryFailed : State.FailedFiles;
```

### Summary Written to Log (Full + Simplified tabs)

```
[blank line]
══════════ (90 '=' chars)
  {TAG}  ·  {FormatDuration(elapsed)}  ·  exit {code}
  {verdictString}

  COPIED    {copiedCount} file(s)   {FormatBytes(BytesSeen)}[  of {FormatBytes(TotalBytes)} total]
  FAILED    {failedCount} file(s)          [only if > 0]
  SKIPPED   {SummarySkipped} file(s)  (already up-to-date or excluded)  [only if > 0]
  DIRS      {FoldersSeen} new folder(s) created                         [only if > 0]

  {file type breakdown table}

  Log: {CurrentLogFile}
══════════ (90 '=' chars)
```

### Post-Completion Actions (ordered)
1. `statsTimer.Stop()`
2. Set status bar text + color from exit code verdict
3. Force `prog.Bar.Value = 100` if `exit <= 7`
4. Update `prog.Detail.Text`
5. If successful and not cancelled: `SystemSounds.Asterisk.Play()`
6. If `OpenDestWhenDone` && dest exists: `Process.Start("explorer.exe", dest)`
7. `RecentsStore.Add("SOURCE", src)` and `RecentsStore.Add("DESTINATION", dest)`
8. Save all settings to `settings.json`
9. `State.LastDest = dst.Text`
10. `Set-MavButtonReady(btnGo, true); Set-MavButtonReady(btnDryRun, true)`
11. `Set-MavButtonReady(btnPause, false); Set-MavButtonReady(btnCancel, false)`
12. `btnPause.Text = "⏸ Pause"`
13. `Set-MavButtonReady(btnOpenDest, Directory.Exists(dst.Text))`
14. `form.Cursor = Cursors.Default`
15. Dispose `Process` object

---

## 21. Robocopy Exit Code Interpretation

| Exit Code | Verdict String | Color | Triggers Sound + OpenDest |
|-----------|---------------|-------|--------------------------|
| 0 | `Already in sync — nothing to copy.` | Warn | No |
| 1 | `Files copied successfully.` | Good | **Yes** |
| 2 | `Done — extra files exist in destination.` | Warn | Yes |
| 3 | `Files copied + extras in destination.` | Good | Yes |
| 4–7 | `Done with some mismatches/extras (exit N).` | Warn | Yes |
| ≥ 8 | `FAILED (exit N).` | Bad | No |

---

## 22. Log Files & Paths

| File | Full Path | Created By |
|------|-----------|-----------|
| Transfer log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\logs\\transfer-{yyyyMMdd-HHmmss}.log` | New file per run via SetLogFile |
| Crash log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\crash.log` | Appended on any unhandled exception |
| Sessions log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\sessions.log` | Appended at every app launch (first line of code) |
| Booster log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\booster.log` | Watch-Transfers.ps1 — INFO/WARN/ERROR lines |
| Boost rc logs | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\logs\\boost-{yyyyMMdd-HHmmss}.log` | Per boost invocation |
| Settings | `%APPDATA%\\Mavericks-RoboCopy\\settings.json` | On every completed transfer |
| Recents | `%APPDATA%\\Mav-AppTemplate\\recents.json` | On browse/Leave/select events |

**Sessions log format:** `{yyyy-MM-dd HH:mm:ss}  PID={n}  PSv={ver}  exe={path}`

---

## 23. Crash Logging

**Sessions log** written as the **absolute first action** on launch — before exception handlers, before UI init. Proves the process launched even when it dies silently.

### C# Equivalent Setup

```csharp
// In Main() before anything else:
var sessLog = Path.Combine(Environment.GetFolderPath(
    Environment.SpecialFolder.LocalApplicationData),
    "Mavericks-RoboCopy", "sessions.log");
Directory.CreateDirectory(Path.GetDirectoryName(sessLog));
File.AppendAllText(sessLog,
    $"{DateTime.Now:yyyy-MM-dd HH:mm:ss}  PID={Environment.ProcessId}\n");

// Exception handlers:
Application.ThreadException += (s, e) => LogCrash("UI thread", e.Exception);
AppDomain.CurrentDomain.UnhandledException += (s, e) =>
    LogCrash("AppDomain", e.ExceptionObject as Exception);
```

### Crash Log Format

```
=== {yyyy-MM-dd HH:mm:ss} · {where} ===
{ExceptionType.FullName}: {Message}
{StackTrace}

```

**Show MessageBox** after writing crash log (user sees path to the log file).  
**Do NOT re-throw** — stops cascading null-reference echoes of the first real error.

---

## 24. Console-Run.ps1 — CLI Differences

A CLI-only robocopy wrapper for testing the transfer logic without WinForms.

| Aspect | GUI (Mavericks-RoboCopy.ps1) | CLI (Console-Run.ps1) |
|--------|------------------------------|----------------------|
| WinForms | Yes | **No** |
| Settings.json | Read + write | **None** |
| `/BYTES` flag | Always added | **Not added** |
| Process launch | Async + ConcurrentQueue | Direct blocking call |
| Output routing | Log tabs + color | **stdout only** |
| Live stats | Yes | **No** |
| Progress bar | Yes | **No** |
| Log files | Yes | **No** |
| Pre-scan | Always | **No** |
| ETA | Yes | **No** |

**CLI Parameters:**

```
-Source         (Mandatory) string
-Destination    (Mandatory) string
-Mode           Copy | Move | Mirror  (default: Copy)
-Threads        int    (default: 16)
-Subdirs        switch
-VerboseLog     switch
-Restartable    switch
-DryRun         switch
-Excludes       string  (comma/semicolon separated)
-Days           int    (default: 0)
-IPG            int    (default: 0)
```

**Output:** Prints full `robocopy` command in cyan before executing. After exit, prints verdict in green (exit ≤ 7) or red (exit > 7).

---

## 25. Watch-Transfers.ps1 — Auto-Booster Service

**Role:** Standalone background service (installed via scheduled task on user login).  
**Script:** `tools/Watch-Transfers.ps1`

### Main Poll Loop (default: every 30 seconds)

```
1. If a boost process is running: check if HasExited; if done, reset state.
2. Skip if any robocopy.exe process is already running (GUI is active).
3. Detect signals:
   a. WMI PerfCounter: drives writing > ThresholdMBps (default 10 MB/s)
      -> hotDrives = list of drive letters above threshold
   b. EnumWindows over explorer.exe PIDs: any visible title matching
      ^(Copying|Moving|File Operation)
      -> dialogPresent = true/false
4. signalActive = (hotDrives.Count > 0) OR dialogPresent
5. IF signalActive:
     pendingCount++
     IF pendingCount >= 2 (two consecutive polls = confirmed):
       a. Read LastSource/LastDest from settings.json
       b. destDrive = Path.GetPathRoot(LastDest).TrimEnd('\\').ToUpper()
       c. driveMatches = (hotDrives.Count == 0) OR (destDrive in hotDrives)
       d. IF driveMatches AND Directory.Exists(LastSource):
            Launch robocopy boost
            Send toast notification
       e. ELSE: Send toast "Large Transfer Detected — Open Mavericks-RoboCopy"
       f. pendingCount = 0
6. IF no signal: reset pendingCount = 0
```

### Boost Robocopy Args

```
robocopy.exe {src} {dst} /E /MT:16 /R:0 /W:0 /NP /BYTES /TEE /UNILOG+:{boostLogFile}
```

**Note:** `/R:0 /W:0` = no retries (skip locked files immediately). Unlike the main app's `/R:1 /W:1`.

### Win32 Interop (user32.dll)

```csharp
[DllImport("user32.dll")] bool EnumWindows(EnumWindowsProc fn, IntPtr lp);
[DllImport("user32.dll")] int GetWindowText(IntPtr h, StringBuilder s, int n);
[DllImport("user32.dll")] uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll")] bool IsWindowVisible(IntPtr h);
```

Enumerate all visible windows of all `explorer.exe` PIDs, collect titles matching `^(Copying|Moving|File Operation)`.

### Toast Notification

Uses Windows Runtime `Windows.UI.Notifications.ToastNotificationManager`.  
Best-effort — wrapped in try/catch, silently swallowed on failure.

---

## 26. Reset-State.ps1 — Test Cleanup Tool

**Usage:**
```
.\Reset-State.ps1               # wipe logs + settings
.\Reset-State.ps1 -KeepSettings # wipe logs only
```

**Files deleted:**
- `%LOCALAPPDATA%\\Mavericks-RoboCopy\\crash.log`
- `%LOCALAPPDATA%\\Mavericks-RoboCopy\\sessions.log`
- `%LOCALAPPDATA%\\Mavericks-RoboCopy\\logs\\*` (all transfer logs)
- `%APPDATA%\\Mavericks-RoboCopy\\settings.json` (unless `-KeepSettings`)

---

## 27. Tests (Pester) — Behaviors Verified

**Runner:** `Invoke-Pester tests\Mavericks-RoboCopy.Tests.ps1 -Output Detailed`

Tests use an inline `Build-RobocopyArgsTest` function (identical to `Console-Run.ps1`). No GUI or module dependency required.

### Describe: Build-RobocopyArgs

| Test | Assertion |
|------|-----------|
| Safety flags | `/R:1`, `/W:1`, `/NP`, `/TEE` always present |
| Strip trailing `\` from source | `args[0]` = path without `\` |
| Strip trailing `\` from destination | `args[1]` = path without `\` |
| Subdirs=true | `/E` present |
| Subdirs=false | `/E` absent |
| Thread count N=8 | `/MT:8` present |
| Mirror mode | `/MIR` present, `/MOV` absent |
| Move mode | `/MOV` present, `/MIR` absent |
| Copy mode | Neither `/MIR` nor `/MOV` |
| DryRun | `/L` present |
| Verbose | `/V` present |
| Days=7 | `/MAXAGE:7` present |
| Plain excludes `.git,node_modules` | `/XD` present, `.git` and `node_modules` present |
| Wildcard excludes `*.tmp,*.log` | `/XF` present, `*.tmp` present |

### Describe: Console-Run.ps1 integration

| Test | Assertion | Skip Condition |
|------|-----------|----------------|
| Copy between real test folders in dry-run mode | `$LASTEXITCODE -le 7` | Skipped unless `C:\Users\ACER\Desktop\testfolder-1` exists |

---

## 28. Recent Paths Store

**File:** `%APPDATA%\Mav-AppTemplate\recents.json`  
**Shared** across all apps using the Mav-AppTemplate framework (by design).

**JSON format:**
```json
{
  "SOURCE":      ["C:\\Users\\...\\Documents", "D:\\backup"],
  "DESTINATION": ["E:\\Archive"]
}
```

| Rule | Detail |
|------|--------|
| Max entries per bucket | 12 (oldest entries trimmed) |
| Deduplication | Case-insensitive; duplicate moved to front |
| Write triggers | Browse dialog OK, TextBox Leave (if path on disk), Recent menu click, transfer completion |
| Load error handling | Corrupt/missing JSON → return empty dict, no exception thrown |
| Encoding | UTF-8 |

---

## 29. DPI Awareness Setup

Must be called **before** any Form is instantiated, or Windows bitmap-scales the UI (blurry).

```csharp
// user32.dll — Per-Monitor V2 (Windows 10+, preferred)
[DllImport("user32.dll")]
static extern bool SetProcessDpiAwarenessContext(IntPtr ctx);
// ctx = new IntPtr(-4)  // DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2

// shcore.dll — Per-Monitor (Windows 8.1+, fallback)
[DllImport("shcore.dll")]
static extern int SetProcessDpiAwareness(int awareness);
// awareness = 2  // PROCESS_PER_MONITOR_DPI_AWARE

// user32.dll — belt-and-suspenders
[DllImport("user32.dll")]
static extern bool SetProcessDPIAware();
```

**Invocation order:**
1. Try `SetProcessDpiAwarenessContext(new IntPtr(-4))` — catch silently
2. If failed: try `SetProcessDpiAwareness(2)` — catch silently
3. Always call `SetProcessDPIAware()` — catch silently
4. `Application.EnableVisualStyles()`
5. `Application.SetCompatibleTextRenderingDefault(false)`

---

## 30. C# Rewrite — Component Checklist

### Core Services
- [ ] **SettingsManager** — Load/Save `settings.json`; 9 keys (§2); graceful fallback on corrupt JSON
- [ ] **RecentsStore** — `recents.json`; bucket-based; max 12; case-insensitive dedup; UTF-8
- [ ] **CrashLogger** — sessions.log on startup (absolute first); crash.log on unhandled exceptions
- [ ] **FormatHelpers** — `FormatBytes(long)` (B/KB/MB/GB/TB, N1/N2) + `FormatDuration(TimeSpan)` (M:SS or H:MM:SS)

### Process Infrastructure
- [ ] **RobocopyArgBuilder** — static; inputs per §8; `/BYTES` flag only for GUI build; shared by GUI and CLI
- [ ] **PreScanner** — sync call; `robocopy NUL /L /E /NFL /NJH /R:0 /W:0 /BYTES`; parse Files/Bytes; returns `(int, long)`
- [ ] **RobocopyRunner** — `ProcessStartInfo` setup; async stdout/stderr via `BeginOutputReadLine`; `ConcurrentQueue<string>` bridge to UI timer
- [ ] **ProcessSuspender** — `NtSuspendProcess`/`NtResumeProcess` P/Invoke to ntdll.dll (§16)

### Output Parsing
- [ ] **OutputParser.ColorForLine(string)** — returns `Color` per §9.1
- [ ] **OutputParser.ChannelsForLine(string)** — returns `string[]` per §9.2
- [ ] **OutputParser.UpdateStats(string, State)** — all 4 patterns per §9.3
- [ ] **OutputParser.ParseSize(string)** — k/m/g suffix multiplier per §9.5

### UI — Theme & Infrastructure
- [ ] **DPI setup** — before any Form (§29)
- [ ] **InfernoTheme** — 17 color properties (§6)
- [ ] **FontSet** — 6 Font objects (§7)
- [ ] **SoftDisable helper** — `SetButtonReady(Button, bool)` — No cursor + 50% color dim

### UI — Controls
- [ ] **MainForm** — 1280×1280; dark background; header with AccentDim→Lava glow; status strip; button bar
- [ ] **PathRow** (×2) — TextBox (Mono font, drag-drop) + Browse (IFileOpenDialog + fallback) + Recent (ContextMenuStrip)
- [ ] **ModeSelector** — 3 RadioButtons; Move + Mirror destructive confirmation MessageBox
- [ ] **OptionsPanel** — Threads NumericUpDown (1–128) + 3 CheckBoxes
- [ ] **FiltersPanel** — Excludes TextBox + Days NumericUpDown + IPG NumericUpDown
- [ ] **PostPanel** — OpenDest CheckBox
- [ ] **StatsRow** — 6 caption/value pairs; Consolas 11pt Bold; Ember color
- [ ] **ProgressRow** — ProgressBar (Continuous) + detail Label
- [ ] **TabbedLogPanel** — 4 RichTextBoxes (Full/Simplified/Warnings/Errors); tab count badges; disk append; Export button
- [ ] **ButtonBar** — 8 buttons with initial states per §4.11; soft-disable support

### Transfer Logic
- [ ] **EtaCalculator** — Initial heuristic (§12) + live formula
- [ ] **SpeedSampler** — rolling 6-sample window (§13)
- [ ] **StatsTimer** — 300ms `System.Windows.Forms.Timer`; drains ConcurrentQueue; triggers completion handler
- [ ] **FileTypeTracker** — `ExtCounts`, `ExtBytes`, `ExtFailed` dictionaries (§19)
- [ ] **CompletionHandler** — TAG selection; copiedCount/failedCount selection; summary log; post-actions in order (§20)
- [ ] **FormClosingGuard** — prompt if transfer running; resume-then-kill if paused

### Satellite Components (optional C# ports)
- [ ] **ConsoleCLI** — per §24; same arg builder; blocking `Process.Start`; no forms
- [ ] **TransferBooster** — per §25; `EnumWindows` + perf counter; 2-poll confirmation; toast
- [ ] **ResetStateCLI** — per §26; file deletion utility

---

*Specification generated 2026-04-27 from direct source analysis of all files in `maverickmackten-eng/Mavericks-RoboCopy`.*
