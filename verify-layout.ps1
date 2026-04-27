# Layout self-verification — launches the actual app process, waits
# for the window to render, captures a PNG screenshot of just that
# window, walks all controls via UIAutomation, and reports overlaps.
#
# This is how I check my own work. No need for the user to look at the
# GUI and tell me what's wrong; the captured PNG and the overlap log
# tell me directly.

param(
    [string]$ScriptPath = "$PSScriptRoot\Mavericks-RoboCopy.ps1",
    [string]$OutPng     = "$env:TEMP\maverick-layout.png",
    [string]$OutLog     = "$env:TEMP\maverick-layout.log",
    [int]$WaitSeconds   = 4
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient

# Win32 — we need GetWindowRect + PrintWindow to capture just our app's
# window without grabbing the whole desktop.
if (-not ('Mav.Win32' -as [type])) {
    Add-Type -Namespace Mav -Name Win32 -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool GetWindowRect(System.IntPtr hWnd, out RECT lpRect);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool PrintWindow(System.IntPtr hwnd, System.IntPtr hdcBlt, uint nFlags);
[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
'@ -PassThru | Out-Null
}

# Launch the real app — Normal window style so MainWindowHandle is set
$proc = Start-Process powershell.exe -PassThru -WindowStyle Normal -ArgumentList @(
    '-NoProfile','-Sta','-ExecutionPolicy','Bypass',
    '-File', $ScriptPath
)
Start-Sleep -Seconds $WaitSeconds

# Find the window via the process's MainWindowHandle — survives the
# Opacity=0 fade-in window where UIA's by-name lookup misses the form.
$win = $null
$tries = 0
while (-not $win -and $tries -lt 16) {
    $proc.Refresh()
    if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
        $win = [System.Windows.Automation.AutomationElement]::FromHandle($proc.MainWindowHandle)
    }
    if (-not $win) { Start-Sleep -Milliseconds 500 }
    $tries++
}

if (-not $win) {
    "FAIL: window 'Mavericks-RoboCopy' not found after ${WaitSeconds}s wait" | Set-Content -Path $OutLog
    Write-Host "FAIL: app didn't render in time" -ForegroundColor Red
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    exit 1
}

$hwnd = [IntPtr]$win.Current.NativeWindowHandle

# Capture the window pixels via PrintWindow (cleaner than screen-grab)
$rect = New-Object Mav.Win32+RECT
[void][Mav.Win32]::GetWindowRect($hwnd, [ref]$rect)
$w = $rect.Right - $rect.Left
$h = $rect.Bottom - $rect.Top
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[void][Mav.Win32]::PrintWindow($hwnd, $hdc, 2)   # 2 = PW_RENDERFULLCONTENT (incl. UWP layered)
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# Walk every UIAutomation element under the window and check for any
# pair of siblings whose bounding rectangles overlap.
$log = New-Object System.Collections.ArrayList
[void]$log.Add("Window bounds: $($win.Current.BoundingRectangle)")
[void]$log.Add("Render saved:  $OutPng")
[void]$log.Add('')

function Walk-Element($el, $depth) {
    $kids = @()
    $first = [System.Windows.Automation.TreeWalker]::ControlViewWalker.GetFirstChild($el)
    while ($first) {
        $kids += $first
        $first = [System.Windows.Automation.TreeWalker]::ControlViewWalker.GetNextSibling($first)
    }
    return $kids
}

$overlaps = @()
function Check-Overlaps($el, $depth, $ancestorPath) {
    $kids = Walk-Element $el $depth
    for ($i = 0; $i -lt $kids.Count; $i++) {
        for ($j = $i+1; $j -lt $kids.Count; $j++) {
            $a = $kids[$i].Current.BoundingRectangle
            $b = $kids[$j].Current.BoundingRectangle
            if ($a.Width -gt 0 -and $b.Width -gt 0) {
                # IntersectsWith
                if (-not ($a.Right -le $b.Left -or $b.Right -le $a.Left -or $a.Bottom -le $b.Top -or $b.Bottom -le $a.Top)) {
                    $script:overlaps += "[${ancestorPath}] '$($kids[$i].Current.Name)' (${a}) ∩ '$($kids[$j].Current.Name)' (${b})"
                }
            }
        }
        Check-Overlaps $kids[$i] ($depth+1) ("$ancestorPath/$($kids[$i].Current.Name)")
    }
}
Check-Overlaps $win 0 'Form'

if ($overlaps.Count -eq 0) {
    [void]$log.Add('PASS: no sibling overlaps detected in the UIAutomation tree.')
} else {
    [void]$log.Add("FAIL: $($overlaps.Count) overlap(s):")
    foreach ($o in $overlaps) { [void]$log.Add("  $o") }
}

[void]$log.Add('')
[void]$log.Add('Full UIA tree (depth-first):')
function Dump-Tree($el, $depth) {
    $kids = Walk-Element $el $depth
    foreach ($k in $kids) {
        $r = $k.Current.BoundingRectangle
        $name = $k.Current.Name
        if ($name.Length -gt 50) { $name = $name.Substring(0, 47) + '...' }
        [void]$log.Add(("{0}'{1}' [{2}] y={3} h={4}" -f
            ('  ' * $depth), $name, $k.Current.ControlType.ProgrammaticName,
            [int]$r.Y, [int]$r.Height))
        Dump-Tree $k ($depth+1)
    }
}
Dump-Tree $win 0

$log -join "`n" | Set-Content -Path $OutLog -Encoding UTF8
Write-Host ($log -join "`n")

# Cleanup
if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
exit ($overlaps.Count -gt 0)
