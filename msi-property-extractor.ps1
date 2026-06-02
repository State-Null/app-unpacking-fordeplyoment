# ==============================================================================
# Script Name: msi-property-extractor.ps1
# Description: Connects to a Windows Installer MSI database using COM automation
#              and extracts all parameters/attributes from the Property table.
#              Helps packaging engineers find configurable CLI switches.
# ==============================================================================

# ==============================================================================
# CONFIGURATION VARIABLES
# ==============================================================================
$MsiPath = "C:\Path\To\YourInstaller.msi"  # The absolute path to the MSI file you want to query
# ==============================================================================

if (Test-Path $MsiPath) {
    try {
        # Initialize Windows Installer COM object
        $installer = New-Object -ComObject WindowsInstaller.Installer
        
        # Open the MSI database in read-only mode (0)
        $database = $installer.OpenDatabase($MsiPath, 0)
        
        # Query the Property table
        $view = $database.OpenView("SELECT ``Property``, ``Value`` FROM ``Property``")
        $view.Execute()
        
        Write-Output "--- PUBLIC & PRIVATE PROPERTIES IN MSI ---"
        
        # Fetch each row and print properties
        while ($record = $view.Fetch()) {
            $property = $record.StringData(1)
            $value = $record.StringData(2)
            
            # Highlight PUBLIC properties (Fully uppercase, which can be modified via CLI)
            if ($property -cmatch '^[A-Z_0-9]+$') {
                Write-Output "[PUBLIC] $property = $value"
            } else {
                Write-Output "         $property = $value"
            }
        }
        
        # Clean up COM references to release locks on the MSI file
        $view.Close()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($view) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($database) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($installer) | Out-Null
    }
    catch {
        Write-Error "Failed to read MSI properties: $_"
    }
} else {
    Write-Warning "MSI file not found at: $MsiPath"
}
