# Path Index

## Source Files (PowerShell Original)
- `Mavericks-RoboCopy.ps1` — Main GUI entry point (~830 lines)
- `Mav-AppTemplate.psm1` — WinForms framework module (~2800 lines)
- `Mav-AppTemplate.psd1` — Module manifest
- `tools/Console-Run.ps1` — CLI wrapper (no GUI)
- `tools/Watch-Transfers.ps1` — Auto-booster background service
- `tools/Reset-State.ps1` — Test cleanup utility
- `tests/Mavericks-RoboCopy.Tests.ps1` — Pester unit tests

## Runtime Paths (Windows)
- Settings: `%APPDATA%\Mavericks-RoboCopy\settings.json`
- Recents: `%APPDATA%\Mav-AppTemplate\recents.json`
- Transfer logs: `%LOCALAPPDATA%\Mavericks-RoboCopy\logs\transfer-{yyyyMMdd-HHmmss}.log`
- Crash log: `%LOCALAPPDATA%\Mavericks-RoboCopy\crash.log`
- Sessions log: `%LOCALAPPDATA%\Mavericks-RoboCopy\sessions.log`
- Booster log: `%LOCALAPPDATA%\Mavericks-RoboCopy\booster.log`

## Agent Files
- `.agent/reports/master-blueprint.md` — Architecture + delivery plan
- `.agent/reports/tasks.md` — 44-item build checklist
- `.agent/reports/path-index.md` — This file
- `.agent/reports/progress.md` — Current phase + blockers
- `.agent/reports/understanding-proof.md` — Reading evidence before coding
- `.agent/knowledge/stack-decisions.md` — C# stack rationale
- `.agent/knowledge/workflow-preferences.md` — User workflow rules
- `.agent/scripts/check_understanding_gate.py` — Gate check before Phase 3
- `.agent/scripts/run_with_logs.py` — Wrapper for logged command execution

## C# Rewrite Target Layout (to be created)
- `csharp-rewrite/` — Root of C# solution
- `csharp-rewrite/MavericksCopy/` — Main WinForms project
- `csharp-rewrite/MavericksCopy.Tests/` — xUnit test project
- `csharp-rewrite/docs/Mavericks-RoboCopy-CSharp-Spec.md` — Full technical spec
