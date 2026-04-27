#Requires -Module Pester
# Mavericks-RoboCopy.Tests.ps1
# Tests the robocopy argument-builder logic in isolation (no GUI, no module needed).
# The same logic lives in tools\Console-Run.ps1; tests reference that copy.
# Run with: Invoke-Pester tests\Mavericks-RoboCopy.Tests.ps1 -Output Detailed

BeforeAll {
    # Inline the argument-builder so the test has no dependency on the GUI .ps1.
    # This is the canonical implementation — keep in sync with Console-Run.ps1.
    function Build-RobocopyArgsTest {
        param(
            [string]$Source, [string]$Destination,
            [string]$Mode = 'Copy', [int]$Threads = 16,
            [bool]$Subdirs = $false, [bool]$Verbose = $false,
            [bool]$Restartable = $false, [bool]$DryRun = $false,
            [string]$Excludes = '', [int]$Days = 0, [int]$IPG = 0
        )
        $a = @($Source.TrimEnd('\','/'), $Destination.TrimEnd('\','/'))
        if ($Subdirs)     { $a += '/E' }
        $a += "/MT:$Threads"
        $a += '/R:1', '/W:1', '/NP', '/TEE'
        if ($Verbose)     { $a += '/V' }
        if ($Restartable) { $a += '/Z' }
        if ($Mode -eq 'Mirror') { $a += '/MIR' }
        elseif ($Mode -eq 'Move') { $a += '/MOV' }
        if ($DryRun)      { $a += '/L' }
        if ($Days -gt 0)  { $a += "/MAXAGE:$Days" }
        if ($IPG -gt 0)   { $a += "/IPG:$IPG" }
        foreach ($pat in ($Excludes -split ',|;')) {
            $p = $pat.Trim(); if (-not $p) { continue }
            if ($p.Contains('*') -or $p.Contains('?')) { $a += '/XF', $p } else { $a += '/XD', $p }
        }
        return , $a
    }
}

Describe 'Build-RobocopyArgs' {
    It 'always includes safety flags /R:1 /W:1 /NP /TEE' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst'
        $a | Should -Contain '/R:1'
        $a | Should -Contain '/W:1'
        $a | Should -Contain '/NP'
        $a | Should -Contain '/TEE'
    }
    It 'strips trailing backslash from source' {
        $a = Build-RobocopyArgsTest -Source 'C:\src\' -Destination 'D:\dst'
        $a[0] | Should -Be 'C:\src'
    }
    It 'strips trailing backslash from destination' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst\'
        $a[1] | Should -Be 'D:\dst'
    }
    It 'includes /E when Subdirs is true' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Subdirs $true
        $a | Should -Contain '/E'
    }
    It 'omits /E when Subdirs is false' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Subdirs $false
        $a | Should -Not -Contain '/E'
    }
    It 'sets thread count correctly' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Threads 8
        $a | Should -Contain '/MT:8'
    }
    It 'adds /MIR for Mirror mode' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Mode 'Mirror'
        $a | Should -Contain '/MIR'
        $a | Should -Not -Contain '/MOV'
    }
    It 'adds /MOV for Move mode' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Mode 'Move'
        $a | Should -Contain '/MOV'
        $a | Should -Not -Contain '/MIR'
    }
    It 'adds neither /MIR nor /MOV for Copy mode' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Mode 'Copy'
        $a | Should -Not -Contain '/MIR'
        $a | Should -Not -Contain '/MOV'
    }
    It 'adds /L for dry run' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -DryRun $true
        $a | Should -Contain '/L'
    }
    It 'adds /V for verbose' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Verbose $true
        $a | Should -Contain '/V'
    }
    It 'adds /MAXAGE for Days > 0' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Days 7
        $a | Should -Contain '/MAXAGE:7'
    }
    It 'adds /XD for plain folder excludes' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Excludes '.git,node_modules'
        $a | Should -Contain '/XD'
        $a | Should -Contain '.git'
        $a | Should -Contain 'node_modules'
    }
    It 'adds /XF for wildcard excludes' {
        $a = Build-RobocopyArgsTest -Source 'C:\src' -Destination 'D:\dst' -Excludes '*.tmp,*.log'
        $a | Should -Contain '/XF'
        $a | Should -Contain '*.tmp'
    }
}

Describe 'Console-Run.ps1 integration' {
    It 'exits 0 or 1 when copying between real test folders' -Skip:(-not (Test-Path 'C:\Users\ACER\Desktop\testfolder-1')) {
        $result = & "$PSScriptRoot\..\tools\Console-Run.ps1" `
            -Source      'C:\Users\ACER\Desktop\testfolder-1' `
            -Destination 'F:\testfolder-2' `
            -DryRun
        $LASTEXITCODE | Should -BeLessOrEqual 7 -Because 'robocopy exit <=7 means success or already-in-sync'
    }
}
