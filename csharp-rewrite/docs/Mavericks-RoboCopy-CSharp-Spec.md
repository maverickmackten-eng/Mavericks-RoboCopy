# Mavericks-RoboCopy — Comprehensive Technical Specification for C# Rewrite

> **Purpose:** This document is the single-source-of-truth technical specification derived from reading every source file in the `Mavericks-RoboCopy` PowerShell project. Use it to build a functionally identical C#/WinForms replacement without referencing the original PowerShell sources.

See the full specification in the repo root or in the latest GitHub release.  
This file is the copy placed in the C# rewrite subfolder for easy access by Claude Code.

> **Note to Claude Code:** Start every session by running:
> ```
> python .agent/scripts/start_session_intake.py
> python .agent/scripts/check_understanding_gate.py
> ```
> Then read `.agent/reports/tasks.md` and work from the top of the first incomplete phase.

---

## Quick Reference — Source File to Spec Section Map

| PowerShell File | Spec Section(s) |
|---|---|
| `Mavericks-RoboCopy.ps1` | §2 Settings, §3 State, §4 UI, §8 Args, §9 Parsing, §16 Pause, §20 Completion |
| `Mav-AppTemplate.psm1` | §4 UI Controls, §5 Framework, §6 Theme, §7 Fonts |
| `tools/Console-Run.ps1` | §24 CLI Differences |
| `tools/Watch-Transfers.ps1` | §25 Auto-Booster |
| `tools/Reset-State.ps1` | §26 Reset Tool |
| `tests/Mavericks-RoboCopy.Tests.ps1` | §27 Tests |

## Component Checklist Summary (see tasks.md for full list)

- P1: Foundation (7 items) — SettingsManager, RecentsStore, CrashLogger, FormatHelpers, InfernoTheme, FontSet, DpiSetup
- P2: Core UI (10 items) — MainForm, PathRow x2, ModeSelector, OptionsPanel, FiltersPanel, PostPanel, StatsRow, ProgressRow, ButtonBar
- P3: Transfer Engine (11 items) — ArgBuilder, PreScanner, Runner, ProcessSuspender, OutputParser x4, EtaCalculator, SpeedSampler, StatsTimer
- P4: Log + Completion (8 items) — TabbedLogPanel, log routing, log files, FileTypeTracker, breakdown table, CompletionHandler, ExitCodeInterpreter, FormClosingGuard
- P5: Polish + Tests (8 items) — xUnit x4, integration smoke test, ConsoleCLI, README update, understanding gate
