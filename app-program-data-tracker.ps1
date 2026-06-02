# ==============================================================================
# Script Name: app-program-data-tracker.ps1
# Description: Takes two snapshots of a specified directory and compares them to
#              identify new, modified, or deleted files.
#
# --- APPLICATION CONFIGURATION CAPTURE PREAMBLE ---
# This script is designed to capture USER CONFIGURATIONS (settings changed via 
# GUI) after an application is already installed. It is NOT an "installation
# capture" tool to repackage installers.
#
# Correct Workflow:
# 1. Install the application first.
# 2. Start this script (it takes a baseline snapshot of the installed system).
# 3. Open the application GUI and toggle the settings you wish to deploy.
# 4. CLOSE the application completely (so it commits settings from memory to disk/registry).
# 5. Press ENTER in this PowerShell terminal to compare and view changes.
# ==============================================================================

# ==============================================================================
# CONFIGURATION VARIABLES
# ==============================================================================
$FolderPath    = "$env:APPDATA"     # The folder to scan (e.g., $env:APPDATA, $env:LOCALAPPDATA, or C:\ProgramData)
$FilterKeyword = "AppName"          # Only track files/folders containing this keyword. Leave empty "" for all.
# ==============================================================================

function Get-FolderSnapshot {
    param(
        [string]$Path,
        [string]$Filter
    )
    Write-Host "Taking folder snapshot of $Path..." -ForegroundColor Cyan
    $snapshot = @{}
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $filePath = $_.FullName
        # Apply filter keyword if defined
        if ([string]::IsNullOrEmpty($Filter) -or $filePath -like "*$Filter*") {
            $snapshot[$filePath] = @{
                LastWriteTime = $_.LastWriteTime
                Length        = $_.Length
            }
        }
    }
    return $snapshot
}

# 1. Take the initial snapshot before making changes
$snap1 = Get-FolderSnapshot -Path $FolderPath -Filter $FilterKeyword
Write-Host "`n[!] Initial Folder Snapshot Complete." -ForegroundColor Green
Write-Host "[!] Make your changes in the target application now." -ForegroundColor Yellow
Write-Host "[!] Press ENTER to take the second snapshot and compare..." -ForegroundColor Yellow
$null = Read-Host


# 2. Take the second snapshot after changes are made
$snap2 = Get-FolderSnapshot -Path $FolderPath -Filter $FilterKeyword

# 3. Compare and output differences
Write-Host "`n--- FOLDER CHANGES DETECTED ---" -ForegroundColor Cyan
$changesFound = $false

foreach ($path in $snap2.Keys) {
    if (-not $snap1.ContainsKey($path)) {
        Write-Host "[NEW]      $path (Size: $($snap2[$path].Length) bytes)" -ForegroundColor Green
        $changesFound = $true
    } elseif ($snap1[$path].LastWriteTime -ne $snap2[$path].LastWriteTime) {
        Write-Host "[MODIFIED] $path" -ForegroundColor Yellow
        Write-Host "   Before: Size=$($snap1[$path].Length) bytes, Date=$($snap1[$path].LastWriteTime)" -ForegroundColor Gray
        Write-Host "   After:  Size=$($snap2[$path].Length) bytes, Date=$($snap2[$path].LastWriteTime)" -ForegroundColor White
        $changesFound = $true
    }
}

foreach ($path in $snap1.Keys) {
    if (-not $snap2.ContainsKey($path)) {
        Write-Host "[DELETED]  $path" -ForegroundColor Red
        $changesFound = $true
    }
}

if (-not $changesFound) {
    Write-Host "No changes detected." -ForegroundColor Gray
}
