# Workflow Preferences

## User Preferences
- Prefer autonomous continuation until verified: Yes — keep building until a phase is complete, then checkpoint
- Prefer log files over terminal-only output: Yes — all robocopy runs write to .agent/logs/ via run_with_logs.py
- Prefer research after unclear failures: Yes — capture exact error, check spec section, then fix
- Prefer path-safe code and no brittle hard-coded paths: Yes — use Environment.GetFolderPath() for all AppData/LocalAppData paths
- Prefer strong UI/UX research before building local launchers: Yes — read spec §4 fully before touching any WinForms control
- Preferred repo and control-file structure: .agent/ folder at repo root; reports in .agent/reports/; knowledge in .agent/knowledge/; scripts in .agent/scripts/
