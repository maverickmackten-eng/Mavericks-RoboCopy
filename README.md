# Mavericks-RoboCopy

> The robocopy GUI Windows deserves — live log streaming, per-extension file counters, background transfer boosting, and a clean WinForms UI built entirely in PowerShell.

---

## What it is

Mavericks-RoboCopy is a PowerShell/WinForms front-end for `robocopy.exe` that treats file transfers as a first-class operation — not an afterthought. Every file moved is tracked by type, size, and outcome. Logs stream live to tabbed views as the transfer runs. A background booster daemon can silently intercept large Windows Explorer transfers and re-run them with 16 threads before you even notice they were slow.

---

## Features

### Core GUI (`Mavericks-RoboCopy.ps1`)
- **Live log streaming** — output appears line-by-line via a background PS runspace + `ConcurrentQueue`, no polling lag
- **Four log tabs** — Full / Simplified / Warnings / Errors, each filtered automatically
- **Copy · Move · Mirror modes** with dry-run, restartable (`/Z`), subdirectory, verbose, IPG throttle, and exclude pattern options
- **Pre-scan** — byte count + file count before the transfer starts so you see ETA immediately
- **Live stats panel** — files transferred, bytes moved, elapsed time, current speed (MB/s), ETA
- **Top-15 file type breakdown** on completion — per extension: files moved + bytes moved
- **Failed file tracking** — counts and groups failures by extension
- **Robocopy summary reconciliation** — uses robocopy's own `Files :` summary line as the authoritative count, not just regex matches
- **Recent paths** — last 5 source/dest pairs remembered and repopulated on next launch
- **Toast notification** on transfer completion
- **Open destination on finish** checkbox
- **Session + crash logging** — `sessions.log` written before anything else; `crash.log` captures every uncaught exception with full stack trace

### Transfer Booster (`tools/Watch-Transfers.ps1`)
- Runs as a Windows Task Scheduler startup task — totally invisible
- Polls every 30 seconds for write throughput above 10 MB/s on any local drive
- Also watches for Windows Explorer copy/move dialog windows via Win32 `EnumWindows`
- **Two consecutive confirmations required** before acting — avoids false positives
- Reads `LastSource` / `LastDest` from `settings.json`, verifies the destination drive letter matches the hot drive
- Launches `robocopy /MT:16 /E /R:0 /W:0` silently in the background
- Sends a Windows toast so you know it fired
- Logs everything to `%LOCALAPPDATA%\Mavericks-RoboCopy\booster.log`

### Mav-AppTemplate Framework (`Mav-AppTemplate.psm1`)
Custom PowerShell module (~2,800 lines) that provides the layout primitives the app uses. Handles DPI scaling, theming, dock order, and WinForms boilerplate so the app script stays focused on logic.

---

## Project layout

```
Mavericks-RoboCopy/
├── Mavericks-RoboCopy.ps1        # Main app — logic, event handlers, robocopy invocation
├── Mavericks-RoboCopy.cmd        # Launcher (add -Diag flag for visible debug window)
├── Mavericks-RoboCopy.vbs        # Silent launcher (double-click from Explorer)
├── Mav-AppTemplate.psm1          # Layout framework module
├── Mav-AppTemplate.psd1          # Module manifest
├── verify-layout.ps1             # Window layout smoke test
│
├── tools/
│   ├── Watch-Transfers.ps1       # Transfer Booster daemon
│   ├── Install-TransferBooster.ps1   # Register booster as Task Scheduler startup task
│   ├── Remove-TransferBooster.ps1    # Unregister + kill all booster processes
│   ├── Console-Run.ps1           # CLI front-end — same logic as GUI, no WinForms
│   ├── Run-Diag.cmd              # Visible-window debug launcher (shows PS errors live)
│   ├── Test-ModuleHealth.ps1     # Checks every Mav-AppTemplate export is recognized
│   ├── Smoke-Run.ps1             # Launches app, captures window PNG, asserts no crashes
│   ├── Tail-CrashLog.ps1         # Live tail of crash.log for a second terminal
│   └── Reset-State.ps1           # Wipes settings.json + logs for a clean test run
│
└── tests/
    ├── Mavericks-RoboCopy.Tests.ps1  # Pester tests for robocopy argument builder
    └── Mav-AppTemplate.Tests.ps1     # Pester tests for framework export contracts
```

---

## Requirements

| Requirement | Notes |
|---|---|
| Windows 10 / 11 | WinForms + Task Scheduler |
| PowerShell 5.1+ | 7+ recommended (`pwsh.exe`) |
| `robocopy.exe` | Included in Windows — no install needed |
| Pester 5+ | For running tests only — `Install-Module Pester` |

No external dependencies. No NuGet packages. No install wizard. Drop the folder, run the `.cmd`.

---

## Quick start

```powershell
# 1. Clone
git clone https://github.com/maverickmackten-eng/Mavericks-RoboCopy.git
cd Mavericks-RoboCopy

# 2. Launch (visible debug window — recommended for first run)
.\tools\Run-Diag.cmd

# 3. Or launch silently
.\Mavericks-RoboCopy.cmd

# 4. Verify the framework is healthy before iterating
.\tools\Test-ModuleHealth.ps1
```

---

## Transfer Booster — install / remove

```powershell
# Install (run as Administrator — Task Scheduler requires elevation)
.\tools\Install-TransferBooster.ps1

# Remove
.\tools\Remove-TransferBooster.ps1
```

After install, the booster starts at every login and runs invisibly. When it fires, a toast notification appears and the action is logged to `%LOCALAPPDATA%\Mavericks-RoboCopy\booster.log`.

---

## CLI usage (no GUI)

```powershell
# Basic copy
.\tools\Console-Run.ps1 -Source C:\Users\You\Documents -Destination F:\Backup

# Mirror with dry-run first
.\tools\Console-Run.ps1 -Source C:\src -Destination D:\dst -Mode Mirror -DryRun

# Copy subdirectories, 8 threads, exclude temp files
.\tools\Console-Run.ps1 -Source C:\src -Destination D:\dst -Subdirs -Threads 8 -Excludes "*.tmp,*.log"
```

---

## Running tests

```powershell
# Robocopy argument builder — 15 tests, no file system access needed
Invoke-Pester tests\Mavericks-RoboCopy.Tests.ps1 -Output Detailed

# Framework module export contracts
Invoke-Pester tests\Mav-AppTemplate.Tests.ps1 -Output Detailed
```

---

## Logs and diagnostics

| Log | Location | Contains |
|---|---|---|
| Session starts | `%LOCALAPPDATA%\Mavericks-RoboCopy\sessions.log` | Every launch — PID, PS version, timestamp |
| Crash log | `%LOCALAPPDATA%\Mavericks-RoboCopy\crash.log` | Uncaught exceptions with stack traces |
| Transfer logs | `%LOCALAPPDATA%\Mavericks-RoboCopy\logs\` | Per-run robocopy output |
| Booster log | `%LOCALAPPDATA%\Mavericks-RoboCopy\booster.log` | Every Transfer Booster poll + action |

```powershell
# Watch crash.log live in a second terminal
.\tools\Tail-CrashLog.ps1

# Wipe all state for a clean test run
.\tools\Reset-State.ps1
```

---

## Robocopy exit codes

| Code | Meaning |
|---|---|
| 0 | Already in sync — nothing copied |
| 1 | Files copied successfully |
| 2 | Done — extra files exist in destination |
| 3 | Files copied + extras in destination |
| 4–7 | Done with mismatches / extras (check output) |
| 8+ | One or more files failed to copy |

---

## License

MIT — see [LICENSE](LICENSE).
