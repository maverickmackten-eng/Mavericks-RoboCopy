@echo off
REM  Run-Diag.cmd — visible-window diagnostic launcher
REM  Use this during iteration so errors appear on screen instead of dying silently.
REM  Close the window manually when done.

where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
    pwsh.exe -NoProfile -Sta -NoExit -ExecutionPolicy Bypass -File "%~dp0..\Mavericks-RoboCopy.ps1"
) else (
    powershell.exe -NoProfile -Sta -NoExit -ExecutionPolicy Bypass -File "%~dp0..\Mavericks-RoboCopy.ps1"
)
