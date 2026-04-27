#Requires -Module Pester
# Mav-AppTemplate.Tests.ps1
# Verifies that every Add-Mav* function returns an object with the expected keys/types.
# Run with: Invoke-Pester tests\Mav-AppTemplate.Tests.ps1 -Output Detailed

param([string]$ModulePath = "$PSScriptRoot\..\Mav-AppTemplate.psd1")

BeforeAll {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.Drawing       -ErrorAction SilentlyContinue
    Import-Module (Resolve-Path $ModulePath) -Force
    $script:app = New-MavForm -Title 'Test' -Subtitle 'unit' -Version 'v0' -Width 900 -Height 700
}

AfterAll {
    try { $script:app.Form.Close() } catch {}
    try { $script:app.Form.Dispose() } catch {}
}

Describe 'FunctionsToExport completeness' {
    It 'every function in the manifest is actually exported' {
        $psd      = Import-PowerShellDataFile (Resolve-Path $ModulePath)
        $exported = (Get-Command -Module Mav-AppTemplate).Name
        $missing  = $psd.FunctionsToExport | Where-Object { $_ -notin $exported }
        $missing | Should -BeNullOrEmpty -Because 'FunctionsToExport must list only actually-defined functions'
    }
}

Describe 'Test-MavFrameworkHealth' {
    It 'passes when all required functions exist' {
        { Test-MavFrameworkHealth -RequiredFunctions @('New-MavForm','Show-MavApp') } | Should -Not -Throw
    }
    It 'throws when a function is missing' {
        { Test-MavFrameworkHealth -RequiredFunctions @('New-MavForm','Fake-Missing-Function-XYZ') } | Should -Throw
    }
}

Describe 'Add-MavTabbedLogPanel' {
    It 'returns a hashtable' {
        $log = Add-MavTabbedLogPanel $script:app -Title 'Log'
        $log | Should -BeOfType [hashtable]
    }
    It 'Append key is a ScriptBlock' {
        $log = Add-MavTabbedLogPanel $script:app -Title 'Log2'
        $log.Append | Should -BeOfType [scriptblock]
    }
    It 'Clear key is a ScriptBlock' {
        $log = Add-MavTabbedLogPanel $script:app -Title 'Log3'
        $log.Clear | Should -BeOfType [scriptblock]
    }
    It 'SetLogFile key is a ScriptBlock' {
        $log = Add-MavTabbedLogPanel $script:app -Title 'Log4'
        $log.SetLogFile | Should -BeOfType [scriptblock]
    }
    It 'Export key is a ScriptBlock' {
        $log = Add-MavTabbedLogPanel $script:app -Title 'Log5'
        $log.Export | Should -BeOfType [scriptblock]
    }
    It 'SetLogFile writes path without throwing' {
        $log = Add-MavTabbedLogPanel $script:app -Title 'Log6'
        { & $log.SetLogFile "$env:TEMP\mav-test.log" } | Should -Not -Throw
    }
    It 'Append writes without throwing' {
        $log = Add-MavTabbedLogPanel $script:app -Title 'Log7'
        { & $log.Append 'hello' $null @('Full') } | Should -Not -Throw
    }
}

Describe 'Add-MavProgressRow' {
    It 'returns an object with a ProgressBar' {
        $prog = Add-MavProgressRow $script:app
        $prog.Bar | Should -BeOfType [System.Windows.Forms.ProgressBar]
    }
    It 'returns an object with a Detail label' {
        $prog = Add-MavProgressRow $script:app
        $prog.Detail | Should -Not -BeNullOrEmpty
    }
}

Describe 'Add-MavStatsRow' {
    It 'returns Values hashtable with all requested captions' {
        $caps  = @('FILES','TOTAL','COPIED','ELAPSED','SPEED','ETA')
        $stats = Add-MavStatsRow $script:app -Captions $caps
        foreach ($k in $caps) {
            $stats.Values[$k] | Should -Not -BeNullOrEmpty -Because "caption $k must have a label"
        }
    }
}

Describe 'Add-MavButtonBar' {
    It 'returns Go and DryRun buttons' {
        $btns = Add-MavButtonBar $script:app -Buttons @(
            @{ Key='Go';     Text='GO';      Side='Right'; Primary=$true }
            @{ Key='DryRun'; Text='DRY RUN'; Side='Right' }
        )
        $btns.Go     | Should -Not -BeNullOrEmpty
        $btns.DryRun | Should -Not -BeNullOrEmpty
    }
}
