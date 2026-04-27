@{
    RootModule        = 'Mav-AppTemplate.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '4f3a8e2c-1b6f-4d3a-9e0f-c8a5b9e2f1a4'
    Author            = 'Maverick'
    Description       = 'WinForms layout framework for fast PowerShell GUI app development. Solves DPI/spacing/dock-order once so consumers just declare content + handlers.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Initialize-MavApp',
        'Get-MavTheme', 'Get-MavFonts',
        'New-MavForm',
        'Add-MavPathRow', 'Add-MavRadioGroup', 'Add-MavOptionsGroup',
        'Add-MavStatsRow', 'Add-MavLogPanel', 'Add-MavButtonBar',
        'Set-MavStatus', 'Set-MavButtonReady', 'Get-MavButtonReady',
        'Pick-FolderModern', 'Show-MavApp', 'Test-MavLayout',
        'Add-MavRecent', 'Get-MavRecent', 'Clear-MavRecent',
        'New-MavLauncherForm', 'Add-MavSidebarSection', 'Add-MavSidebarButton', 'Add-MavCard',
        'Add-MavLiveConsole', 'Add-MavLogViewer',
        'New-MavSettingsDialog', 'Add-MavSettingsTab',
        'New-MavWizardForm', 'Add-MavWizardStep', 'Set-MavWizardStep',
        'New-MavSplashForm', 'Add-MavSplashStep', 'Set-MavSplashStepStatus',
        'Add-MavSplitPane', 'Add-MavFormGrid',
        'Add-MavMetricRow', 'Add-MavComboList', 'Add-MavCheckList', 'Add-MavToolStrip',
        'Add-MavTabbedLogPanel', 'Add-MavProgressRow',
        'Test-MavFrameworkHealth'
    )
    CmdletsToExport   = @()
    AliasesToExport   = @()
    VariablesToExport = @()
}
