# ==============================================================================
# Script Name: reg-snapshot.ps1
# Description: Takes snapshots of both HKCU and HKLM Registry paths and compares
#              them to identify new, modified, or deleted keys/values.
#
# --- APPLICATION CONFIGURATION CAPTURE PREAMBLE ---
# This script is designed to capture USER CONFIGURATIONS (settings changed via 
# GUI) after an application is already installed. It is NOT an "installation
# capture" tool to repackage installers.
#
# Correct Workflow:
# 1. Install the application first.
# 2. Start this script (it takes a baseline snapshot of HKCU and HKLM).
# 3. Open the application GUI and toggle the settings you wish to deploy.
# 4. CLOSE the application completely (so it commits settings from memory to disk/registry).
# 5. Press ENTER in this PowerShell terminal to compare and view changes.
# ==============================================================================

# ==============================================================================
# CONFIGURATION VARIABLES
# ==============================================================================
$FilterKeyword = "AVer" # Filters keys/values containing this keyword (starts with)
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
        
        # Split path by backslash and check if any component starts with the filter keyword
        $pathComponents = $keyPath -split '\\'
        $hasMatch = $false
        foreach ($comp in $pathComponents) {
            if ($comp -like "$Filter*") {
                $hasMatch = $true
                break
            }
        }

        if ([string]::IsNullOrEmpty($Filter) -or $hasMatch) {
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

function Compare-Snapshots {
    param(
        [hashtable]$SnapBefore,
        [hashtable]$SnapAfter
    )
    $changesFound = $false

    foreach ($key in $SnapAfter.Keys) {
        if (-not $SnapBefore.ContainsKey($key)) {
            Write-Host "[NEW]      $key = $($SnapAfter[$key])" -ForegroundColor Green
            $changesFound = $true
        } elseif ($SnapBefore[$key] -ne $SnapAfter[$key]) {
            # Format arrays nicely if encountered (e.g. binary data)
            $beforeVal = $SnapBefore[$key]
            $afterVal = $SnapAfter[$key]
            if ($beforeVal -is [array]) { $beforeVal = $beforeVal -join ' ' }
            if ($afterVal -is [array]) { $afterVal = $afterVal -join ' ' }

            Write-Host "[MODIFIED] $key" -ForegroundColor Yellow
            Write-Host "   Before: $beforeVal" -ForegroundColor Gray
            Write-Host "   After:  $afterVal" -ForegroundColor White
            $changesFound = $true
        }
    }

    foreach ($key in $SnapBefore.Keys) {
        if (-not $SnapAfter.ContainsKey($key)) {
            Write-Host "[DELETED]  $key" -ForegroundColor Red
            $changesFound = $true
        }
    }

    if (-not $changesFound) {
        Write-Host "No changes detected." -ForegroundColor Gray
    }
}

# 1. Take initial snapshots of both HKCU and HKLM
$hkcuBefore = Get-RegistrySnapshot -Path "HKCU:\Software" -Filter $FilterKeyword
$hklmBefore = Get-RegistrySnapshot -Path "HKLM:\Software" -Filter $FilterKeyword

Write-Host "`n[!] Initial Registry Snapshots Complete." -ForegroundColor Green
Write-Host "[!] Make your changes in the target application now (and close it when done)." -ForegroundColor Yellow
Write-Host "[!] Press ENTER to take the second snapshot and compare..." -ForegroundColor Yellow
$null = Read-Host

# 2. Take second snapshots of both HKCU and HKLM
$hkcuAfter = Get-RegistrySnapshot -Path "HKCU:\Software" -Filter $FilterKeyword
$hklmAfter = Get-RegistrySnapshot -Path "HKLM:\Software" -Filter $FilterKeyword

# 3. Output comparison in two clean chunks
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "--- CURRENT USER (HKCU) REGISTRY CHANGES ---" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Compare-Snapshots -SnapBefore $hkcuBefore -SnapAfter $hkcuAfter

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "--- LOCAL MACHINE (HKLM) REGISTRY CHANGES ---" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Compare-Snapshots -SnapBefore $hklmBefore -SnapAfter $hklmAfter
