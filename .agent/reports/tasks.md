# Tasks — C# Rewrite Build Checklist

> Source of truth: `csharp-rewrite/docs/Mavericks-RoboCopy-CSharp-Spec.md`  
> Each task maps to a spec section. Check off items as Claude Code completes them.
> Run `python .agent/scripts/check_understanding_gate.py` before starting Phase 3.

---

## PHASE 1 — Foundation

### Core Services
- [ ] **P1-01** `SettingsManager` — Load/Save `settings.json`; all 9 keys (spec §2); graceful fallback on corrupt JSON; UTF-8 encoding
- [ ] **P1-02** `RecentsStore` — `recents.json`; bucket-based (SOURCE/DESTINATION); max 12; case-insensitive dedup; UTF-8
- [ ] **P1-03** `CrashLogger` — Write `sessions.log` as absolute first action on startup; write `crash.log` on unhandled exceptions; attach to `Application.ThreadException` + `AppDomain.UnhandledException`
- [ ] **P1-04** `FormatHelpers.FormatBytes(long)` — Output: B / KB / MB / GB / TB with 1–2 decimal places
- [ ] **P1-05** `FormatHelpers.FormatDuration(TimeSpan)` — Output: M:SS or H:MM:SS

### Theme + Fonts
- [ ] **P1-06** `InfernoTheme` — 17 color properties matching spec §6 hex values exactly
- [ ] **P1-07** `FontSet` — 6 Font objects (UI, UIB, UITitle, UISub, Mono, Stat) per spec §7

---

## PHASE 2 — Core UI

### Form Shell
- [ ] **P2-01** `DpiSetup` — Per-Monitor V2 → Per-Monitor fallback → SetProcessDPIAware; called before `Application.Run` (spec §29)
- [ ] **P2-02** `MainForm` — 1280×1280; dark Bg background; header with AccentDim→Lava glow bar; scrollable content panel; status strip

### Controls
- [ ] **P2-03** `PathRow` (×2 — SOURCE + DESTINATION) — TextBox (Mono font) + drag-drop + Browse (IFileOpenDialog + FolderBrowserDialog fallback) + Recent ContextMenuStrip; auto-add to recents on Leave
- [ ] **P2-04** `ModeSelector` — 3 RadioButtons; Move + Mirror show destructive `MessageBox` confirm before checking (spec §4.4)
- [ ] **P2-05** `OptionsPanel` — Threads `NumericUpDown` (1–128, default 16) + Subdirs/Verbose/Restartable `CheckBox` controls
- [ ] **P2-06** `FiltersPanel` — Excludes `TextBox` (w=560) + Days `NumericUpDown` (0–36500) + IPG `NumericUpDown` (0–9999)
- [ ] **P2-07** `PostPanel` — OpenDest `CheckBox`
- [ ] **P2-08** `StatsRow` — 6 caption/value label pairs; Consolas 11pt Bold; Ember color; captions: FILES, TOTAL, COPIED, ELAPSED, SPEED, ETA
- [ ] **P2-09** `ProgressRow` — `ProgressBar` (Continuous, 0–100) + detail `Label`
- [ ] **P2-10** `ButtonBar` — 8 buttons with exact initial enabled/soft-disabled states per spec §4.11; soft-disable = No cursor + 50% color dim

---

## PHASE 3 — Transfer Engine

### Process Infrastructure
- [ ] **P3-01** `RobocopyArgBuilder.Build(...)` — Static method; all args per spec §8; `/BYTES` GUI-only flag; backslash trim; wildcard vs directory exclude split
- [ ] **P3-02** `PreScanner.Run(src, threads)` — `robocopy NUL /L /E /NFL /NJH /R:0 /W:0 /BYTES`; parse Files + Bytes lines; return `(int files, long bytes)`; catch + log failure without blocking transfer
- [ ] **P3-03** `RobocopyRunner` — `ProcessStartInfo` (no shell, redirect stdout+stderr, UTF-8); `BeginOutputReadLine` + `BeginErrorReadLine`; `ConcurrentQueue<string>` with `"O:"`/`"E:"` prefixes; `Task.Run` wait + 500ms flush sleep
- [ ] **P3-04** `ProcessSuspender` — `NtSuspendProcess` + `NtResumeProcess` P/Invoke to ntdll.dll (spec §16); handles resume-before-kill for Cancel-while-paused

### Parsing
- [ ] **P3-05** `OutputParser.ColorForLine(string)` — 5 regex patterns from spec §9.1
- [ ] **P3-06** `OutputParser.ChannelsForLine(string)` — Returns `string[]` for tab routing per spec §9.2
- [ ] **P3-07** `OutputParser.UpdateStats(string, TransferState)` — 4 patterns: New File/Newer, ERROR COPYING, New Dir, Files summary table (spec §9.3)
- [ ] **P3-08** `OutputParser.ParseSize(string)` — k/m/g suffix multiplier; comma removal (spec §9.5)

### ETA + Speed
- [ ] **P3-09** `EtaCalculator.InitialEta(long totalBytes, int threads)` — Heuristic formula: `thread_factor = 1 + 0.6 * log10(max(1, threads))`; baseline 50 MB/s (spec §12)
- [ ] **P3-10** `SpeedSampler` — Rolling 6-sample window; delta bytes / delta seconds per 300ms tick (spec §13)
- [ ] **P3-11** `StatsTimer` — 300ms `System.Windows.Forms.Timer`; drains `ConcurrentQueue`; calls `UpdateStats`; updates all 6 stat labels + progress bar + detail label; triggers `CompletionHandler` when done + queue empty

---

## PHASE 4 — Log + Completion

### Log Panel
- [ ] **P4-01** `TabbedLogPanel` — 4 `RichTextBox` tabs (Full, Simplified, Warnings, Errors); count badges on tab titles; `SetLogFile(path)` disk append; `Export` button (SaveFileDialog); `Clear` resets all tabs + badges
- [ ] **P4-02** Log routing wired: every Append call routes per `ChannelsForLine` + always writes to disk log file
- [ ] **P4-03** Log file auto-created per run: `%LOCALAPPDATA%\Mavericks-RoboCopy\logs\transfer-{yyyyMMdd-HHmmss}.log`

### Completion
- [ ] **P4-04** `FileTypeTracker` — `ExtCounts`, `ExtBytes`, `ExtFailed` dicts; ext from `Path.GetExtension().ToLower()`; empty ext → `"(no ext)"`
- [ ] **P4-05** File-type breakdown table display — sorted by count desc; top 15; `ExtFailed`-only rows with `"— all failed"` suffix; Simplified tab adds `"… and N more"` if > 15 (spec §19)
- [ ] **P4-06** `CompletionHandler` — TAG selection (CANCELLED/DRY RUN COMPLETE/TRANSFER COMPLETE); copiedCount/failedCount selection fallback (spec §20); 90-char `═` summary block; all 15 post-completion actions in order
- [ ] **P4-07** Exit code interpretation — 8 rows per spec §21; correct color + sound + OpenDest trigger per code
- [ ] **P4-08** `FormClosingGuard` — Prompt if transfer running; resume-then-kill if paused

---

## PHASE 5 — Polish + Tests

### Tests
- [ ] **P5-01** xUnit test project targeting `RobocopyArgBuilder` — 14 test cases mirroring Pester suite (spec §27)
- [ ] **P5-02** xUnit tests for `OutputParser` — color, channel routing, stat update, ParseSize
- [ ] **P5-03** xUnit tests for `EtaCalculator` — formula verification at 1, 8, 16, 64 threads
- [ ] **P5-04** xUnit tests for `SpeedSampler` — rolling window trim, average
- [ ] **P5-05** Integration smoke test (dry-run): run ConsoleCLI equivalent between two temp folders; assert exit code <= 7

### Satellite + Docs
- [ ] **P5-06** `ConsoleCLI` — CLI entry point; same `RobocopyArgBuilder`; blocking `Process.Start`; no forms; prints command in cyan + exit verdict in green/red (spec §24)
- [ ] **P5-07** Update `README.md` — Add C# build instructions, .NET 8 requirement, and satellite tool docs
- [ ] **P5-08** Run `check_understanding_gate.py` — Must output `UNDERSTANDING_GATE_PASSED` before final PR

---

## Progress Summary

| Phase | Total | Done | Remaining |
|-------|-------|------|----------|
| P1 Foundation | 7 | 0 | 7 |
| P2 Core UI | 10 | 0 | 10 |
| P3 Transfer Engine | 11 | 0 | 11 |
| P4 Log + Completion | 8 | 0 | 8 |
| P5 Polish + Tests | 8 | 0 | 8 |
| **Total** | **44** | **0** | **44** |
