@echo off
REM  Pass -Diag as the first arg to run in a visible console with -NoExit
REM  so errors are readable: Mavericks-RoboCopy.cmd -Diag
if /I "%~1"=="-Diag" goto diag

REM ═════════════════════════════════════════════════════════════════════
REM   Mavericks-RoboCopy.cmd  —  GUI launcher
REM   ─────────────────────────────────────────────────────────────────
REM   Spawns the WinForms app via PowerShell. Prefers pwsh.exe
REM   (PowerShell 7+) when available — it has the modern Windows
REM   folder picker built in. Falls back to powershell.exe (Windows
REM   PowerShell 5.1) — the .ps1 P/Invokes IFileOpenDialog directly
REM   so the modern picker still appears either way.
REM
REM   Args (drag a folder onto the .lnk shortcut → fills Source):
REM     %~1 = source path, %~2 = destination path
REM
REM   -Sta:                 needed for Windows Forms dialogs
REM   -WindowStyle Hidden:  no PowerShell console behind the GUI
REM   -ExecutionPolicy Bypass:  per-invocation only
REM ═════════════════════════════════════════════════════════════════════

where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
    start "" /b pwsh.exe -NoProfile -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0Mavericks-RoboCopy.ps1" -Source "%~1" -Destination "%~2"
) else (
    start "" /b powershell.exe -NoProfile -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0Mavericks-RoboCopy.ps1" -Source "%~1" -Destination "%~2"
)
goto :eof

:diag
where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
    pwsh.exe -NoProfile -Sta -NoExit -ExecutionPolicy Bypass -File "%~dp0Mavericks-RoboCopy.ps1"
) else (
    powershell.exe -NoProfile -Sta -NoExit -ExecutionPolicy Bypass -File "%~dp0Mavericks-RoboCopy.ps1"
)
