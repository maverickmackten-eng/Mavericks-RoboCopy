# Stack Decisions

## Decision
- Project: Mavericks-RoboCopy C# Rewrite
- Existing stack: PowerShell 5.1 + WinForms via Add-Type; module Mav-AppTemplate.psm1 (~2800 lines)
- Chosen language strategy: C# 12 / .NET 8 / Windows Forms; single-file publish; x64 Windows only
- Why: Eliminates PowerShell runtime dependency; faster cold start; native P/Invoke for ntdll.dll (NtSuspendProcess/NtResumeProcess); no PSModulePath issues; NuGet for xUnit; WinRT toast via Windows.UI.Notifications
- Constraints: Must stay WinForms (not WPF/MAUI) to preserve identical layout model; must target Windows 10+ (DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 requires Win10)
- Re-evaluate when: If cross-platform port is ever requested (switch to Avalonia)
