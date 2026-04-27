#Requires -Version 5.1
# Smoke-Run.ps1 — automated "does the window appear" test.
# Launches the app, waits up to $WaitSeconds for the main window,
# captures a PNG screenshot, kills it, checks for new crash entries.
# Exit 0 = PASS, 1 = FAIL.

param(
    [string]$ScriptPath  = "$PSScriptRoot\..\Mavericks-RoboCopy.ps1",
    [string]$OutPng      = "$env:TEMP\maverick-smoke.png",
    [int]$WaitSeconds    = 10
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient

if (-not ('Mav.Win32Smoke' -as [type])) {
    Add-Type -Namespace Mav -Name Win32Smoke -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool GetWindowRect(System.IntPtr hWnd, out RECT lpRect);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool PrintWindow(System.IntPtr hwnd, System.IntPtr hdcBlt, uint nFlags);
[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
'@
}

$crashLog    = "$env:LOCALAPPDATA\Mavericks-RoboCopy\crash.log"
$crashBefore = if (Test-Path $crashLog) { (Get-Item $crashLog).LastWriteTime } else { $null }

$psExe = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
Write-Host "Launching via $psExe ..." -ForegroundColor Cyan

$proc = Start-Process $psExe -PassThru -WindowStyle Normal -ArgumentList @(
    '-NoProfile', '-Sta', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath
)

Write-Host "PID $($proc.Id) — polling for window (up to $WaitSeconds s)..."
$win = $null; $tries = 0
while (-not $win -and $tries -lt ($WaitSeconds * 2)) {
    Start-Sleep -Milliseconds 500; $tries++
    $proc.Refresh()
    if ($proc.HasExited) { Write-Host "FAIL: process exited early (exit $($proc.ExitCode))" -ForegroundColor Red; exit 1 }
    if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
        try { $win = [System.Windows.Automation.AutomationElement]::FromHandle($proc.MainWindowHandle) } catch {}
    }
}

$passed = $true

if ($win) {
    Write-Host "Window found. Capturing screenshot..." -ForegroundColor Green
    $hwnd = [IntPtr]$win.Current.NativeWindowHandle
    $rect = New-Object Mav.Win32Smoke+RECT
    [void][Mav.Win32Smoke]::GetWindowRect($hwnd, [ref]$rect)
    $w = $rect.Right - $rect.Left; $h = $rect.Bottom - $rect.Top
    $bmp = New-Object System.Drawing.Bitmap ([Math]::Max(1,$w)), ([Math]::Max(1,$h))
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    [void][Mav.Win32Smoke]::PrintWindow($hwnd, $hdc, 2)
    $g.ReleaseHdc($hdc); $g.Dispose()
    $bmp.Save($OutPng)
    $bmp.Dispose()
    Write-Host "Screenshot → $OutPng" -ForegroundColor Green
} else {
    Write-Host "FAIL: no window appeared in $WaitSeconds s" -ForegroundColor Red
    $passed = $false
}

if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }

$crashAfter = if (Test-Path $crashLog) { (Get-Item $crashLog).LastWriteTime } else { $null }
if ($crashAfter -and (-not $crashBefore -or $crashAfter -gt $crashBefore)) {
    Write-Host "FAIL: crash.log was written during this run:" -ForegroundColor Red
    Get-Content $crashLog | Select-Object -Last 30
    $passed = $false
}

if ($passed) {
    Write-Host "`nPASS: window rendered, no crashes logged." -ForegroundColor Green
    exit 0
} else {
    exit 1
}
