#Requires -Version 5.1
# Test-ModuleHealth.ps1 — run this after EVERY edit to Mav-AppTemplate.psm1.
# Prints PASS/FAIL for every function listed in FunctionsToExport.
# Exits 0 = all present, 1 = something missing.

param([string]$ModulePath = "$PSScriptRoot\..\Mav-AppTemplate.psd1")

$resolved = Resolve-Path $ModulePath -ErrorAction Stop
Write-Host "Loading: $resolved" -ForegroundColor DarkGray

try {
    Import-Module $resolved -Force -ErrorAction Stop
} catch {
    Write-Host "FAIL: module failed to import: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$psd      = Import-PowerShellDataFile $resolved
$expected = $psd.FunctionsToExport | Sort-Object
$exported = (Get-Command -Module Mav-AppTemplate -ErrorAction SilentlyContinue).Name

$pass = 0; $fail = 0
foreach ($fn in $expected) {
    if ($fn -in $exported) {
        Write-Host "  [OK] $fn" -ForegroundColor Green
        $pass++
    } else {
        Write-Host "  [FAIL] $fn — not exported" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
if ($fail -eq 0) {
    Write-Host "PASS: all $pass exports present." -ForegroundColor Green
    exit 0
} else {
    $missing = $expected | Where-Object { $_ -notin $exported }
    Write-Host "FAIL: $fail missing: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}
