# ==============================================================================
# Script Name: reg-snapshot.ps1
# Description: Takes two snapshots of a specified Registry path and compares them
#              to identify new, modified, or deleted registry keys and values.
#              Useful for finding registry configurations written by GUI tools.
# ==============================================================================

# ==============================================================================
# CONFIGURATION VARIABLES
# ==============================================================================
$RegistryRoot  = "HKCU:\Software"   # The registry hive/path to scan (e.g., HKCU:\Software or HKLM:\Software)
$FilterKeyword = "PublisherOrAppName" # Filters keys/values containing this keyword. Leave empty "" for all (caution: lots of noise!).
# ==============================================================================

function Get-RegistrySnapshot {
    param(
        [string]$Path,
        [string]$Filter
    )
    Write-Host "Taking registry snapshot of $Path..." -ForegroundColor Cyan
    $snapshot = @{}
    Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $keyPath = $_.Name
        # Apply filter keyword if defined
        if ([string]::IsNullOrEmpty($Filter) -or $keyPath -like "*$Filter*") {
            $key = $_
            try {
                $key.GetValueNames() | ForEach-Object {
                    $valName = $_
                    $valValue = $key.GetValue($valName)
                    $snapshot["$keyPath\$valName"] = $valValue
                }
            } catch {}
        }
    }
    return $snapshot
}

# 1. Take the initial snapshot before making changes
$snap1 = Get-RegistrySnapshot -Path $RegistryRoot -Filter $FilterKeyword
Write-Host "`n[!] Initial Registry Snapshot Complete." -ForegroundColor Green
Write-Host "[!] Make your changes in the target application now." -ForegroundColor Yellow
Write-Host "[!] Press any key to take the second snapshot and compare..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# 2. Take the second snapshot after changes are made
$snap2 = Get-RegistrySnapshot -Path $RegistryRoot -Filter $FilterKeyword

# 3. Compare and output differences
Write-Host "`n--- REGISTRY CHANGES DETECTED ---" -ForegroundColor Cyan
$changesFound = $false

foreach ($key in $snap2.Keys) {
    if (-not $snap1.ContainsKey($key)) {
        Write-Host "[NEW]      $key = $($snap2[$key])" -ForegroundColor Green
        $changesFound = $true
    } elseif ($snap1[$key] -ne $snap2[$key]) {
        Write-Host "[MODIFIED] $key" -ForegroundColor Yellow
        Write-Host "   Before: $($snap1[$key])" -ForegroundColor Gray
        Write-Host "   After:  $($snap2[$key])" -ForegroundColor White
        $changesFound = $true
    }
}

foreach ($key in $snap1.Keys) {
    if (-not $snap2.ContainsKey($key)) {
        Write-Host "[DELETED]  $key" -ForegroundColor Red
        $changesFound = $true
    }
}

if (-not $changesFound) {
    Write-Host "No changes detected." -ForegroundColor Gray
}
