# =====================================================================
#  Mav-AppTemplate.psm1                                            v1.0
#  -----------------------------------------------------------------
#  WinForms layout framework for fast PowerShell GUI app development.
#
#  WHY THIS EXISTS
#    Every new tool was costing me hours of pixel-arithmetic fighting:
#    DPI scaling, dock z-order, AutoSize labels overflowing rows, etc.
#    This module solves layout ONCE so consumers just declare WHAT they
#    want — title, sections, buttons, click handlers — and never type
#    a `Location` or `Size` themselves.
#
#  WHAT YOU GET
#    • Initialize-MavApp     — DPI awareness + theme + assemblies
#    • New-MavForm           — form with header/status/button-bar/content
#    • Add-MavPathRow        — labeled folder picker with Recent + Browse
#    • Add-MavRadioGroup     — radio button group with destructive confirms
#    • Add-MavOptionsGroup   — declarative options (checkbox/numeric/etc.)
#    • Add-MavStatsRow       — caption-above-value live stats columns
#    • Add-MavLogPanel       — color-coded scrolling log
#    • Add-MavButtonBar      — bottom button bar with primary/destructive
#    • Set-MavStatus         — bottom-strip status text + color
#    • Set-MavButtonReady    — soft-disable with No cursor + dim text
#    • Pick-FolderModern     — modern Windows folder picker (IFileDialog)
#    • Test-MavLayout        — overlap detector + render capture
#
#  CORE PRINCIPLE
#    Callers never type pixel coordinates. The module owns:
#      - All Location / Size / Margin / Padding values
#      - All Dock / Anchor decisions
#      - All TableLayoutPanel + FlowLayoutPanel construction
#      - All theme application
#      - All DPI-awareness setup
#      - All overlap detection
# =====================================================================

# ─────────────────────────────────────────────────────────────────────
#  Module-scope state — populated by Initialize-MavApp
# ─────────────────────────────────────────────────────────────────────
$script:MavTheme = $null
$script:MavFonts = $null
$script:MavInitialized = $false

# ═════════════════════════════════════════════════════════════════════
#  THEMES
# ═════════════════════════════════════════════════════════════════════
function Get-MavTheme {
    param([string]$Name = 'Inferno')
    switch ($Name) {
        'Inferno' {
            return @{
                Bg          = [System.Drawing.Color]::FromArgb(10, 10, 10)
                BgAlt       = [System.Drawing.Color]::FromArgb(20, 14, 12)
                BgPanel     = [System.Drawing.Color]::FromArgb(28, 18, 16)
                BgPanelHi   = [System.Drawing.Color]::FromArgb(40, 24, 22)
                Border      = [System.Drawing.Color]::FromArgb(80, 24, 18)
                Text        = [System.Drawing.Color]::FromArgb(232, 226, 218)
                TextDim     = [System.Drawing.Color]::FromArgb(140, 124, 116)
                TextFaint   = [System.Drawing.Color]::FromArgb(90, 80, 76)
                Accent      = [System.Drawing.Color]::FromArgb(220, 38, 38)
                AccentDim   = [System.Drawing.Color]::FromArgb(140, 24, 24)
                Lava        = [System.Drawing.Color]::FromArgb(255, 87, 34)
                Ember       = [System.Drawing.Color]::FromArgb(255, 138, 30)
                Flame       = [System.Drawing.Color]::FromArgb(255, 200, 60)
                Char        = [System.Drawing.Color]::FromArgb(58, 28, 24)
                Good        = [System.Drawing.Color]::FromArgb(120, 200, 100)
                Warn        = [System.Drawing.Color]::FromArgb(230, 180, 80)
                Bad         = [System.Drawing.Color]::FromArgb(230, 80, 80)
            }
        }
        default { throw "Unknown theme: $Name" }
    }
}

function Get-MavFonts {
    return @{
        UI        = New-Object System.Drawing.Font('Segoe UI', 9)
        UIB       = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
        UITitle   = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
        UISub     = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Italic)
        Mono      = New-Object System.Drawing.Font('Consolas', 9)
        Stat      = New-Object System.Drawing.Font('Consolas', 11, [System.Drawing.FontStyle]::Bold)
    }
}

# ═════════════════════════════════════════════════════════════════════
#  INITIALIZATION
# ═════════════════════════════════════════════════════════════════════
function Initialize-MavApp {
    [CmdletBinding()]
    param(
        [string]$Theme = 'Inferno'
    )
    if ($script:MavInitialized) { return }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName Microsoft.VisualBasic

    # DPI awareness — must run BEFORE any window is created so Windows
    # doesn't bitmap-scale us (which makes everything blurry).
    if (-not ('Mav.DPIShim' -as [type])) {
        Add-Type -Namespace 'Mav' -Name 'DPIShim' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError=true)]
public static extern bool SetProcessDPIAware();
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError=true)]
public static extern bool SetProcessDpiAwarenessContext(System.IntPtr dpiContext);
[System.Runtime.InteropServices.DllImport("shcore.dll")]
public static extern int SetProcessDpiAwareness(int awareness);
'@ -ErrorAction SilentlyContinue
    }
    $ok = $false
    try { $ok = [Mav.DPIShim]::SetProcessDpiAwarenessContext([IntPtr]::new(-4)) } catch {}
    if (-not $ok) { try { [void][Mav.DPIShim]::SetProcessDpiAwareness(2) } catch {} }
    try { [void][Mav.DPIShim]::SetProcessDPIAware() } catch {}

    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

    # IFileOpenDialog wrapper for the modern Windows folder picker
    if (-not ('MavFP.Picker' -as [type])) {
        $picker = @'
using System;
using System.Runtime.InteropServices;
namespace MavFP {
    [ComImport, Guid("DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7")] public class FOD { }
    [ComImport, Guid("42f85136-db7e-439c-85f1-e4075d135fc8"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IFD {
        [PreserveSig] int Show(IntPtr o);
        void __SetFileTypes(); void __SetFileTypeIndex(); void __GetFileTypeIndex();
        void __Advise(); void __Unadvise();
        void SetOptions(uint fos);
        void __GetOptions(); void __SetDefaultFolder();
        void SetFolder([MarshalAs(UnmanagedType.Interface)] ISI psi);
        void __GetFolder(); void __GetCurrentSelection();
        void __SetFileName(); void __GetFileName();
        void SetTitle([MarshalAs(UnmanagedType.LPWStr)] string title);
        void __SetOkButtonLabel(); void __SetFileNameLabel();
        [PreserveSig] int GetResult([MarshalAs(UnmanagedType.Interface)] out ISI ppsi);
    }
    [ComImport, Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ISI {
        void __BindToHandler(); void __GetParent();
        void GetDisplayName(uint sigdnName, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
    }
    public static class Picker {
        [DllImport("shell32.dll", CharSet = CharSet.Auto)]
        static extern int SHCreateItemFromParsingName(
            [MarshalAs(UnmanagedType.LPWStr)] string path, IntPtr pbc,
            [In] ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out ISI ppv);
        public static string PickFolder(IntPtr ownerHwnd, string title, string initialDir) {
            var dlg = (IFD)new FOD();
            dlg.SetOptions(0x20 | 0x40 | 0x8);
            if (!string.IsNullOrEmpty(title)) dlg.SetTitle(title);
            if (!string.IsNullOrEmpty(initialDir) && System.IO.Directory.Exists(initialDir)) {
                ISI si;
                Guid iidISI = new Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe");
                if (SHCreateItemFromParsingName(initialDir, IntPtr.Zero, ref iidISI, out si) == 0) {
                    dlg.SetFolder(si);
                }
            }
            if (dlg.Show(ownerHwnd) != 0) return null;
            ISI res;
            if (dlg.GetResult(out res) != 0) return null;
            string path; res.GetDisplayName(0x80058000, out path);
            return path;
        }
    }
}
'@
        try { Add-Type -TypeDefinition $picker -Language CSharp -ErrorAction Stop } catch {
            Write-Verbose ("Modern picker compile failed; falling back to FolderBrowserDialog. " + $_.Exception.Message)
        }
    }

    $script:MavTheme = Get-MavTheme $Theme
    $script:MavFonts = Get-MavFonts
    $script:MavInitialized = $true
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: modern folder picker (Windows shell IFileOpenDialog)
# ═════════════════════════════════════════════════════════════════════
function Pick-FolderModern {
    [CmdletBinding()]
    param(
        [string]$Title = 'Pick a folder',
        [string]$InitialDir = '',
        $Owner = $null
    )
    $hwnd = if ($Owner -and $Owner.Handle) { $Owner.Handle } else { [IntPtr]::Zero }
    if ('MavFP.Picker' -as [type]) {
        try { return [MavFP.Picker]::PickFolder($hwnd, $Title, $InitialDir) } catch { }
    }
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Title
    if ($InitialDir -and (Test-Path $InitialDir)) { $dlg.SelectedPath = $InitialDir }
    if ($dlg.ShowDialog($Owner) -eq 'OK') { return $dlg.SelectedPath }
    return $null
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Recent paths store (used by Add-MavPathRow's Recent button)
#  -----------------------------------------------------------------
#  Recents are persisted to %APPDATA%\Mav-AppTemplate\recents.json,
#  bucketed by the path-row's Title (e.g., 'SOURCE', 'DESTINATION').
#  Every app using Add-MavPathRow shares the same store, so a folder
#  you used in Mavericks-RoboCopy as a SOURCE shows up next time too.
# ═════════════════════════════════════════════════════════════════════
$script:MavRecentsPath = Join-Path $env:APPDATA 'Mav-AppTemplate\recents.json'

function _Load-MavRecents {
    if (-not (Test-Path $script:MavRecentsPath)) { return @{} }
    try {
        $raw = Get-Content $script:MavRecentsPath -Raw -ErrorAction Stop
        if (-not $raw) { return @{} }
        $h = $raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        if ($null -eq $h) { return @{} }
        return $h
    } catch { return @{} }
}

function _Save-MavRecents([hashtable]$h) {
    $dir = Split-Path -Parent $script:MavRecentsPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    try {
        $h | ConvertTo-Json -Depth 4 | Set-Content -Path $script:MavRecentsPath -Encoding utf8 -ErrorAction Stop
    } catch {
        Write-Verbose "Could not save recents: $($_.Exception.Message)"
    }
}

function Add-MavRecent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Bucket,
        [Parameter(Mandatory)][string]$Path,
        [int]$MaxItems = 12
    )
    if (-not $Path) { return }
    $h = _Load-MavRecents
    $key = $Bucket.ToUpper()
    $existing = @()
    if ($h.ContainsKey($key)) { $existing = @($h[$key]) }
    # Dedupe (case-insensitive) — newest first
    $list = @($Path) + @($existing | Where-Object { $_ -and ($_.ToString().ToLower() -ne $Path.ToLower()) })
    if ($list.Count -gt $MaxItems) { $list = $list[0..($MaxItems - 1)] }
    $h[$key] = $list
    _Save-MavRecents $h
}

function Get-MavRecent {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Bucket)
    $h = _Load-MavRecents
    $key = $Bucket.ToUpper()
    if ($h.ContainsKey($key)) { return @($h[$key]) }
    return @()
}

function Clear-MavRecent {
    [CmdletBinding()]
    param([string]$Bucket = '')
    if ($Bucket) {
        $h = _Load-MavRecents
        $key = $Bucket.ToUpper()
        if ($h.ContainsKey($key)) { $h.Remove($key) }
        _Save-MavRecents $h
    } else {
        _Save-MavRecents @{}
    }
}

# ─────────────────────────────────────────────────────────────────────
#  Internal: button factory with soft-disabled support
# ─────────────────────────────────────────────────────────────────────
function _New-MavBtn {
    param(
        [string]$Text,
        [System.Drawing.Color]$Bg,
        [System.Drawing.Color]$Fg,
        [int]$Width = 130,
        [int]$Height = 36
    )
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Font = $script:MavFonts.UIB
    $b.BackColor = $Bg
    $b.ForeColor = $Fg
    $b.FlatStyle = 'Flat'
    $b.FlatAppearance.BorderColor = $script:MavTheme.Border
    $b.FlatAppearance.BorderSize = 1
    $b.Width = $Width
    $b.Height = $Height
    $b.Cursor = 'Hand'
    $b.Tag = @{ Ready = $true; OriginalFG = $Fg; OriginalBG = $Bg }
    return $b
}

function Set-MavButtonReady {
    [CmdletBinding()]
    param(
        $Button,
        [bool]$Ready
    )
    if (-not $Button.Tag) { return }
    $Button.Tag.Ready = $Ready
    if ($Ready) {
        $Button.ForeColor = $Button.Tag.OriginalFG
        $Button.BackColor = $Button.Tag.OriginalBG
        $Button.Cursor = 'Hand'
    } else {
        $orig = $Button.Tag.OriginalFG
        $Button.ForeColor = [System.Drawing.Color]::FromArgb([int]($orig.R * 0.5), [int]($orig.G * 0.5), [int]($orig.B * 0.5))
        $Button.Cursor = [System.Windows.Forms.Cursors]::No
    }
}

function Get-MavButtonReady {
    param($Button)
    return ($Button.Tag -and $Button.Tag.Ready)
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: New-MavForm — creates the host form with the standard layout
# ═════════════════════════════════════════════════════════════════════
function New-MavForm {
    [CmdletBinding()]
    param(
        [string]$Title = 'My App',
        [string]$Subtitle = '',
        [string]$Version = 'v1.0',
        [string]$IconGlyph = '☠',
        [int]$MinWidth = 1140,
        [int]$MinHeight = 800,
        [int]$Width = 1240,
        [int]$Height = 1000,
        [bool]$AlwaysOnTop = $false,
        [bool]$FadeIn = $true,
        [bool]$ShowAlwaysOnTopToggle = $true
    )
    if (-not $script:MavInitialized) { Initialize-MavApp }
    $T = $script:MavTheme
    $F = $script:MavFonts

    # ── Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$Title — Inferno Edition"
    $form.MinimumSize = New-Object System.Drawing.Size $MinWidth, $MinHeight
    $form.Size = New-Object System.Drawing.Size $Width, $Height
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = $T.Bg
    $form.ForeColor = $T.Text
    $form.Font = $F.UI

    # ── HEADER — TableLayoutPanel: skull|title with subtitle below
    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = 'Top'
    $header.Height = 100
    $header.BackColor = $T.BgAlt

    $tlpHeader = New-Object System.Windows.Forms.TableLayoutPanel
    $tlpHeader.Location = New-Object System.Drawing.Point 16, 14
    $tlpHeader.Size = New-Object System.Drawing.Size 900, 80
    $tlpHeader.ColumnCount = 2
    $tlpHeader.RowCount = 2
    $tlpHeader.BackColor = [System.Drawing.Color]::Transparent
    [void]$tlpHeader.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Absolute', 80))
    [void]$tlpHeader.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'AutoSize'))
    [void]$tlpHeader.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 50))
    [void]$tlpHeader.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 28))
    $header.Controls.Add($tlpHeader)

    $lblIcon = New-Object System.Windows.Forms.Label
    $lblIcon.Text = $IconGlyph
    $lblIcon.Font = $F.UITitle
    $lblIcon.ForeColor = $T.Lava
    $lblIcon.BackColor = [System.Drawing.Color]::Transparent
    $lblIcon.Dock = 'Fill'
    $lblIcon.TextAlign = 'MiddleCenter'
    $tlpHeader.Controls.Add($lblIcon, 0, 0)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title.ToUpper()
    $lblTitle.Font = $F.UITitle
    $lblTitle.ForeColor = $T.Lava
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $lblTitle.AutoSize = $true
    $lblTitle.Margin = '12,0,0,0'
    $tlpHeader.Controls.Add($lblTitle, 1, 0)

    $lblSubtitle = New-Object System.Windows.Forms.Label
    $lblSubtitle.Text = $Subtitle
    $lblSubtitle.Font = $F.UISub
    $lblSubtitle.ForeColor = $T.TextDim
    $lblSubtitle.BackColor = [System.Drawing.Color]::Transparent
    $lblSubtitle.AutoSize = $true
    $lblSubtitle.Margin = '12,0,0,0'
    $tlpHeader.Controls.Add($lblSubtitle, 1, 1)
    $tlpHeader.SetColumnSpan($lblSubtitle, 2)

    $lblVersion = New-Object System.Windows.Forms.Label
    $lblVersion.Text = $Version
    $lblVersion.Font = $F.UIB
    $lblVersion.ForeColor = $T.AccentDim
    $lblVersion.BackColor = [System.Drawing.Color]::Transparent
    $lblVersion.AutoSize = $true
    $lblVersion.Anchor = 'Top, Right'
    $header.Controls.Add($lblVersion)
    $lblVersion.Location = New-Object System.Drawing.Point ($Width - 70), 18

    $chkOnTop = $null
    if ($ShowAlwaysOnTopToggle) {
        $chkOnTop = New-Object System.Windows.Forms.CheckBox
        $chkOnTop.Text = 'Always on top'
        $chkOnTop.Font = $F.UI
        $chkOnTop.ForeColor = $T.TextDim
        $chkOnTop.BackColor = [System.Drawing.Color]::Transparent
        $chkOnTop.AutoSize = $true
        $chkOnTop.Anchor = 'Top, Right'
        $chkOnTop.Checked = $AlwaysOnTop
        $chkOnTop.Add_CheckedChanged({ $form.TopMost = $chkOnTop.Checked }.GetNewClosure())
        $header.Controls.Add($chkOnTop)
        $chkOnTop.Location = New-Object System.Drawing.Point ($Width - 170), 64
        $header.Add_Resize({
            $lblVersion.Location = New-Object System.Drawing.Point ($header.Width - 60), 18
            $chkOnTop.Location = New-Object System.Drawing.Point ($header.Width - 170), 64
        }.GetNewClosure())
    } else {
        $header.Add_Resize({
            $lblVersion.Location = New-Object System.Drawing.Point ($header.Width - 60), 18
        }.GetNewClosure())
    }

    # ── Header bottom glow
    $header.Add_Paint({
        param($s, $e)
        $rect = New-Object System.Drawing.Rectangle 0, ($s.Height - 3), $s.Width, 3
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $T.AccentDim, $T.Lava, 0
        $e.Graphics.FillRectangle($brush, $rect)
        $brush.Dispose()
    }.GetNewClosure())

    # ── Status strip
    $status = New-Object System.Windows.Forms.StatusStrip
    $status.BackColor = $T.BgAlt
    $status.SizingGrip = $false
    $statusText = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusText.Text = 'Ready.'
    $statusText.ForeColor = $T.TextDim
    $statusText.Spring = $true
    $statusText.TextAlign = 'MiddleLeft'
    [void]$status.Items.Add($statusText)

    # ── Button bar (children placed by Add-MavButtonBar)
    $buttonBar = New-Object System.Windows.Forms.Panel
    $buttonBar.Dock = 'Bottom'
    $buttonBar.Height = 56
    $buttonBar.BackColor = $T.BgAlt

    # ── Content area: outer scroll panel + inner TableLayoutPanel for stacking
    # Scroll panel adds vertical scrollbar if total content exceeds form height
    $contentScroll = New-Object System.Windows.Forms.Panel
    $contentScroll.Dock = 'Fill'
    $contentScroll.AutoScroll = $true
    $contentScroll.Padding = '14,8,14,8'
    $contentScroll.BackColor = $T.Bg

    # Sections stack via Dock=Top directly inside the scroll panel. Each
    # section's Height is set explicitly before adding, and SetChildIndex(0)
    # forces the new section to z-index 0 so older sections (higher z) dock
    # first → result: top-to-bottom matches add order. Simpler and more
    # reliable than TableLayoutPanel for vertical stacks.
    # We track a "content host" reference for _Add-MavRow to attach to.
    $contentTable = $contentScroll   # alias: the host IS the scroll panel

    # Add to form. Z-index order matters for Dock behavior — see SetChildIndex below.
    $form.Controls.Add($header)
    $form.Controls.Add($status)
    $form.Controls.Add($buttonBar)
    $form.Controls.Add($contentScroll)

    # CRITICAL — WinForms processes Dock in REVERSE z-order: highest index
    # docks FIRST. So set Fill (contentScroll) at index 0, top/bottom edges
    # at higher indices. Without this, the Fill child eats the entire client
    # area before the docked children can claim their edges.
    $form.Controls.SetChildIndex($contentScroll, 0)
    $form.Controls.SetChildIndex($status, 1)
    $form.Controls.SetChildIndex($buttonBar, 2)
    $form.Controls.SetChildIndex($header, 3)
    $form.PerformLayout()

    # Fade-in (assigned at form-Shown)
    if ($FadeIn) {
        $form.Opacity = 0.0
        $fadeTimer = New-Object System.Windows.Forms.Timer
        $fadeTimer.Interval = 16
        $script:_fadePhase = 0
        $fadeTimer.Add_Tick({
            $script:_fadePhase++
            $t = [Math]::Min(1.0, $script:_fadePhase / 18.0)
            $form.Opacity = [Math]::Pow($t, 0.6)
            if ($script:_fadePhase -ge 18) { $form.Opacity = 1.0; $fadeTimer.Stop() }
        }.GetNewClosure())
        $form.Add_Shown({ $fadeTimer.Start() }.GetNewClosure())
    }

    # Build app handle returned to caller
    $app = [pscustomobject]@{
        Form          = $form
        Header        = $header
        TitleLabel    = $lblTitle
        SubtitleLabel = $lblSubtitle
        StatusStrip   = $status
        StatusText    = $statusText
        ButtonBar     = $buttonBar
        ContentScroll = $contentScroll
        ContentTable  = $contentTable
        AlwaysOnTopChk = $chkOnTop
        Theme         = $T
        Fonts         = $F
        Buttons       = @{}        # filled by Add-MavButtonBar
        Sections      = @()        # tracked sections
    }
    return $app
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Set-MavStatus — bottom-strip status text + color
# ═════════════════════════════════════════════════════════════════════
function Set-MavStatus {
    [CmdletBinding()]
    param(
        $App,
        [string]$Text,
        [System.Drawing.Color]$Color = ([System.Drawing.Color]::Empty)
    )
    if ($Color -eq [System.Drawing.Color]::Empty) { $Color = $App.Theme.TextDim }
    $action = { $App.StatusText.Text = $Text; $App.StatusText.ForeColor = $Color }
    if ($App.StatusStrip.InvokeRequired) {
        $App.StatusStrip.BeginInvoke($action) | Out-Null
    } else { & $action }
}

# ─────────────────────────────────────────────────────────────────────
#  Internal: add a "row" (any control) to the content stack — sized by
#  Absolute height so children inside it have a known canvas
# ─────────────────────────────────────────────────────────────────────
function _Add-MavRow {
    param(
        $App,
        $Control,
        [int]$Height
    )
    # Wrap each section in a small spacer panel (Dock=Top) so consecutive
    # sections have a 6-px breathing gap between them. Without the wrapper,
    # GroupBoxes touch each other.
    $wrap = New-Object System.Windows.Forms.Panel
    $wrap.Dock = 'Top'
    $wrap.Height = $Height + 8           # +8 for the breathing gap
    $wrap.Padding = '0,4,0,4'
    $wrap.BackColor = $App.Theme.Bg
    $Control.Dock = 'Fill'
    $wrap.Controls.Add($Control)

    $App.ContentTable.Controls.Add($wrap)
    # Force this new section to the BOTTOM of z-order so older sections
    # (higher z) dock first and end up at the top. Result: visual order
    # matches add order — a section added later appears below earlier ones.
    $App.ContentTable.Controls.SetChildIndex($wrap, 0)

    $App.Sections += @{ Control = $Control; Wrapper = $wrap; Height = $Height }
    return $Control
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavPathRow — folder picker row with Recent dropdown
# ═════════════════════════════════════════════════════════════════════
function Add-MavPathRow {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title,                      # "SOURCE" — the short name
        [string]$Description = '',           # "pick the folder to copy/move FROM"
        [string]$InitialText = '',
        [bool]$ShowRecent = $true,
        [string]$RecentSettingsKey = ''      # if set, recent list is stored under $App.Settings.$RecentSettingsKey
    )
    $T = $App.Theme; $F = $App.Fonts

    $headText = if ($Description) { "  ▶  $Title — $Description  " } else { "  ▶  $Title  " }

    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = $headText
    $grp.Font = $F.UIB
    $grp.ForeColor = $T.Lava

    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $tlp.ColumnCount = 3
    $tlp.RowCount = 1
    $tlp.Padding = '10,12,10,8'
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', 100))
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Absolute', 120))
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Absolute', 140))
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 36))
    $grp.Controls.Add($tlp)

    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Dock = 'Fill'; $tb.Margin = '0,4,8,0'
    $tb.BackColor = $T.BgPanel; $tb.ForeColor = $T.Text
    $tb.Font = $F.Mono; $tb.BorderStyle = 'FixedSingle'
    $tb.AllowDrop = $true
    $tb.Text = $InitialText
    $tlp.Controls.Add($tb, 0, 0)

    # Drag-drop wiring
    $tb.Add_DragEnter({
        param($s, $e)
        if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
            $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
        } else { $e.Effect = [System.Windows.Forms.DragDropEffects]::None }
    })
    $tb.Add_DragDrop({
        param($s, $e)
        $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
        if ($files -and $files.Count -gt 0) { $s.Text = $files[0] }
    })

    $bRecent = $null
    if ($ShowRecent) {
        $bRecent = _New-MavBtn '▼ Recent' $T.BgPanel $T.Ember 100 28
        $bRecent.Dock = 'Fill'; $bRecent.Margin = '0,2,8,2'; $bRecent.Font = $F.UI
        $tlp.Controls.Add($bRecent, 1, 0)
    } else {
        $spacer = New-Object System.Windows.Forms.Label
        $spacer.Dock = 'Fill'
        $tlp.Controls.Add($spacer, 1, 0)
    }

    $bBrowse = _New-MavBtn '📂 Browse…' $T.BgPanel $T.Text 120 28
    $bBrowse.Dock = 'Fill'; $bBrowse.Margin = '0,2,0,2'; $bBrowse.Font = $F.UI
    $tlp.Controls.Add($bBrowse, 2, 0)

    $form = $App.Form
    $bucket = $Title.ToUpper()

    # Browse — when a folder is picked, also save it into the Recent list for this bucket
    $bBrowse.Add_Click({
        $picked = Pick-FolderModern -Title "Pick the $Title folder" -InitialDir $tb.Text -Owner $form
        if ($picked) {
            $tb.Text = $picked
            try { Add-MavRecent -Bucket $bucket -Path $picked } catch {}
        }
    }.GetNewClosure())

    # Also record paths the user types/pastes manually — fires when they leave the textbox
    $tb.Add_Leave({
        $p = $tb.Text.Trim()
        if ($p -and (Test-Path $p)) {
            try { Add-MavRecent -Bucket $bucket -Path $p } catch {}
        }
    }.GetNewClosure())

    # Recent button — popup menu of saved paths
    if ($bRecent) {
        $bRecent.Add_Click({
            $items = Get-MavRecent -Bucket $bucket
            $menu = New-Object System.Windows.Forms.ContextMenuStrip
            $menu.BackColor = $T.BgPanel
            $menu.ForeColor = $T.Text
            if ($items.Count -eq 0) {
                $mi = $menu.Items.Add('(no recent folders yet)')
                $mi.Enabled = $false
                $mi.ForeColor = $T.TextDim
            } else {
                foreach ($item in $items) {
                    $mi = $menu.Items.Add($item)
                    $mi.ForeColor = $T.Text
                    $mi.Tag = $item
                    $mi.Add_Click({
                        param($s, $e); $tb.Text = $s.Tag
                        try { Add-MavRecent -Bucket $bucket -Path $s.Tag } catch {}
                    }.GetNewClosure())
                }
                [void]$menu.Items.Add('-')
                $clr = $menu.Items.Add('Clear recent…')
                $clr.ForeColor = $T.Bad
                $clr.Add_Click({ try { Clear-MavRecent -Bucket $bucket } catch {} }.GetNewClosure())
            }
            $menu.Show($bRecent, (New-Object System.Drawing.Point 0, $bRecent.Height))
        }.GetNewClosure())
    }

    [void](_Add-MavRow $App $grp 84)

    return @{
        GroupBox     = $grp
        TextBox      = $tb
        RecentButton = $bRecent
        BrowseButton = $bBrowse
        Bucket       = $bucket
    }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavRadioGroup
# ═════════════════════════════════════════════════════════════════════
function Add-MavRadioGroup {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'Mode',
        [object[]]$Choices    # @(@{ Key='Copy'; Label='COPY'; ColorName='Text'; Confirm='...' }, ...)
    )
    $T = $App.Theme; $F = $App.Fonts

    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "  $Title  "
    $grp.Font = $F.UIB
    $grp.ForeColor = $T.Lava

    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = 'Fill'
    $flow.WrapContents = $true
    $flow.Padding = '8,12,8,4'
    $flow.BackColor = [System.Drawing.Color]::Transparent
    $grp.Controls.Add($flow)

    $radios = @{}
    $first = $true
    foreach ($c in $Choices) {
        $r = New-Object System.Windows.Forms.RadioButton
        $r.Text = $c.Label
        $r.Font = $F.UIB
        $r.ForeColor = $T[$c.ColorName]
        $r.AutoSize = $true
        $r.Margin = '4,8,40,0'
        if ($first) { $r.Checked = $true; $first = $false }
        if ($c.Confirm) {
            $confirmText = $c.Confirm
            $r.Add_CheckedChanged({
                if ($r.Checked) {
                    $resp = [System.Windows.Forms.MessageBox]::Show(
                        $App.Form, $confirmText,
                        "Confirm $($c.Label)",
                        [System.Windows.Forms.MessageBoxButtons]::YesNo,
                        [System.Windows.Forms.MessageBoxIcon]::Warning)
                    if ($resp -ne 'Yes') { $radios[$Choices[0].Key].Checked = $true }
                }
            }.GetNewClosure())
        }
        $flow.Controls.Add($r)
        $radios[$c.Key] = $r
    }

    [void](_Add-MavRow $App $grp 78)
    return @{ GroupBox = $grp; Radios = $radios }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavOptionsGroup — declarative options panel
# ═════════════════════════════════════════════════════════════════════
function Add-MavOptionsGroup {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'Options',
        [object[]][AllowEmptyCollection()]$Items = @(),    # one row of options
        [int]$Height = 90
    )
    $T = $App.Theme; $F = $App.Fonts

    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "  $Title  "
    $grp.Font = $F.UIB
    $grp.ForeColor = $T.Lava

    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = 'Fill'
    $flow.WrapContents = $true
    $flow.Padding = '8,12,8,4'
    $flow.BackColor = [System.Drawing.Color]::Transparent
    $grp.Controls.Add($flow)

    $controls = @{}
    foreach ($item in $Items) {
        switch ($item.Type) {
            'Label' {
                $lbl = New-Object System.Windows.Forms.Label
                $lbl.Text = $item.Text
                $lbl.AutoSize = $true
                $lbl.ForeColor = if ($item.ColorName) { $T[$item.ColorName] } else { $T.Text }
                $lbl.Margin = '4,7,4,0'
                $flow.Controls.Add($lbl)
            }
            'Numeric' {
                if ($item.LabelText) {
                    $lbl = New-Object System.Windows.Forms.Label
                    $lbl.Text = $item.LabelText
                    $lbl.AutoSize = $true; $lbl.ForeColor = $T.Text
                    $lbl.Margin = '4,7,4,0'
                    $flow.Controls.Add($lbl)
                }
                $num = New-Object System.Windows.Forms.NumericUpDown
                $num.Minimum = if ($item.Min -ne $null) { $item.Min } else { 0 }
                $num.Maximum = if ($item.Max -ne $null) { $item.Max } else { 999999 }
                $num.Value = if ($item.Default -ne $null) { $item.Default } else { 0 }
                $num.Width = if ($item.Width) { $item.Width } else { 60 }
                $num.Margin = '0,4,16,0'
                $num.BackColor = $T.BgPanel; $num.ForeColor = $T.Text
                $flow.Controls.Add($num)
                $controls[$item.Name] = $num
            }
            'CheckBox' {
                $chk = New-Object System.Windows.Forms.CheckBox
                $chk.Text = $item.Label
                $chk.AutoSize = $true; $chk.Margin = '0,7,16,0'
                $chk.Checked = [bool]$item.Default
                $chk.ForeColor = if ($item.ColorName) { $T[$item.ColorName] } else { $T.Text }
                $flow.Controls.Add($chk)
                $controls[$item.Name] = $chk
            }
            'TextBox' {
                if ($item.LabelText) {
                    $lbl = New-Object System.Windows.Forms.Label
                    $lbl.Text = $item.LabelText
                    $lbl.AutoSize = $true; $lbl.ForeColor = $T.Text
                    $lbl.Margin = '4,7,4,0'
                    $flow.Controls.Add($lbl)
                }
                $tb = New-Object System.Windows.Forms.TextBox
                $tb.Width = if ($item.Width) { $item.Width } else { 200 }
                $tb.BackColor = $T.BgPanel; $tb.ForeColor = $T.Text
                $tb.Font = $F.Mono; $tb.BorderStyle = 'FixedSingle'
                $tb.Margin = '0,4,16,0'
                $tb.Text = [string]$item.Default
                $flow.Controls.Add($tb)
                $controls[$item.Name] = $tb
            }
        }
    }

    [void](_Add-MavRow $App $grp $Height)
    return @{ GroupBox = $grp; Controls = $controls; Flow = $flow }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavStatsRow — captioned stat columns
# ═════════════════════════════════════════════════════════════════════
function Add-MavStatsRow {
    [CmdletBinding()]
    param(
        $App,
        [string[]]$Captions,
        [int]$Height = 80
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = $T.BgPanel

    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $colCount = $Captions.Count
    $tlp.ColumnCount = $colCount
    $tlp.RowCount = 2
    $tlp.Padding = '12,8,12,4'
    foreach ($i in 0..($colCount-1)) {
        [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', ([float](100/$colCount))))
    }
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 28))
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Percent', 100))
    $pnl.Controls.Add($tlp)

    $values = @{}
    for ($i = 0; $i -lt $colCount; $i++) {
        $cap = New-Object System.Windows.Forms.Label
        $cap.Text = $Captions[$i]
        $cap.Font = $F.UISub
        $cap.ForeColor = $T.TextDim
        $cap.Dock = 'Fill'; $cap.TextAlign = 'BottomLeft'
        $tlp.Controls.Add($cap, $i, 0)

        $val = New-Object System.Windows.Forms.Label
        $val.Text = '—'
        $val.Font = $F.Stat
        $val.ForeColor = $T.Ember
        $val.Dock = 'Fill'; $val.TextAlign = 'TopLeft'; $val.Margin = '0,2,0,0'
        $tlp.Controls.Add($val, $i, 1)

        $values[$Captions[$i]] = $val
    }

    [void](_Add-MavRow $App $pnl $Height)
    return @{ Panel = $pnl; Values = $values }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavLogPanel — color-coded scrolling log
# ═════════════════════════════════════════════════════════════════════
function Add-MavLogPanel {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'OUTPUT',
        [int]$Height = 240
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Padding = '0,4,0,4'
    $pnl.BackColor = $T.Bg

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Title
    $lbl.Font = $F.UIB
    $lbl.ForeColor = $T.Lava
    $lbl.Dock = 'Top'
    $lbl.Height = 24
    $pnl.Controls.Add($lbl)

    $rtb = New-Object System.Windows.Forms.RichTextBox
    $rtb.Dock = 'Fill'
    $rtb.BackColor = $T.Bg
    $rtb.ForeColor = $T.Text
    $rtb.Font = $F.Mono
    $rtb.ReadOnly = $true
    $rtb.BorderStyle = 'FixedSingle'
    $rtb.WordWrap = $false
    $rtb.DetectUrls = $false
    $rtb.HideSelection = $false
    $pnl.Controls.Add($rtb)
    $lbl.BringToFront()

    [void](_Add-MavRow $App $pnl $Height)

    # Append-Log helper that colors lines based on content
    $appendFn = {
        param([string]$line, $color = $null)
        if ($null -eq $color) { $color = $T.Text }
        $action = {
            $start = $rtb.TextLength
            $rtb.AppendText($line + "`n")
            $rtb.Select($start, $line.Length + 1)
            $rtb.SelectionColor = $color
            $rtb.SelectionStart = $rtb.TextLength
            $rtb.SelectionLength = 0
            $rtb.ScrollToCaret()
        }
        if ($rtb.InvokeRequired) { $rtb.BeginInvoke($action) | Out-Null } else { & $action }
    }.GetNewClosure()

    return @{
        Panel    = $pnl
        TextBox  = $rtb
        Append   = $appendFn
    }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavTabbedLogPanel — multi-tab log with optional disk file
#  -----------------------------------------------------------------
#  Tabs: Full | Simplified | Warnings | Errors (configurable).
#  Append takes a Channels[] list — line goes to those tabs.
#  Optional disk-log path: set via $log.SetLogFile <path> after creation.
#  Caller can also call $log.Export to dump the current Full tab to a
#  user-picked file.
# ═════════════════════════════════════════════════════════════════════
function Add-MavTabbedLogPanel {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'OUTPUT',
        [int]$Height = 280,
        [string[]]$Tabs = @('Full','Simplified','Warnings','Errors')
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = $T.Bg

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Title; $lbl.Font = $F.UIB; $lbl.ForeColor = $T.Lava
    $lbl.Dock = 'Top'; $lbl.Height = 26; $lbl.Padding = '0,4,0,0'
    $pnl.Controls.Add($lbl)

    $tabCtl = New-Object System.Windows.Forms.TabControl
    $tabCtl.Dock = 'Fill'
    $tabCtl.SizeMode = 'Fixed'
    $tabCtl.ItemSize = New-Object System.Drawing.Size 140, 28
    $tabCtl.BackColor = $T.Bg
    $pnl.Controls.Add($tabCtl)
    $lbl.BringToFront()

    $boxes = @{}
    foreach ($name in $Tabs) {
        $page = New-Object System.Windows.Forms.TabPage
        $page.Text = $name; $page.BackColor = $T.Bg
        $rtb = New-Object System.Windows.Forms.RichTextBox
        $rtb.Dock = 'Fill'
        $rtb.BackColor = $T.Bg; $rtb.ForeColor = $T.Text
        $rtb.Font = $F.Mono; $rtb.ReadOnly = $true
        $rtb.BorderStyle = 'None'; $rtb.WordWrap = $false
        $rtb.DetectUrls = $false
        $page.Controls.Add($rtb)
        $tabCtl.TabPages.Add($page)
        $boxes[$name] = $rtb
    }

    # Counts shown on each tab title (e.g. "Errors (3)")
    $counts = @{}; foreach ($n in $Tabs) { $counts[$n] = 0 }

    # Mutable closure-state — disk-log path lives here
    $logState = @{ Path = $null }

    $themeRef = $T  # capture in closure

    $appendFn = {
        param([string]$line, $color = $null, [string[]]$Channels = @('Full'))
        if ($null -eq $line) { return }
        if ($null -eq $color) { $color = $themeRef.Text }
        $action = {
            foreach ($ch in $Channels) {
                if (-not $boxes.ContainsKey($ch)) { continue }
                $rtb = $boxes[$ch]
                if ($rtb.IsDisposed) { continue }
                $start = $rtb.TextLength
                $rtb.AppendText($line + "`n")
                $rtb.Select($start, $line.Length + 1)
                $rtb.SelectionColor = $color
                $rtb.SelectionStart = $rtb.TextLength
                $rtb.SelectionLength = 0
                $rtb.ScrollToCaret()
                $counts[$ch]++
                # Update tab title with running count
                $idx = $Tabs.IndexOf($ch)
                if ($idx -ge 0 -and $idx -lt $tabCtl.TabPages.Count) {
                    $tabCtl.TabPages[$idx].Text = if ($counts[$ch] -gt 0) { "$ch ($($counts[$ch]))" } else { $ch }
                }
            }
        }
        $first = $boxes[$Tabs[0]]
        if ($first.InvokeRequired) { [void]$first.BeginInvoke($action) } else { & $action }
        # Disk write — append unconditionally (channel-tagged)
        if ($logState.Path) {
            try { Add-Content -Path $logState.Path -Value $line -Encoding utf8 -ErrorAction SilentlyContinue } catch {}
        }
    }.GetNewClosure()

    $clearFn = {
        foreach ($rtb in $boxes.Values) { $rtb.Clear() }
        foreach ($k in @($counts.Keys)) { $counts[$k] = 0 }
        for ($i = 0; $i -lt $tabCtl.TabPages.Count; $i++) {
            $tabCtl.TabPages[$i].Text = $Tabs[$i]
        }
    }.GetNewClosure()

    $setLogFileFn = {
        param([string]$Path)
        $logState.Path = $Path
        if ($Path) {
            $dir = Split-Path -Parent $Path
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        }
    }.GetNewClosure()

    $exportFn = {
        param($Owner = $null)
        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Filter = 'Log files (*.log)|*.log|Text files (*.txt)|*.txt|All files (*.*)|*.*'
        $dlg.FileName = "transfer-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        if ($dlg.ShowDialog($Owner) -eq 'OK') {
            try {
                # Write the Full tab text to file
                $rtb = $boxes['Full']
                if ($rtb) { [System.IO.File]::WriteAllText($dlg.FileName, $rtb.Text) }
                return $dlg.FileName
            } catch { return $null }
        }
        return $null
    }.GetNewClosure()

    [void](_Add-MavRow $App $pnl $Height)
    return @{
        Panel       = $pnl
        TabControl  = $tabCtl
        Tabs        = $boxes
        TextBox     = $boxes[$Tabs[0]]   # back-compat: .TextBox = the Full pane
        Append      = $appendFn
        Clear       = $clearFn
        SetLogFile  = $setLogFileFn
        Export      = $exportFn
        Counts      = $counts
    }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavProgressRow — progress bar + 4 stat slots
#  -----------------------------------------------------------------
#  A wide progress bar with caption above + a thin "details" line
#  beneath showing the current file being processed.
# ═════════════════════════════════════════════════════════════════════
function Add-MavProgressRow {
    [CmdletBinding()]
    param(
        $App,
        [int]$Height = 88
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = $T.Bg; $pnl.Padding = '0,4,0,4'

    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $tlp.ColumnCount = 1; $tlp.RowCount = 3
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', 100))
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 22))
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 28))
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 22))
    $pnl.Controls.Add($tlp)

    $lblCap = New-Object System.Windows.Forms.Label
    $lblCap.Text = 'PROGRESS'; $lblCap.Font = $F.UIB; $lblCap.ForeColor = $T.Lava
    $lblCap.Dock = 'Fill'; $lblCap.TextAlign = 'MiddleLeft'
    $tlp.Controls.Add($lblCap, 0, 0)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Dock = 'Fill'; $bar.Margin = '0,2,0,2'
    $bar.Style = 'Continuous'; $bar.Minimum = 0; $bar.Maximum = 100; $bar.Value = 0
    $tlp.Controls.Add($bar, 0, 1)

    $lblDetail = New-Object System.Windows.Forms.Label
    $lblDetail.Text = 'idle'; $lblDetail.Font = $F.Mono; $lblDetail.ForeColor = $T.TextDim
    $lblDetail.Dock = 'Fill'; $lblDetail.TextAlign = 'MiddleLeft'
    $tlp.Controls.Add($lblDetail, 0, 2)

    [void](_Add-MavRow $App $pnl $Height)
    return @{
        Panel   = $pnl
        Bar     = $bar
        Caption = $lblCap
        Detail  = $lblDetail
    }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Add-MavButtonBar — bottom button bar with side placement
# ═════════════════════════════════════════════════════════════════════
function Add-MavButtonBar {
    [CmdletBinding()]
    param(
        $App,
        [object[]]$Buttons        # @(@{ Key='Go'; Text='COPY'; Side='Right'; Primary=$true; ColorName='Accent' }, ...)
    )
    $T = $App.Theme; $F = $App.Fonts

    $leftFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $leftFlow.FlowDirection = 'LeftToRight'
    $leftFlow.Dock = 'Left'
    $leftFlow.AutoSize = $true
    $leftFlow.WrapContents = $false
    $leftFlow.Padding = '10,10,0,0'
    $leftFlow.BackColor = [System.Drawing.Color]::Transparent

    $rightFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $rightFlow.FlowDirection = 'RightToLeft'
    $rightFlow.Dock = 'Right'
    $rightFlow.AutoSize = $true
    $rightFlow.WrapContents = $false
    $rightFlow.Padding = '0,10,10,0'
    $rightFlow.BackColor = [System.Drawing.Color]::Transparent

    $App.ButtonBar.Controls.Add($leftFlow)
    $App.ButtonBar.Controls.Add($rightFlow)

    foreach ($btnDef in $Buttons) {
        $color = if ($btnDef.ColorName) { $T[$btnDef.ColorName] } else { $T.Text }
        $bg = if ($btnDef.Primary) { $T.Accent } else { $T.BgPanel }
        $fg = if ($btnDef.Primary) { [System.Drawing.Color]::White } else { $color }
        $b = _New-MavBtn $btnDef.Text $bg $fg
        if ($btnDef.Primary) {
            $b.FlatAppearance.BorderColor = $T.Lava
            $b.FlatAppearance.BorderSize = 2
        }
        $b.Margin = '4,0,4,0'
        if ($btnDef.Side -eq 'Left') {
            $leftFlow.Controls.Add($b)
        } else {
            $rightFlow.Controls.Add($b)
        }
        if ($btnDef.Disabled) {
            Set-MavButtonReady $b $false
        }
        $App.Buttons[$btnDef.Key] = $b
    }
    return $App.Buttons
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Test-MavLayout — overlap detector + render capture
# ═════════════════════════════════════════════════════════════════════
function Test-MavLayout {
    [CmdletBinding()]
    param(
        $Form,
        [string]$RenderTo = '',
        [bool]$IgnoreDockedSiblings = $true   # Dock=Fill+Bottom siblings reported as overlap by Bounds — false positive
    )
    $issues = New-Object System.Collections.ArrayList

    function _walk($parent, $path) {
        $kids = @($parent.Controls)
        for ($i = 0; $i -lt $kids.Count; $i++) {
            for ($j = $i+1; $j -lt $kids.Count; $j++) {
                $a = $kids[$i]; $b = $kids[$j]
                # Skip Dock-pair false positives: Fill+Bottom, Fill+Top, etc.
                if ($IgnoreDockedSiblings) {
                    $aDock = "$($a.Dock)"; $bDock = "$($b.Dock)"
                    if ($aDock -eq 'Fill' -or $bDock -eq 'Fill') { continue }
                    if ($aDock -in 'Top','Bottom','Left','Right' -and $bDock -in 'Top','Bottom','Left','Right' -and $aDock -ne $bDock) { continue }
                }
                if ($a.Bounds.IntersectsWith($b.Bounds)) {
                    $msg = "{0}: '{1}/{2}' {3} ∩ '{4}/{5}' {6}" -f $path, $a.Name, $a.GetType().Name, $a.Bounds, $b.Name, $b.GetType().Name, $b.Bounds
                    [void]$issues.Add($msg)
                }
            }
            _walk $kids[$i] "$path/$($kids[$i].GetType().Name)"
        }
    }
    _walk $Form 'Form'

    if ($RenderTo) {
        $bmp = New-Object System.Drawing.Bitmap $Form.Width, $Form.Height
        $Form.DrawToBitmap($bmp, (New-Object System.Drawing.Rectangle 0, 0, $Form.Width, $Form.Height))
        $bmp.Save($RenderTo, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
    }

    return @{ Issues = $issues; Count = $issues.Count }
}

# =====================================================================
# =====================================================================
#  PAGE 2 — LAUNCHER  (sidebar + card grid + bottom action bar)
#
#  Pattern: InfernoLauncher's main form. Use for any "control panel"
#  app with categorized buttons on the left, content area in the middle
#  (typically a grid of service/feature cards), and global actions at
#  the bottom.
# =====================================================================
# =====================================================================

function New-MavLauncherForm {
    [CmdletBinding()]
    param(
        [string]$Title = 'Launcher',
        [string]$Subtitle = '',
        [string]$Version = 'v1.0',
        [string]$IconGlyph = '☠',
        [int]$SidebarWidth = 220,
        [int]$Width = 1400,
        [int]$Height = 900,
        [int]$MinWidth = 1200,
        [int]$MinHeight = 700,
        [bool]$FadeIn = $true
    )
    if (-not $script:MavInitialized) { Initialize-MavApp }
    $T = $script:MavTheme; $F = $script:MavFonts

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$Title — Inferno Edition"
    $form.MinimumSize = New-Object System.Drawing.Size $MinWidth, $MinHeight
    $form.Size = New-Object System.Drawing.Size $Width, $Height
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = $T.Bg; $form.ForeColor = $T.Text; $form.Font = $F.UI

    # Header (same as standard form's header — title + subtitle + version)
    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = 'Top'; $header.Height = 100; $header.BackColor = $T.BgAlt

    $tlpHeader = New-Object System.Windows.Forms.TableLayoutPanel
    $tlpHeader.Location = New-Object System.Drawing.Point 16, 14
    $tlpHeader.Size = New-Object System.Drawing.Size 900, 80   # wider so titles up to ~14 chars fit
    $tlpHeader.ColumnCount = 2; $tlpHeader.RowCount = 2
    $tlpHeader.BackColor = [System.Drawing.Color]::Transparent
    [void]$tlpHeader.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Absolute', 80))
    [void]$tlpHeader.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'AutoSize'))
    [void]$tlpHeader.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 50))
    [void]$tlpHeader.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 28))
    $header.Controls.Add($tlpHeader)

    $lblIcon = New-Object System.Windows.Forms.Label
    $lblIcon.Text = $IconGlyph; $lblIcon.Font = $F.UITitle
    $lblIcon.ForeColor = $T.Lava; $lblIcon.BackColor = [System.Drawing.Color]::Transparent
    $lblIcon.Dock = 'Fill'; $lblIcon.TextAlign = 'MiddleCenter'
    $tlpHeader.Controls.Add($lblIcon, 0, 0)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title.ToUpper(); $lblTitle.Font = $F.UITitle
    $lblTitle.ForeColor = $T.Lava; $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $lblTitle.AutoSize = $true; $lblTitle.Margin = '12,0,0,0'
    $tlpHeader.Controls.Add($lblTitle, 1, 0)

    $lblSubtitle = New-Object System.Windows.Forms.Label
    $lblSubtitle.Text = $Subtitle; $lblSubtitle.Font = $F.UISub
    $lblSubtitle.ForeColor = $T.TextDim; $lblSubtitle.BackColor = [System.Drawing.Color]::Transparent
    $lblSubtitle.AutoSize = $true; $lblSubtitle.Margin = '12,0,0,0'
    $tlpHeader.Controls.Add($lblSubtitle, 1, 1)
    $tlpHeader.SetColumnSpan($lblSubtitle, 2)

    $lblVersion = New-Object System.Windows.Forms.Label
    $lblVersion.Text = $Version; $lblVersion.Font = $F.UIB
    $lblVersion.ForeColor = $T.AccentDim; $lblVersion.BackColor = [System.Drawing.Color]::Transparent
    $lblVersion.AutoSize = $true; $lblVersion.Anchor = 'Top, Right'
    $header.Controls.Add($lblVersion)
    $lblVersion.Location = New-Object System.Drawing.Point ($Width - 60), 14
    $header.Add_Resize({ $lblVersion.Location = New-Object System.Drawing.Point ($header.Width - 60), 14 }.GetNewClosure())
    $header.Add_Paint({
        param($s, $e)
        $rect = New-Object System.Drawing.Rectangle 0, ($s.Height - 3), $s.Width, 3
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $T.AccentDim, $T.Lava, 0
        $e.Graphics.FillRectangle($brush, $rect); $brush.Dispose()
    }.GetNewClosure())

    # Status strip + bottom action bar (always-visible global actions)
    $status = New-Object System.Windows.Forms.StatusStrip
    $status.BackColor = $T.BgAlt; $status.SizingGrip = $false
    $statusText = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusText.Text = 'Ready.'; $statusText.ForeColor = $T.TextDim
    $statusText.Spring = $true; $statusText.TextAlign = 'MiddleLeft'
    [void]$status.Items.Add($statusText)

    $bottomActions = New-Object System.Windows.Forms.Panel
    $bottomActions.Dock = 'Bottom'; $bottomActions.Height = 56
    $bottomActions.BackColor = $T.BgAlt

    # Sidebar (left, fixed-width scrollable)
    $sidebar = New-Object System.Windows.Forms.Panel
    $sidebar.Dock = 'Left'; $sidebar.Width = $SidebarWidth
    $sidebar.BackColor = $T.BgAlt
    $sidebar.AutoScroll = $true
    $sidebar.Padding = '10,12,10,12'

    # Vertical separator between sidebar and content
    $sidebarBorder = New-Object System.Windows.Forms.Panel
    $sidebarBorder.Dock = 'Left'; $sidebarBorder.Width = 2
    $sidebarBorder.BackColor = $T.AccentDim

    # Main content area — used for the card grid (or anything else)
    $content = New-Object System.Windows.Forms.Panel
    $content.Dock = 'Fill'
    $content.BackColor = $T.Bg
    $content.AutoScroll = $true
    $content.Padding = '16,16,16,16'

    # The card grid lives inside $content and uses a FlowLayoutPanel
    # so cards wrap as the user resizes the window
    $cardGrid = New-Object System.Windows.Forms.FlowLayoutPanel
    $cardGrid.Dock = 'Fill'
    $cardGrid.FlowDirection = 'LeftToRight'
    $cardGrid.WrapContents = $true
    $cardGrid.AutoScroll = $false
    $cardGrid.BackColor = $T.Bg
    $cardGrid.Padding = '0,0,0,0'
    $content.Controls.Add($cardGrid)

    # Add to form, then enforce dock z-order
    $form.Controls.Add($header)
    $form.Controls.Add($status)
    $form.Controls.Add($bottomActions)
    $form.Controls.Add($sidebarBorder)
    $form.Controls.Add($sidebar)
    $form.Controls.Add($content)
    $form.Controls.SetChildIndex($content,        0)   # Fill claims rest, lowest priority
    $form.Controls.SetChildIndex($sidebar,        1)
    $form.Controls.SetChildIndex($sidebarBorder,  2)
    $form.Controls.SetChildIndex($status,         3)
    $form.Controls.SetChildIndex($bottomActions,  4)
    $form.Controls.SetChildIndex($header,         5)
    $form.PerformLayout()

    if ($FadeIn) {
        $form.Opacity = 0.0
        $fadeTimer = New-Object System.Windows.Forms.Timer
        $fadeTimer.Interval = 16; $script:_fadePhase = 0
        $fadeTimer.Add_Tick({
            $script:_fadePhase++
            $t = [Math]::Min(1.0, $script:_fadePhase / 18.0)
            $form.Opacity = [Math]::Pow($t, 0.6)
            if ($script:_fadePhase -ge 18) { $form.Opacity = 1.0; $fadeTimer.Stop() }
        }.GetNewClosure())
        $form.Add_Shown({ $fadeTimer.Start() }.GetNewClosure())
    }

    $app = [pscustomobject]@{
        Form          = $form
        Header        = $header
        TitleLabel    = $lblTitle
        StatusStrip   = $status
        StatusText    = $statusText
        Sidebar       = $sidebar
        SidebarBorder = $sidebarBorder
        Content       = $content
        CardGrid      = $cardGrid
        BottomActions = $bottomActions
        # ContentTable shim so Set-MavStatus etc. work the same way
        ButtonBar     = $bottomActions
        ContentTable  = $content
        Buttons       = @{}
        Sections      = @()
        SidebarItems  = @()
        Cards         = @()
        Theme         = $T
        Fonts         = $F
    }
    return $app
}

# ═════════════════════════════════════════════════════════════════════
#  Add-MavSidebarSection — visual section header inside the sidebar
# ═════════════════════════════════════════════════════════════════════
function Add-MavSidebarSection {
    [CmdletBinding()]
    param($App, [string]$Text)
    $T = $App.Theme; $F = $App.Fonts
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text.ToUpper()
    $lbl.Font = $F.UISub; $lbl.ForeColor = $T.Lava
    $lbl.Dock = 'Top'; $lbl.Height = 28
    $lbl.TextAlign = 'BottomLeft'
    $lbl.Padding = '4,8,0,0'
    $App.Sidebar.Controls.Add($lbl)
    $App.Sidebar.Controls.SetChildIndex($lbl, 0)
    $App.SidebarItems += $lbl
    return $lbl
}

# ═════════════════════════════════════════════════════════════════════
#  Add-MavSidebarButton — a clickable item in the sidebar
# ═════════════════════════════════════════════════════════════════════
function Add-MavSidebarButton {
    [CmdletBinding()]
    param(
        $App,
        [string]$Text,
        [string]$Icon = '',
        [string]$ColorName = 'Text',
        [scriptblock]$OnClick = $null
    )
    $T = $App.Theme; $F = $App.Fonts
    $b = New-Object System.Windows.Forms.Button
    $b.Text = if ($Icon) { "$Icon  $Text" } else { $Text }
    $b.Font = $F.UI
    $b.ForeColor = $T[$ColorName]
    $b.BackColor = $T.BgAlt
    $b.FlatStyle = 'Flat'
    $b.FlatAppearance.BorderColor = $T.BgPanel
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = $T.BgPanel
    $b.FlatAppearance.MouseDownBackColor = $T.BgPanelHi
    $b.TextAlign = 'MiddleLeft'
    $b.Padding = '8,0,0,0'
    $b.Dock = 'Top'; $b.Height = 32
    $b.Cursor = 'Hand'
    $b.Tag = @{ Ready = $true; OriginalFG = $T[$ColorName]; OriginalBG = $T.BgAlt }
    if ($OnClick) { $b.Add_Click($OnClick) }
    $App.Sidebar.Controls.Add($b)
    $App.Sidebar.Controls.SetChildIndex($b, 0)
    $App.SidebarItems += $b
    return $b
}

# ═════════════════════════════════════════════════════════════════════
#  Add-MavCard — adds a service card (or any tile) to the card grid
# ═════════════════════════════════════════════════════════════════════
function Add-MavCard {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title,
        [string]$Description = '',
        [string]$StatusText = 'Idle',
        [string]$StatusColorName = 'TextDim',
        [int]$Width = 320,
        [int]$Height = 140,
        [scriptblock]$OnClick = $null
    )
    $T = $App.Theme; $F = $App.Fonts

    $card = New-Object System.Windows.Forms.Panel
    $card.Width = $Width; $card.Height = $Height
    $card.BackColor = $T.BgPanel
    $card.Margin = '0,0,12,12'
    $card.Padding = '14,12,14,12'
    $card.Cursor = if ($OnClick) { 'Hand' } else { 'Default' }

    # Top-left red accent bar
    $accent = New-Object System.Windows.Forms.Panel
    $accent.Dock = 'Left'; $accent.Width = 4
    $accent.BackColor = $T.Lava
    $card.Controls.Add($accent)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title; $lblTitle.Font = $F.UIB
    $lblTitle.ForeColor = $T.Text
    $lblTitle.Location = New-Object System.Drawing.Point 18, 10
    $lblTitle.AutoSize = $false
    $lblTitle.Size = New-Object System.Drawing.Size ($Width - 36), 24
    $card.Controls.Add($lblTitle)

    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text = $Description; $lblDesc.Font = $F.UISub
    $lblDesc.ForeColor = $T.TextDim
    $lblDesc.Location = New-Object System.Drawing.Point 18, 42
    $lblDesc.Size = New-Object System.Drawing.Size ($Width - 36), ($Height - 80)
    $card.Controls.Add($lblDesc)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "● $StatusText"
    $lblStatus.Font = $F.UIB
    $lblStatus.ForeColor = $T[$StatusColorName]
    $lblStatus.Location = New-Object System.Drawing.Point 18, ($Height - 28)
    $lblStatus.AutoSize = $true
    $card.Controls.Add($lblStatus)

    if ($OnClick) {
        $card.Add_Click($OnClick)
        $lblTitle.Add_Click($OnClick)
        $lblDesc.Add_Click($OnClick)
    }

    # Hover effect — lighten panel on mouse-over
    $card.Add_MouseEnter({ $card.BackColor = $T.BgPanelHi }.GetNewClosure())
    $card.Add_MouseLeave({ $card.BackColor = $T.BgPanel }.GetNewClosure())

    $App.CardGrid.Controls.Add($card)
    $App.Cards += @{ Panel = $card; TitleLabel = $lblTitle; DescLabel = $lblDesc; StatusLabel = $lblStatus }
    return @{ Panel = $card; TitleLabel = $lblTitle; DescLabel = $lblDesc; StatusLabel = $lblStatus }
}

# ═════════════════════════════════════════════════════════════════════
#  Add-MavBottomActionBar — buttons in the launcher's bottom strip
#  (uses the same Add-MavButtonBar API but installs them in the bottom
#   strip of a launcher form rather than the standard form's button bar)
# ═════════════════════════════════════════════════════════════════════
# (alias — works because launcher form sets ButtonBar = $bottomActions)

# =====================================================================
# =====================================================================
#  PAGE 3 — LIVE CONSOLE  (HealthCheckRunner-style: run-output-cancel)
#
#  Pattern: a single big console panel, a status row, and a few
#  buttons (Run/Cancel/Export). Use for any wrapper that runs a
#  process and streams its stdout.
# =====================================================================
# =====================================================================

function Add-MavLiveConsole {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'CONSOLE OUTPUT',
        [int]$Height = 400
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = $T.Bg

    # Toolbar at top of console: header + status indicator
    $top = New-Object System.Windows.Forms.Panel
    $top.Dock = 'Top'; $top.Height = 28; $top.BackColor = $T.Bg

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title; $lblTitle.Font = $F.UIB
    $lblTitle.ForeColor = $T.Lava
    $lblTitle.Dock = 'Left'; $lblTitle.AutoSize = $false
    $lblTitle.Width = 240; $lblTitle.TextAlign = 'MiddleLeft'
    $top.Controls.Add($lblTitle)

    $lblIndicator = New-Object System.Windows.Forms.Label
    $lblIndicator.Text = '● IDLE'
    $lblIndicator.Font = $F.UIB
    $lblIndicator.ForeColor = $T.TextDim
    $lblIndicator.Dock = 'Right'; $lblIndicator.AutoSize = $false
    $lblIndicator.Width = 160; $lblIndicator.TextAlign = 'MiddleRight'
    $top.Controls.Add($lblIndicator)

    $pnl.Controls.Add($top)

    # The actual console — color-coded RichTextBox
    $rtb = New-Object System.Windows.Forms.RichTextBox
    $rtb.Dock = 'Fill'
    $rtb.BackColor = $T.Bg; $rtb.ForeColor = $T.Text
    $rtb.Font = $F.Mono
    $rtb.ReadOnly = $true; $rtb.BorderStyle = 'FixedSingle'
    $rtb.WordWrap = $false; $rtb.DetectUrls = $false
    $rtb.HideSelection = $false
    $pnl.Controls.Add($rtb)
    $top.BringToFront()

    # Append fn — same colored-line API as Add-MavLogPanel
    $appendFn = {
        param([string]$line, $color = $null)
        if ($null -eq $color) { $color = $T.Text }
        $action = {
            $start = $rtb.TextLength
            $rtb.AppendText($line + "`n")
            $rtb.Select($start, $line.Length + 1)
            $rtb.SelectionColor = $color
            $rtb.SelectionStart = $rtb.TextLength
            $rtb.SelectionLength = 0
            $rtb.ScrollToCaret()
        }
        if ($rtb.InvokeRequired) { $rtb.BeginInvoke($action) | Out-Null } else { & $action }
    }.GetNewClosure()

    # Indicator setter — Idle / Running / Done / Failed
    $setIndicator = {
        param([string]$state)
        $action = {
            switch ($state.ToUpper()) {
                'IDLE'    { $lblIndicator.Text = '● IDLE';     $lblIndicator.ForeColor = $T.TextDim }
                'RUNNING' { $lblIndicator.Text = '● RUNNING';  $lblIndicator.ForeColor = $T.Lava }
                'PAUSED'  { $lblIndicator.Text = '● PAUSED';   $lblIndicator.ForeColor = $T.Warn }
                'DONE'    { $lblIndicator.Text = '● DONE';     $lblIndicator.ForeColor = $T.Good }
                'FAILED'  { $lblIndicator.Text = '● FAILED';   $lblIndicator.ForeColor = $T.Bad }
                default   { $lblIndicator.Text = "● $state";   $lblIndicator.ForeColor = $T.Text }
            }
        }
        if ($lblIndicator.InvokeRequired) { $lblIndicator.BeginInvoke($action) | Out-Null } else { & $action }
    }.GetNewClosure()

    [void](_Add-MavRow $App $pnl $Height)
    return @{
        Panel        = $pnl
        TextBox      = $rtb
        Indicator    = $lblIndicator
        Append       = $appendFn
        SetIndicator = $setIndicator
    }
}

# =====================================================================
# =====================================================================
#  PAGE 4 — LOG VIEWER  (ServiceLogForm-style: toolbar + scrolling log)
#
#  Pattern: a toolbar with Copy/Clear/Save/Filter actions and a
#  read-only log panel. Use for any "look at output / show me history"
#  view.
# =====================================================================
# =====================================================================

function Add-MavLogViewer {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'LOG OUTPUT',
        [int]$Height = 400,
        [bool]$ShowToolbar = $true,
        [bool]$ShowFilter = $true
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = $T.Bg

    $toolbar = New-Object System.Windows.Forms.Panel
    $toolbar.Dock = 'Top'; $toolbar.Height = 44; $toolbar.BackColor = $T.BgAlt

    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = 'Fill'; $flow.FlowDirection = 'LeftToRight'
    $flow.WrapContents = $false
    $flow.Padding = '8,6,8,6'
    $flow.BackColor = [System.Drawing.Color]::Transparent
    $toolbar.Controls.Add($flow)

    function _MakeToolBtn($text, $color) {
        $b = _New-MavBtn $text $T.BgPanel $color 130 30
        $b.Margin = '0,2,8,2'
        $b.AutoSize = $true
        $b.AutoSizeMode = 'GrowAndShrink'
        $b.Padding = '8,2,8,2'
        return $b
    }

    $btnCopy   = _MakeToolBtn '📋 Copy' $T.Text
    $btnClear  = _MakeToolBtn '🗑 Clear' $T.TextDim
    $btnSave   = _MakeToolBtn '💾 Save'  $T.Text
    $btnReload = _MakeToolBtn '↻ Reload' $T.Text
    $flow.Controls.AddRange(@($btnCopy, $btnClear, $btnSave, $btnReload))

    $tbFilter = $null
    if ($ShowFilter) {
        $lblFilter = New-Object System.Windows.Forms.Label
        $lblFilter.Text = 'Filter:'; $lblFilter.AutoSize = $true
        $lblFilter.ForeColor = $T.TextDim
        $lblFilter.Margin = '12,9,4,4'
        $flow.Controls.Add($lblFilter)

        $tbFilter = New-Object System.Windows.Forms.TextBox
        $tbFilter.Width = 280; $tbFilter.Margin = '0,6,4,4'
        $tbFilter.BackColor = $T.BgPanel; $tbFilter.ForeColor = $T.Text
        $tbFilter.Font = $F.Mono; $tbFilter.BorderStyle = 'FixedSingle'
        $flow.Controls.Add($tbFilter)
    }

    if ($ShowToolbar) { $pnl.Controls.Add($toolbar) }

    $rtb = New-Object System.Windows.Forms.RichTextBox
    $rtb.Dock = 'Fill'
    $rtb.BackColor = $T.Bg; $rtb.ForeColor = $T.Text
    $rtb.Font = $F.Mono
    $rtb.ReadOnly = $true; $rtb.BorderStyle = 'FixedSingle'
    $rtb.WordWrap = $false; $rtb.DetectUrls = $false
    $pnl.Controls.Add($rtb)
    if ($ShowToolbar) { $toolbar.BringToFront() }

    $btnCopy.Add_Click({
        if ($rtb.TextLength -gt 0) {
            [System.Windows.Forms.Clipboard]::SetText($rtb.Text)
            Set-MavStatus -App $App -Text 'Log copied to clipboard.' -Color $T.Good
        }
    }.GetNewClosure())
    $btnClear.Add_Click({ $rtb.Clear() }.GetNewClosure())
    $btnSave.Add_Click({
        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Filter = 'Log files (*.log)|*.log|Text files (*.txt)|*.txt|All files (*.*)|*.*'
        $dlg.FileName = "log-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        if ($dlg.ShowDialog($App.Form) -eq 'OK') {
            [System.IO.File]::WriteAllText($dlg.FileName, $rtb.Text)
            Set-MavStatus -App $App -Text "Saved to $($dlg.FileName)" -Color $T.Good
        }
    }.GetNewClosure())

    $appendFn = {
        param([string]$line, $color = $null)
        if ($null -eq $color) { $color = $T.Text }
        $action = {
            $start = $rtb.TextLength
            $rtb.AppendText($line + "`n")
            $rtb.Select($start, $line.Length + 1)
            $rtb.SelectionColor = $color
            $rtb.SelectionStart = $rtb.TextLength
            $rtb.SelectionLength = 0
            $rtb.ScrollToCaret()
        }
        if ($rtb.InvokeRequired) { $rtb.BeginInvoke($action) | Out-Null } else { & $action }
    }.GetNewClosure()

    [void](_Add-MavRow $App $pnl $Height)
    return @{
        Panel        = $pnl
        TextBox      = $rtb
        Toolbar      = $toolbar
        FilterBox    = $tbFilter
        CopyButton   = $btnCopy
        ClearButton  = $btnClear
        SaveButton   = $btnSave
        ReloadButton = $btnReload
        Append       = $appendFn
    }
}

# =====================================================================
# =====================================================================
#  PAGE 5 — SETTINGS DIALOG  (modal: tab pages + OK/Cancel/Apply)
#
#  Pattern: small modal form with categorized settings tabs and the
#  standard OK/Cancel/Apply buttons at the bottom. Use for any
#  preferences-style window.
# =====================================================================
# =====================================================================

function New-MavSettingsDialog {
    [CmdletBinding()]
    param(
        [string]$Title = 'Settings',
        [int]$Width = 720,
        [int]$Height = 540,
        [scriptblock]$OnApply = $null,
        [scriptblock]$OnOK = $null
    )
    if (-not $script:MavInitialized) { Initialize-MavApp }
    $T = $script:MavTheme; $F = $script:MavFonts

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size $Width, $Height
    $form.MinimumSize = New-Object System.Drawing.Size 600, 400
    $form.StartPosition = 'CenterParent'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false; $form.MinimizeBox = $false
    $form.BackColor = $T.Bg; $form.ForeColor = $T.Text; $form.Font = $F.UI

    # Bottom button bar: OK / Cancel / Apply
    $bottom = New-Object System.Windows.Forms.Panel
    $bottom.Dock = 'Bottom'; $bottom.Height = 56; $bottom.BackColor = $T.BgAlt

    $btnApply = _New-MavBtn 'Apply' $T.BgPanel $T.Text
    $btnCancel = _New-MavBtn 'Cancel' $T.BgPanel $T.Text
    $btnOK = _New-MavBtn 'OK' $T.Accent ([System.Drawing.Color]::White)
    $btnOK.FlatAppearance.BorderColor = $T.Lava; $btnOK.FlatAppearance.BorderSize = 2

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    $rightFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $rightFlow.FlowDirection = 'RightToLeft'; $rightFlow.Dock = 'Right'
    $rightFlow.AutoSize = $true; $rightFlow.WrapContents = $false
    $rightFlow.Padding = '0,10,10,0'
    $rightFlow.BackColor = [System.Drawing.Color]::Transparent
    $btnOK.Margin = '4,0,4,0'; $btnCancel.Margin = '4,0,4,0'; $btnApply.Margin = '4,0,4,0'
    $rightFlow.Controls.Add($btnOK)
    $rightFlow.Controls.Add($btnCancel)
    $rightFlow.Controls.Add($btnApply)
    $bottom.Controls.Add($rightFlow)

    # Tab control fills the rest
    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = 'Fill'
    $tabs.Font = $F.UI
    # WinForms TabControl draws an ugly system look on dark themes. Set
    # owner-draw so tabs render in the Inferno palette.
    $tabs.Appearance = 'Buttons'
    $tabs.SizeMode = 'Fixed'
    $tabs.ItemSize = New-Object System.Drawing.Size 140, 32

    $form.Controls.Add($tabs)
    $form.Controls.Add($bottom)
    $form.Controls.SetChildIndex($tabs, 0)
    $form.Controls.SetChildIndex($bottom, 1)

    $btnOK.Add_Click({
        if ($OnOK) { & $OnOK }
        $form.DialogResult = 'OK'
        $form.Close()
    }.GetNewClosure())
    $btnCancel.Add_Click({ $form.DialogResult = 'Cancel'; $form.Close() }.GetNewClosure())
    $btnApply.Add_Click({ if ($OnApply) { & $OnApply } }.GetNewClosure())

    $app = [pscustomobject]@{
        Form         = $form
        Tabs         = $tabs
        BottomPanel  = $bottom
        OKButton     = $btnOK
        CancelButton = $btnCancel
        ApplyButton  = $btnApply
        Theme        = $T
        Fonts        = $F
        TabPages     = @{}
    }
    return $app
}

function Add-MavSettingsTab {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title,
        [object[]][AllowEmptyCollection()]$Items = @()
    )
    $T = $App.Theme; $F = $App.Fonts
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = $Title
    $tab.BackColor = $T.Bg
    $tab.ForeColor = $T.Text
    $tab.Padding = '12,12,12,12'

    # Use a vertically-stacked TableLayoutPanel for the tab content
    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $tlp.ColumnCount = 2
    $tlp.RowCount = $Items.Count + 1   # +1 for spacer
    $tlp.BackColor = [System.Drawing.Color]::Transparent
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Absolute', 200))
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', 100))

    $controls = @{}
    $rowIdx = 0
    foreach ($item in $Items) {
        [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 36))

        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $item.Label; $lbl.ForeColor = $T.Text
        $lbl.Dock = 'Fill'; $lbl.TextAlign = 'MiddleLeft'
        $tlp.Controls.Add($lbl, 0, $rowIdx)

        switch ($item.Type) {
            'TextBox' {
                $tb = New-Object System.Windows.Forms.TextBox
                $tb.Dock = 'Fill'; $tb.Margin = '0,6,0,6'
                $tb.BackColor = $T.BgPanel; $tb.ForeColor = $T.Text
                $tb.Font = $F.Mono; $tb.BorderStyle = 'FixedSingle'
                $tb.Text = [string]$item.Default
                $tlp.Controls.Add($tb, 1, $rowIdx)
                $controls[$item.Name] = $tb
            }
            'CheckBox' {
                $chk = New-Object System.Windows.Forms.CheckBox
                $chk.Text = if ($item.HelpText) { $item.HelpText } else { '' }
                $chk.Dock = 'Fill'; $chk.AutoSize = $false
                $chk.Checked = [bool]$item.Default
                $chk.ForeColor = $T.Text
                $tlp.Controls.Add($chk, 1, $rowIdx)
                $controls[$item.Name] = $chk
            }
            'Numeric' {
                $num = New-Object System.Windows.Forms.NumericUpDown
                $num.Minimum = if ($item.Min -ne $null) { $item.Min } else { 0 }
                $num.Maximum = if ($item.Max -ne $null) { $item.Max } else { 999999 }
                $num.Value = [int]$item.Default
                $num.Width = 100
                $num.Dock = 'Left'; $num.Margin = '0,6,0,6'
                $num.BackColor = $T.BgPanel; $num.ForeColor = $T.Text
                $tlp.Controls.Add($num, 1, $rowIdx)
                $controls[$item.Name] = $num
            }
            'Combo' {
                $cb = New-Object System.Windows.Forms.ComboBox
                $cb.DropDownStyle = 'DropDownList'
                $cb.Dock = 'Left'; $cb.Width = 200; $cb.Margin = '0,6,0,6'
                $cb.BackColor = $T.BgPanel; $cb.ForeColor = $T.Text
                $cb.FlatStyle = 'Flat'
                foreach ($opt in $item.Options) { [void]$cb.Items.Add($opt) }
                if ($item.Default -ne $null) { $cb.SelectedItem = $item.Default }
                $tlp.Controls.Add($cb, 1, $rowIdx)
                $controls[$item.Name] = $cb
            }
        }
        $rowIdx++
    }
    # Spacer row
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Percent', 100))

    $tab.Controls.Add($tlp)
    $App.Tabs.TabPages.Add($tab)
    $App.TabPages[$Title] = @{ Tab = $tab; Controls = $controls }
    return $App.TabPages[$Title]
}

# =====================================================================
# =====================================================================
#  PAGE 6 — MULTI-STEP WIZARD  (SetupWizard / installer style)
# =====================================================================
# =====================================================================

function New-MavWizardForm {
    [CmdletBinding()]
    param(
        [string]$Title = 'Setup Wizard',
        [string]$Subtitle = '',
        [string[]]$StepNames = @('Welcome','Configure','Confirm','Install','Done'),
        [int]$Width = 900,
        [int]$Height = 640
    )
    if (-not $script:MavInitialized) { Initialize-MavApp }
    $T = $script:MavTheme; $F = $script:MavFonts

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$Title — Setup Wizard"
    $form.Size = New-Object System.Drawing.Size $Width, $Height
    $form.MinimumSize = New-Object System.Drawing.Size 700, 500
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.BackColor = $T.Bg; $form.ForeColor = $T.Text; $form.Font = $F.UI

    # ── Top stepper — breadcrumb of steps with current highlighted
    $stepper = New-Object System.Windows.Forms.Panel
    $stepper.Dock = 'Top'; $stepper.Height = 70; $stepper.BackColor = $T.BgAlt
    $stepLabels = @()
    $stepperFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $stepperFlow.Dock = 'Fill'; $stepperFlow.FlowDirection = 'LeftToRight'
    $stepperFlow.WrapContents = $false; $stepperFlow.Padding = '12,18,12,0'
    $stepperFlow.AutoScroll = $true
    $stepperFlow.BackColor = [System.Drawing.Color]::Transparent
    for ($i = 0; $i -lt $StepNames.Count; $i++) {
        $cell = New-Object System.Windows.Forms.Label
        $cell.Text = "$($i+1).  $($StepNames[$i])"
        $cell.Font = $F.UIB
        $cell.AutoSize = $true
        $cell.Padding = '10,8,10,8'
        $cell.TextAlign = 'MiddleCenter'
        $cell.ForeColor = $T.TextDim
        $cell.BackColor = $T.BgPanel
        $cell.Margin = '0,0,4,0'
        $stepperFlow.Controls.Add($cell)
        $stepLabels += $cell
    }
    $stepper.Controls.Add($stepperFlow)
    $stepper.Add_Paint({
        param($s, $e)
        $rect = New-Object System.Drawing.Rectangle 0, ($s.Height - 3), $s.Width, 3
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $T.AccentDim, $T.Lava, 0
        $e.Graphics.FillRectangle($brush, $rect); $brush.Dispose()
    }.GetNewClosure())

    # ── Bottom button bar — Cancel | Back | Next | Finish
    $bottom = New-Object System.Windows.Forms.Panel
    $bottom.Dock = 'Bottom'; $bottom.Height = 60; $bottom.BackColor = $T.BgAlt

    $btnCancel = _New-MavBtn '✕ Cancel' $T.BgPanel $T.Bad
    $btnBack   = _New-MavBtn '← Back'   $T.BgPanel $T.Text
    $btnNext   = _New-MavBtn 'Next →'   $T.Accent ([System.Drawing.Color]::White)
    $btnNext.FlatAppearance.BorderColor = $T.Lava; $btnNext.FlatAppearance.BorderSize = 2
    $btnFinish = _New-MavBtn '✓ Finish' $T.Good ([System.Drawing.Color]::White)
    $btnFinish.Visible = $false
    Set-MavButtonReady $btnBack $false

    $btnCancel.Anchor = 'Top, Left';  $btnCancel.Location = New-Object System.Drawing.Point 16, 12
    $btnFinish.Anchor = 'Top, Right'; $btnFinish.Location = New-Object System.Drawing.Point ($Width - 156), 12
    $btnNext.Anchor   = 'Top, Right'; $btnNext.Location   = New-Object System.Drawing.Point ($Width - 156), 12
    $btnBack.Anchor   = 'Top, Right'; $btnBack.Location   = New-Object System.Drawing.Point ($Width - 296), 12
    $bottom.Controls.AddRange(@($btnCancel, $btnBack, $btnNext, $btnFinish))
    $bottom.Add_Resize({
        $btnFinish.Location = New-Object System.Drawing.Point ($bottom.Width - 156), 12
        $btnNext.Location   = New-Object System.Drawing.Point ($bottom.Width - 156), 12
        $btnBack.Location   = New-Object System.Drawing.Point ($bottom.Width - 296), 12
    }.GetNewClosure())

    # ── Content area — holds all step pages, only one visible at a time
    $content = New-Object System.Windows.Forms.Panel
    $content.Dock = 'Fill'; $content.BackColor = $T.Bg
    $content.Padding = '0,0,0,0'

    $form.Controls.Add($stepper)
    $form.Controls.Add($bottom)
    $form.Controls.Add($content)
    $form.Controls.SetChildIndex($content, 0)
    $form.Controls.SetChildIndex($bottom, 1)
    $form.Controls.SetChildIndex($stepper, 2)
    $form.PerformLayout()

    $app = [pscustomobject]@{
        Form         = $form
        Stepper      = $stepper
        StepLabels   = $stepLabels
        StepNames    = $StepNames
        StepPanels   = @{}
        CurrentStep  = 0
        Bottom       = $bottom
        ContentHost  = $content
        CancelButton = $btnCancel
        BackButton   = $btnBack
        NextButton   = $btnNext
        FinishButton = $btnFinish
        Theme        = $T
        Fonts        = $F
        OnNext       = $null    # caller can set: scriptblock returning $true to allow advance
        OnFinish     = $null
    }

    # Wire navigation
    $btnCancel.Add_Click({ $form.DialogResult = 'Cancel'; $form.Close() }.GetNewClosure())
    $btnBack.Add_Click({
        if ($app.CurrentStep -gt 0) { Set-MavWizardStep -App $app -StepIndex ($app.CurrentStep - 1) }
    }.GetNewClosure())
    $btnNext.Add_Click({
        if ($app.OnNext) {
            $ok = & $app.OnNext $app.CurrentStep
            if (-not $ok) { return }
        }
        if ($app.CurrentStep -lt ($StepNames.Count - 1)) { Set-MavWizardStep -App $app -StepIndex ($app.CurrentStep + 1) }
    }.GetNewClosure())
    $btnFinish.Add_Click({
        if ($app.OnFinish) { & $app.OnFinish }
        $form.DialogResult = 'OK'; $form.Close()
    }.GetNewClosure())

    return $app
}

function Add-MavWizardStep {
    [CmdletBinding()]
    param(
        $App,
        [int]$Index,
        [scriptblock]$ContentBuilder    # called with parent panel; populates it
    )
    $T = $App.Theme
    $page = New-Object System.Windows.Forms.Panel
    $page.Dock = 'Fill'; $page.Padding = '24,18,24,18'
    $page.BackColor = $T.Bg
    $page.Visible = ($Index -eq 0)
    & $ContentBuilder $page
    $App.ContentHost.Controls.Add($page)
    $App.StepPanels[$Index] = $page
    return $page
}

function Set-MavWizardStep {
    [CmdletBinding()]
    param($App, [int]$StepIndex)
    foreach ($k in $App.StepPanels.Keys) { $App.StepPanels[$k].Visible = ($k -eq $StepIndex) }
    $App.CurrentStep = $StepIndex
    # Update step indicator colors
    for ($i = 0; $i -lt $App.StepLabels.Count; $i++) {
        if ($i -lt $StepIndex)        { $App.StepLabels[$i].ForeColor = $App.Theme.Good;  $App.StepLabels[$i].BackColor = $App.Theme.BgPanel; $App.StepLabels[$i].Text = "✓  $($App.StepNames[$i])" }
        elseif ($i -eq $StepIndex)    { $App.StepLabels[$i].ForeColor = [System.Drawing.Color]::White; $App.StepLabels[$i].BackColor = $App.Theme.Lava; $App.StepLabels[$i].Text = "$($i+1).  $($App.StepNames[$i])" }
        else                          { $App.StepLabels[$i].ForeColor = $App.Theme.TextDim; $App.StepLabels[$i].BackColor = $App.Theme.BgPanel; $App.StepLabels[$i].Text = "$($i+1).  $($App.StepNames[$i])" }
    }
    # Back enabled if not first step
    Set-MavButtonReady $App.BackButton ($StepIndex -gt 0)
    # Show Finish on last step instead of Next
    $isLast = ($StepIndex -eq ($App.StepNames.Count - 1))
    $App.NextButton.Visible = (-not $isLast)
    $App.FinishButton.Visible = $isLast
}

# =====================================================================
# =====================================================================
#  PAGE 7 — SPLASH / BOOT PROGRESS
# =====================================================================
# =====================================================================

function New-MavSplashForm {
    [CmdletBinding()]
    param(
        [string]$Title = 'Loading',
        [string]$Subtitle = 'preparing your workspace',
        [string]$IconGlyph = '☠',
        [int]$Width = 520,
        [int]$Height = 460
    )
    if (-not $script:MavInitialized) { Initialize-MavApp }
    $T = $script:MavTheme; $F = $script:MavFonts

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size $Width, $Height
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'None'
    $form.BackColor = $T.Bg
    $form.ForeColor = $T.Text
    $form.Font = $F.UI

    # Red glow border (paint)
    $form.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen $T.Lava, 3
        $rect = New-Object System.Drawing.Rectangle 1, 1, ($s.Width - 3), ($s.Height - 3)
        $e.Graphics.DrawRectangle($pen, $rect); $pen.Dispose()
    }.GetNewClosure())

    # ── Big icon at top
    $lblIcon = New-Object System.Windows.Forms.Label
    $lblIcon.Text = $IconGlyph
    $lblIcon.Font = New-Object System.Drawing.Font('Segoe UI', 56, [System.Drawing.FontStyle]::Bold)
    $lblIcon.ForeColor = $T.Lava; $lblIcon.BackColor = [System.Drawing.Color]::Transparent
    $lblIcon.Dock = 'Top'; $lblIcon.Height = 120
    $lblIcon.TextAlign = 'MiddleCenter'
    $form.Controls.Add($lblIcon)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title.ToUpper()
    $lblTitle.Font = $F.UITitle
    $lblTitle.ForeColor = $T.Lava; $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $lblTitle.Dock = 'Top'; $lblTitle.Height = 40
    $lblTitle.TextAlign = 'MiddleCenter'
    $form.Controls.Add($lblTitle)

    $lblSubtitle = New-Object System.Windows.Forms.Label
    $lblSubtitle.Text = $Subtitle
    $lblSubtitle.Font = $F.UISub
    $lblSubtitle.ForeColor = $T.TextDim; $lblSubtitle.BackColor = [System.Drawing.Color]::Transparent
    $lblSubtitle.Dock = 'Top'; $lblSubtitle.Height = 24
    $lblSubtitle.TextAlign = 'MiddleCenter'
    $form.Controls.Add($lblSubtitle)

    # ── Step list (FlowLayoutPanel of step rows)
    $stepList = New-Object System.Windows.Forms.FlowLayoutPanel
    $stepList.Dock = 'Fill'; $stepList.FlowDirection = 'TopDown'
    $stepList.WrapContents = $false; $stepList.AutoScroll = $true
    $stepList.Padding = '40,8,40,8'
    $stepList.BackColor = [System.Drawing.Color]::Transparent
    $form.Controls.Add($stepList)

    # ── Progress bar at bottom
    $progressPanel = New-Object System.Windows.Forms.Panel
    $progressPanel.Dock = 'Bottom'; $progressPanel.Height = 38
    $progressPanel.Padding = '20,6,20,12'

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Dock = 'Fill'; $progress.Style = 'Marquee'
    $progress.MarqueeAnimationSpeed = 30
    $progressPanel.Controls.Add($progress)
    $form.Controls.Add($progressPanel)

    # Z-order: stepList=Fill last, others Top first
    $form.Controls.SetChildIndex($stepList, 0)
    $form.Controls.SetChildIndex($progressPanel, 1)
    $form.Controls.SetChildIndex($lblSubtitle, 2)
    $form.Controls.SetChildIndex($lblTitle, 3)
    $form.Controls.SetChildIndex($lblIcon, 4)
    $form.PerformLayout()

    $app = [pscustomobject]@{
        Form         = $form
        IconLabel    = $lblIcon
        TitleLabel   = $lblTitle
        SubtitleLabel = $lblSubtitle
        StepList     = $stepList
        Progress     = $progress
        Steps        = @{}
        Theme        = $T
        Fonts        = $F
    }
    return $app
}

function Add-MavSplashStep {
    [CmdletBinding()]
    param($App, [string]$Key, [string]$Text)
    $T = $App.Theme; $F = $App.Fonts

    $row = New-Object System.Windows.Forms.Panel
    $row.Width = 420; $row.Height = 28
    $row.Margin = '0,2,0,2'
    $row.BackColor = [System.Drawing.Color]::Transparent

    $dot = New-Object System.Windows.Forms.Label
    $dot.Text = '○'; $dot.Font = $F.UIB
    $dot.ForeColor = $T.TextFaint
    $dot.Location = New-Object System.Drawing.Point 0, 4
    $dot.Size = New-Object System.Drawing.Size 24, 22

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text; $lbl.Font = $F.UI
    $lbl.ForeColor = $T.TextDim
    $lbl.Location = New-Object System.Drawing.Point 24, 4
    $lbl.Size = New-Object System.Drawing.Size 380, 22
    $lbl.TextAlign = 'MiddleLeft'

    $row.Controls.AddRange(@($dot, $lbl))
    $App.StepList.Controls.Add($row)
    $App.Steps[$Key] = @{ Row = $row; Dot = $dot; Label = $lbl; Status = 'Pending' }
    return $App.Steps[$Key]
}

function Set-MavSplashStepStatus {
    [CmdletBinding()]
    param($App, [string]$Key, [ValidateSet('Pending','Running','Done','Failed')][string]$Status)
    $T = $App.Theme
    $step = $App.Steps[$Key]
    if (-not $step) { return }
    $step.Status = $Status
    $action = {
        switch ($Status) {
            'Pending' { $step.Dot.Text = '○'; $step.Dot.ForeColor = $T.TextFaint; $step.Label.ForeColor = $T.TextDim }
            'Running' { $step.Dot.Text = '◐'; $step.Dot.ForeColor = $T.Lava;     $step.Label.ForeColor = $T.Text }
            'Done'    { $step.Dot.Text = '●'; $step.Dot.ForeColor = $T.Good;     $step.Label.ForeColor = $T.Good }
            'Failed'  { $step.Dot.Text = '✕'; $step.Dot.ForeColor = $T.Bad;      $step.Label.ForeColor = $T.Bad }
        }
    }
    if ($step.Row.InvokeRequired) { $step.Row.BeginInvoke($action) | Out-Null } else { & $action }
}

# =====================================================================
# =====================================================================
#  PAGE 8 — TWO-PANE BROWSER  (file explorer / mail / Slack style)
# =====================================================================
# =====================================================================

function Add-MavSplitPane {
    [CmdletBinding()]
    param(
        $App,
        [int]$LeftWidth = 280,
        [int]$Height = 420,
        [string]$LeftTitle = 'Items',
        [string]$RightTitle = 'Details'
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = $T.Bg

    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Dock = 'Fill'
    $split.Orientation = 'Vertical'
    $split.SplitterWidth = 4
    $split.FixedPanel = 'Panel1'
    $split.Panel1MinSize = 200
    $split.Panel2MinSize = 300
    $split.BackColor = $T.AccentDim
    $split.Panel1.BackColor = $T.BgAlt
    $split.Panel2.BackColor = $T.Bg
    $pnl.Controls.Add($split)
    # SplitterDistance must be set AFTER the SplitContainer has been
    # given a width by its parent layout. HandleCreated fires once
    # WinForms has computed our size, so set there + on Resize.
    $applyDistance = {
        if ($split.Width -gt ($LeftWidth + 50)) {
            try { $split.SplitterDistance = $LeftWidth } catch {}
        }
    }.GetNewClosure()
    $split.Add_HandleCreated($applyDistance)
    $pnl.Add_Resize($applyDistance)

    # ── Left side: TableLayoutPanel with row 0 = label, row 1 = tree
    $tlpL = New-Object System.Windows.Forms.TableLayoutPanel
    $tlpL.Dock = 'Fill'; $tlpL.ColumnCount = 1; $tlpL.RowCount = 2
    [void]$tlpL.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', 100))
    [void]$tlpL.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 32))
    [void]$tlpL.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Percent', 100))
    $tlpL.BackColor = $T.BgAlt
    $split.Panel1.Controls.Add($tlpL)

    $lblL = New-Object System.Windows.Forms.Label
    $lblL.Text = $LeftTitle.ToUpper(); $lblL.Font = $F.UIB
    $lblL.ForeColor = $T.Lava; $lblL.Dock = 'Fill'
    $lblL.TextAlign = 'MiddleLeft'; $lblL.Padding = '12,0,0,0'
    $tlpL.Controls.Add($lblL, 0, 0)

    $tree = New-Object System.Windows.Forms.TreeView
    $tree.Dock = 'Fill'
    $tree.BackColor = $T.BgAlt; $tree.ForeColor = $T.Text
    $tree.Font = $F.UI; $tree.BorderStyle = 'None'
    $tree.HideSelection = $false; $tree.ShowLines = $true
    $tree.LineColor = $T.AccentDim
    $tree.FullRowSelect = $true
    $tlpL.Controls.Add($tree, 0, 1)

    # ── Right side: TableLayoutPanel with row 0 = label, row 1 = detail
    $tlpR = New-Object System.Windows.Forms.TableLayoutPanel
    $tlpR.Dock = 'Fill'; $tlpR.ColumnCount = 1; $tlpR.RowCount = 2
    [void]$tlpR.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', 100))
    [void]$tlpR.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 32))
    [void]$tlpR.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Percent', 100))
    $tlpR.BackColor = $T.Bg
    $split.Panel2.Controls.Add($tlpR)

    $lblR = New-Object System.Windows.Forms.Label
    $lblR.Text = $RightTitle.ToUpper(); $lblR.Font = $F.UIB
    $lblR.ForeColor = $T.Lava; $lblR.Dock = 'Fill'
    $lblR.TextAlign = 'MiddleLeft'; $lblR.Padding = '12,0,0,0'
    $tlpR.Controls.Add($lblR, 0, 0)

    $detail = New-Object System.Windows.Forms.RichTextBox
    $detail.Dock = 'Fill'
    $detail.BackColor = $T.Bg; $detail.ForeColor = $T.Text
    $detail.Font = $F.Mono; $detail.ReadOnly = $true
    $detail.BorderStyle = 'None'; $detail.WordWrap = $true
    $tlpR.Controls.Add($detail, 0, 1)

    [void](_Add-MavRow $App $pnl $Height)
    return @{
        Panel    = $pnl
        Split    = $split
        Tree     = $tree
        Detail   = $detail
        LeftLabel  = $lblL
        RightLabel = $lblR
    }
}

# =====================================================================
# =====================================================================
#  PAGE 9 — FORM INPUT  (account creator / profile editor / ticket form)
#
#  Extension to Add-MavOptionsGroup with richer item types: Date, Time,
#  Slider, ColorPicker, Password, FileBrowse. Plus Add-MavFormGrid for
#  classic key-label / value-control rows.
# =====================================================================
# =====================================================================

function Add-MavFormGrid {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'Details',
        [object[]][AllowEmptyCollection()]$Items = @(),
        [int]$LabelWidth = 180,
        [int]$Height = 0      # 0 = auto-compute from item count
    )
    $T = $App.Theme; $F = $App.Fonts

    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "  $Title  "; $grp.Font = $F.UIB; $grp.ForeColor = $T.Lava

    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $tlp.ColumnCount = 2
    $tlp.RowCount = $Items.Count
    $tlp.Padding = '14,18,14,8'
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Absolute', $LabelWidth))
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', 100))
    $grp.Controls.Add($tlp)

    $controls = @{}
    $rowIdx = 0
    foreach ($item in $Items) {
        [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 38))
        $lbl = New-Object System.Windows.Forms.Label
        $labelText = $item.Label
        if ($item.Required) { $labelText += '  *' }
        $lbl.Text = $labelText; $lbl.ForeColor = if ($item.Required) { $T.Text } else { $T.TextDim }
        $lbl.Dock = 'Fill'; $lbl.TextAlign = 'MiddleLeft'
        $lbl.Font = $F.UI
        $tlp.Controls.Add($lbl, 0, $rowIdx)

        $ctl = $null
        switch ($item.Type) {
            'TextBox' {
                $ctl = New-Object System.Windows.Forms.TextBox
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.BackColor = $T.BgPanel; $ctl.ForeColor = $T.Text
                $ctl.Font = $F.Mono; $ctl.BorderStyle = 'FixedSingle'
                if ($item.Default) { $ctl.Text = [string]$item.Default }
                if ($item.Placeholder) { $ctl.Tag = @{ Placeholder = $item.Placeholder } }
            }
            'Password' {
                $ctl = New-Object System.Windows.Forms.TextBox
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.BackColor = $T.BgPanel; $ctl.ForeColor = $T.Text
                $ctl.Font = $F.Mono; $ctl.BorderStyle = 'FixedSingle'
                $ctl.UseSystemPasswordChar = $true
            }
            'Multiline' {
                $ctl = New-Object System.Windows.Forms.TextBox
                $ctl.Multiline = $true; $ctl.ScrollBars = 'Vertical'
                $ctl.Dock = 'Fill'; $ctl.Margin = '0,8,16,4'
                $ctl.BackColor = $T.BgPanel; $ctl.ForeColor = $T.Text
                $ctl.Font = $F.Mono; $ctl.BorderStyle = 'FixedSingle'
                if ($item.Default) { $ctl.Text = [string]$item.Default }
                # Multiline rows are taller
                $tlp.RowStyles[$rowIdx].Height = 86
            }
            'Date' {
                $ctl = New-Object System.Windows.Forms.DateTimePicker
                $ctl.Format = 'Long'
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.Font = $F.UI
            }
            'Time' {
                $ctl = New-Object System.Windows.Forms.DateTimePicker
                $ctl.Format = 'Time'; $ctl.ShowUpDown = $true
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.Font = $F.UI
            }
            'Slider' {
                $ctl = New-Object System.Windows.Forms.TrackBar
                $ctl.Minimum = if ($item.Min -ne $null) { $item.Min } else { 0 }
                $ctl.Maximum = if ($item.Max -ne $null) { $item.Max } else { 100 }
                $ctl.Value = if ($item.Default -ne $null) { $item.Default } else { 50 }
                $ctl.TickFrequency = 10
                $ctl.Dock = 'Top'; $ctl.Margin = '0,4,16,0'
                $ctl.BackColor = $T.BgAlt
            }
            'Combo' {
                $ctl = New-Object System.Windows.Forms.ComboBox
                $ctl.DropDownStyle = 'DropDownList'
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.BackColor = $T.BgPanel; $ctl.ForeColor = $T.Text
                $ctl.FlatStyle = 'Flat'; $ctl.Font = $F.UI
                foreach ($opt in $item.Options) { [void]$ctl.Items.Add($opt) }
                if ($item.Default -ne $null) { $ctl.SelectedItem = $item.Default }
            }
            'CheckBox' {
                $ctl = New-Object System.Windows.Forms.CheckBox
                $ctl.Text = if ($item.HelpText) { $item.HelpText } else { '' }
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.AutoSize = $false; $ctl.Height = 22
                $ctl.ForeColor = $T.Text
                $ctl.Checked = [bool]$item.Default
            }
            'Numeric' {
                $ctl = New-Object System.Windows.Forms.NumericUpDown
                $ctl.Minimum = if ($item.Min -ne $null) { $item.Min } else { 0 }
                $ctl.Maximum = if ($item.Max -ne $null) { $item.Max } else { 999999 }
                $ctl.Value = if ($item.Default -ne $null) { $item.Default } else { 0 }
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.Width = 120; $ctl.BackColor = $T.BgPanel; $ctl.ForeColor = $T.Text
            }
            'Color' {
                # Color picker — a button that opens ColorDialog
                $ctl = New-Object System.Windows.Forms.Button
                $ctl.Text = '  Pick color…'; $ctl.Font = $F.UI
                $ctl.Dock = 'Top'; $ctl.Margin = '0,8,16,0'
                $ctl.BackColor = if ($item.Default) { $item.Default } else { $T.Lava }
                $ctl.ForeColor = [System.Drawing.Color]::White
                $ctl.FlatStyle = 'Flat'; $ctl.Height = 26
                $ctl.Add_Click({
                    $dlg = New-Object System.Windows.Forms.ColorDialog
                    $dlg.Color = $ctl.BackColor
                    if ($dlg.ShowDialog() -eq 'OK') { $ctl.BackColor = $dlg.Color }
                }.GetNewClosure())
            }
            'FileBrowse' {
                # File picker = textbox + Browse button in a sub-panel
                $sub = New-Object System.Windows.Forms.Panel
                $sub.Dock = 'Top'; $sub.Margin = '0,8,16,0'; $sub.Height = 26
                $tb = New-Object System.Windows.Forms.TextBox
                $tb.Dock = 'Fill'; $tb.BackColor = $T.BgPanel; $tb.ForeColor = $T.Text
                $tb.Font = $F.Mono; $tb.BorderStyle = 'FixedSingle'
                if ($item.Default) { $tb.Text = [string]$item.Default }
                $btn = _New-MavBtn '📂' $T.BgPanel $T.Text 36 26
                $btn.Dock = 'Right'; $btn.Margin = '4,0,0,0'
                $btn.Add_Click({
                    $dlg = New-Object System.Windows.Forms.OpenFileDialog
                    if ($dlg.ShowDialog() -eq 'OK') { $tb.Text = $dlg.FileName }
                }.GetNewClosure())
                $sub.Controls.Add($tb); $sub.Controls.Add($btn); $btn.BringToFront()
                $ctl = $sub
                $controls[$item.Name] = $tb   # caller wants the textbox, not the wrapper
            }
        }
        if ($ctl -and -not $controls.ContainsKey($item.Name)) {
            $tlp.Controls.Add($ctl, 1, $rowIdx)
            $controls[$item.Name] = $ctl
        } elseif ($ctl) {
            $tlp.Controls.Add($ctl, 1, $rowIdx)
        }
        $rowIdx++
    }

    if ($Height -le 0) {
        # Compute from item count: groupbox header (~22) + padding (~26) + 38 per row + multiline extras
        $h = 22 + 26
        foreach ($i in $Items) {
            if ($i.Type -eq 'Multiline') { $h += 86 } else { $h += 38 }
        }
        $Height = $h
    }
    [void](_Add-MavRow $App $grp $Height)
    return @{ GroupBox = $grp; Controls = $controls; Table = $tlp }
}

# =====================================================================
# =====================================================================
#  PAGE 10 — DASHBOARD  (KPI cards + filter dropdowns + multi-checkbox)
# =====================================================================
# =====================================================================

function Add-MavMetricRow {
    [CmdletBinding()]
    param(
        $App,
        [object[]]$Metrics,        # @(@{ Caption='Total Sales'; Value='$1.2M'; Delta='+12%'; DeltaColor='Good' }, ...)
        [int]$Height = 110
    )
    $T = $App.Theme; $F = $App.Fonts

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = $T.Bg

    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $tlp.ColumnCount = $Metrics.Count
    $tlp.RowCount = 1
    $tlp.Padding = '0,4,0,4'
    foreach ($i in 0..($Metrics.Count - 1)) {
        [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', ([float](100 / $Metrics.Count))))
    }
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Percent', 100))
    $pnl.Controls.Add($tlp)

    $cards = @{}
    $col = 0
    foreach ($m in $Metrics) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Dock = 'Fill'; $card.Margin = '0,0,12,0'
        $card.BackColor = $T.BgPanel; $card.Padding = '14,12,14,12'

        $accent = New-Object System.Windows.Forms.Panel
        $accent.Dock = 'Left'; $accent.Width = 4
        $accent.BackColor = $T.Lava
        $card.Controls.Add($accent)

        $cap = New-Object System.Windows.Forms.Label
        $cap.Text = $m.Caption; $cap.Font = $F.UISub
        $cap.ForeColor = $T.TextDim
        $cap.Location = New-Object System.Drawing.Point 18, 10
        $cap.Size = New-Object System.Drawing.Size 220, 22
        $card.Controls.Add($cap)

        $val = New-Object System.Windows.Forms.Label
        $val.Text = $m.Value
        $val.Font = New-Object System.Drawing.Font('Consolas', 18, [System.Drawing.FontStyle]::Bold)
        $val.ForeColor = $T.Ember
        $val.Location = New-Object System.Drawing.Point 18, 32
        $val.Size = New-Object System.Drawing.Size 220, 32
        $card.Controls.Add($val)

        $delta = New-Object System.Windows.Forms.Label
        $delta.Text = $m.Delta
        $delta.Font = $F.UIB
        $delta.ForeColor = if ($m.DeltaColor) { $T[$m.DeltaColor] } else { $T.Good }
        $delta.Location = New-Object System.Drawing.Point 18, 70
        $delta.Size = New-Object System.Drawing.Size 220, 20
        $card.Controls.Add($delta)

        $tlp.Controls.Add($card, $col, 0)
        $cards[$m.Caption] = @{ Card = $card; Value = $val; Delta = $delta; Caption = $cap }
        $col++
    }

    [void](_Add-MavRow $App $pnl $Height)
    return @{ Panel = $pnl; Cards = $cards }
}

# Big multi-item dropdown — same as Combo in Add-MavOptionsGroup but
# exposed as its own row so it can be the only control in a section.
function Add-MavComboList {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'Filter',
        [string]$Label = 'Select an option:',
        [string[]]$Options,
        [string]$Default = '',
        [int]$Height = 84
    )
    $T = $App.Theme; $F = $App.Fonts

    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "  $Title  "; $grp.Font = $F.UIB; $grp.ForeColor = $T.Lava

    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $tlp.ColumnCount = 2; $tlp.RowCount = 1
    $tlp.Padding = '12,18,12,8'
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Absolute', 200))
    [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', 100))
    [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Percent', 100))
    $grp.Controls.Add($tlp)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Label; $lbl.ForeColor = $T.Text
    $lbl.Dock = 'Fill'; $lbl.TextAlign = 'MiddleLeft'
    $tlp.Controls.Add($lbl, 0, 0)

    $cb = New-Object System.Windows.Forms.ComboBox
    $cb.DropDownStyle = 'DropDownList'
    $cb.Dock = 'Top'; $cb.Margin = '0,4,0,4'
    $cb.BackColor = $T.BgPanel; $cb.ForeColor = $T.Text
    $cb.FlatStyle = 'Flat'; $cb.Font = $F.UI
    foreach ($opt in $Options) { [void]$cb.Items.Add($opt) }
    if ($Default) { $cb.SelectedItem = $Default }
    $tlp.Controls.Add($cb, 1, 0)

    [void](_Add-MavRow $App $grp $Height)
    return @{ GroupBox = $grp; ComboBox = $cb }
}

function Add-MavCheckList {
    [CmdletBinding()]
    param(
        $App,
        [string]$Title = 'Categories',
        [object[]]$Items,         # @(@{ Name='X'; Label='Show X'; Default=$true }, ...)
        [int]$Height = 0,         # 0 = auto from item count
        [int]$Columns = 3
    )
    $T = $App.Theme; $F = $App.Fonts

    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "  $Title  "; $grp.Font = $F.UIB; $grp.ForeColor = $T.Lava

    $tlp = New-Object System.Windows.Forms.TableLayoutPanel
    $tlp.Dock = 'Fill'
    $tlp.ColumnCount = $Columns
    $rows = [Math]::Ceiling($Items.Count / $Columns)
    $tlp.RowCount = $rows
    $tlp.Padding = '14,18,14,8'
    foreach ($i in 0..($Columns - 1)) {
        [void]$tlp.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle 'Percent', ([float](100/$Columns))))
    }
    foreach ($i in 0..($rows - 1)) {
        [void]$tlp.RowStyles.Add((New-Object System.Windows.Forms.RowStyle 'Absolute', 30))
    }
    $grp.Controls.Add($tlp)

    $checks = @{}
    $i = 0
    foreach ($item in $Items) {
        $col = $i % $Columns
        $row = [Math]::Floor($i / $Columns)
        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text = $item.Label
        $chk.Checked = [bool]$item.Default
        $chk.Dock = 'Fill'; $chk.AutoSize = $false
        $chk.ForeColor = $T.Text; $chk.Font = $F.UI
        $tlp.Controls.Add($chk, $col, $row)
        $checks[$item.Name] = $chk
        $i++
    }

    if ($Height -le 0) { $Height = 22 + 26 + ($rows * 30) + 8 }
    [void](_Add-MavRow $App $grp $Height)
    return @{ GroupBox = $grp; Checks = $checks }
}

function Add-MavToolStrip {
    [CmdletBinding()]
    param(
        $App,
        [object[]]$Items,        # @(@{ Type='Button'; Key='Refresh'; Text='↻'; OnClick={...} }, @{ Type='Sep' }, ...)
        [int]$Height = 44
    )
    $T = $App.Theme; $F = $App.Fonts

    $strip = New-Object System.Windows.Forms.Panel
    $strip.BackColor = $T.BgAlt

    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = 'Fill'; $flow.FlowDirection = 'LeftToRight'
    $flow.WrapContents = $false; $flow.Padding = '8,6,8,6'
    $flow.BackColor = [System.Drawing.Color]::Transparent
    $strip.Controls.Add($flow)

    $controls = @{}
    foreach ($item in $Items) {
        switch ($item.Type) {
            'Button' {
                $fg = if ($item.ColorName) { $T[$item.ColorName] } else { $T.Text }
                $w  = if ($item.Width)     { $item.Width }          else { 110 }
                $b  = _New-MavBtn $item.Text $T.BgPanel $fg $w 30
                $b.Margin = '0,2,6,2'; $b.Font = $F.UI
                $b.AutoSize = $true; $b.AutoSizeMode = 'GrowAndShrink'
                $b.Padding = '8,2,8,2'
                if ($item.OnClick) { $b.Add_Click($item.OnClick) }
                $flow.Controls.Add($b)
                $controls[$item.Key] = $b
            }
            'Sep' {
                $sep = New-Object System.Windows.Forms.Panel
                $sep.Width = 1; $sep.Height = 24
                $sep.BackColor = $T.AccentDim
                $sep.Margin = '6,8,6,8'
                $flow.Controls.Add($sep)
            }
            'Label' {
                $l = New-Object System.Windows.Forms.Label
                $l.Text = $item.Text; $l.AutoSize = $true
                $l.ForeColor = $T.TextDim; $l.Margin = '4,11,4,4'
                $flow.Controls.Add($l)
            }
            'Combo' {
                $c = New-Object System.Windows.Forms.ComboBox
                $c.DropDownStyle = 'DropDownList'
                $cw = if ($item.Width) { $item.Width } else { 160 }
                $c.Width = $cw; $c.Margin = '0,6,4,4'
                $c.BackColor = $T.BgPanel; $c.ForeColor = $T.Text
                $c.FlatStyle = 'Flat'; $c.Font = $F.UI
                foreach ($opt in $item.Options) { [void]$c.Items.Add($opt) }
                if ($item.Default) { $c.SelectedItem = $item.Default }
                $flow.Controls.Add($c)
                $controls[$item.Key] = $c
            }
        }
    }

    [void](_Add-MavRow $App $strip $Height)
    return @{ Panel = $strip; Controls = $controls }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Show-MavApp — finalize layout and run the message loop
# ═════════════════════════════════════════════════════════════════════
function Show-MavApp {
    [CmdletBinding()]
    param(
        $App,
        [bool]$Modal = $false
    )
    if ($Modal) {
        $App.Form.ShowDialog() | Out-Null
    } else {
        [System.Windows.Forms.Application]::Run($App.Form)
    }
}

# ═════════════════════════════════════════════════════════════════════
#  PUBLIC: Test-MavFrameworkHealth
#  -----------------------------------------------------------------
#  Must be defined BEFORE Export-ModuleMember so PowerShell finds it
#  when resolving the export list. Call right after Import-Module in
#  any consumer script to catch missing exports before the GUI starts.
# ═════════════════════════════════════════════════════════════════════
function Test-MavFrameworkHealth {
    [CmdletBinding()]
    param([string[]]$RequiredFunctions)
    $exported = (Get-Command -Module Mav-AppTemplate -ErrorAction SilentlyContinue).Name
    $missing  = $RequiredFunctions | Where-Object { $_ -notin $exported }
    if ($missing) {
        throw "Mav-AppTemplate missing exports: $($missing -join ', ')"
    }
}

Export-ModuleMember -Function `
    Initialize-MavApp, `
    Get-MavTheme, Get-MavFonts, `
    New-MavForm, `
    Add-MavPathRow, Add-MavRadioGroup, Add-MavOptionsGroup, `
    Add-MavStatsRow, Add-MavLogPanel, Add-MavTabbedLogPanel, Add-MavProgressRow, Add-MavButtonBar, `
    Set-MavStatus, Set-MavButtonReady, Get-MavButtonReady, `
    Pick-FolderModern, Show-MavApp, Test-MavLayout, `
    Add-MavRecent, Get-MavRecent, Clear-MavRecent, `
    New-MavLauncherForm, Add-MavSidebarSection, Add-MavSidebarButton, Add-MavCard, `
    Add-MavLiveConsole, Add-MavLogViewer, `
    New-MavSettingsDialog, Add-MavSettingsTab, `
    New-MavWizardForm, Add-MavWizardStep, Set-MavWizardStep, `
    New-MavSplashForm, Add-MavSplashStep, Set-MavSplashStepStatus, `
    Add-MavSplitPane, Add-MavFormGrid, `
    Add-MavMetricRow, Add-MavComboList, Add-MavCheckList, Add-MavToolStrip, `
    Test-MavFrameworkHealth
