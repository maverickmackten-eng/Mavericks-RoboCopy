# Master Blueprint

## Mission
- Project goal: Rewrite Mavericks-RoboCopy (PowerShell/WinForms) as a native C# WinForms application with identical functionality, better performance, and no PowerShell runtime dependency.
- Success criteria: All 30 checklist items in `tasks.md` marked done; Pester-equivalent xUnit tests pass; UI matches Inferno theme; all robocopy modes (Copy/Move/Mirror), pause/resume, pre-scan, ETA, and file-type breakdown work correctly.
- Non-goals: No MAUI/WPF port; no Linux support; no new features beyond the PowerShell original.

## Architecture
- Major components: MainForm, SettingsManager, RecentsStore, CrashLogger, RobocopyArgBuilder, PreScanner, RobocopyRunner, ProcessSuspender, OutputParser, EtaCalculator, SpeedSampler, FileTypeTracker, CompletionHandler
- Responsibilities: See `.agent/reports/path-index.md` and `csharp-rewrite/SPEC.md` for per-component details
- Interfaces and integration points: RobocopyRunner -> ConcurrentQueue<string> -> StatsTimer (UI thread); ProcessSuspender -> ntdll.dll P/Invoke; SettingsManager -> %APPDATA%\Mavericks-RoboCopy\settings.json; RecentsStore -> %APPDATA%\Mav-AppTemplate\recents.json
- Data flow: UI controls -> RobocopyArgBuilder -> ProcessStartInfo -> robocopy.exe -> stdout/stderr -> ConcurrentQueue -> UI Timer -> OutputParser -> log tabs + stats update -> CompletionHandler
- Startup order: DPI awareness -> EnableVisualStyles -> CrashLogger.InitSessions() -> SettingsManager.Load() -> MainForm.Init() -> Application.Run()

## Runtime Map
- Services: robocopy.exe (Windows built-in), ntdll.dll (NtSuspendProcess/NtResumeProcess), user32.dll (DPI), shcore.dll (DPI fallback)
- Containers: None
- Processes: Main UI process + robocopy.exe child process (no shell)
- Localhost pages and ports: None
- Path and config contracts: settings.json at %APPDATA%\Mavericks-RoboCopy\; recents.json at %APPDATA%\Mav-AppTemplate\; logs at %LOCALAPPDATA%\Mavericks-RoboCopy\logs\

## Stack Strategy
- Chosen language and framework decisions: C# 12 / .NET 8 / Windows Forms; single-file publish; x64 only
- Why: No PowerShell runtime dependency; faster startup; native P/Invoke for ntdll; WinRT toast support; NuGet ecosystem for xUnit tests
- Alternatives rejected: WPF (heavier), MAUI (no WinForms parity), PowerShell rewrite (status quo)

## Delivery Plan
- Phase 1 (Foundation): Project scaffold, DPI setup, InfernoTheme, FontSet, SettingsManager, RecentsStore, CrashLogger, FormatHelpers
- Phase 2 (Core UI): MainForm shell, PathRow x2, ModeSelector, OptionsPanel, FiltersPanel, PostPanel, StatsRow, ProgressRow, ButtonBar, StatusStrip
- Phase 3 (Transfer Engine): RobocopyArgBuilder, PreScanner, RobocopyRunner (ConcurrentQueue bridge), ProcessSuspender (P/Invoke), OutputParser (all regexes), EtaCalculator, SpeedSampler, StatsTimer
- Phase 4 (Log + Completion): TabbedLogPanel (4 tabs, disk write, badges, export), FileTypeTracker, CompletionHandler (summary, sound, open-dest, post-actions), FormClosingGuard
- Phase 5 (Polish + Tests): xUnit tests mirroring Pester suite, satellite ConsoleCLI, integration smoke test, README update

## Verification Plan
- Unit checks: xUnit — RobocopyArgBuilder (14 test cases from Pester), OutputParser (all regex patterns), SizeParser, EtaCalculator formula, SpeedSampler rolling window
- Integration checks: Run ConsoleCLI dry-run between two test folders; assert exit code <= 7
- Startup checks: App launches without exceptions; sessions.log created; settings.json read/written correctly
- UI or workflow checks: All 8 buttons correct initial state; Pause/Resume label toggles; stats row updates during copy
- Regression checks: Mirror mode never passes both /MIR and /MOV; Move mode fires destructive confirm; FormClosing resumes then kills

## Risks
- Known risks: NtSuspendProcess not officially documented for robocopy (works in practice since Win7); WinRT toast may silently fail on older Windows builds
- Blockers: None at start
- Assumptions: Target is Windows 10 x64 or later; .NET 8 runtime available or single-file publish used
