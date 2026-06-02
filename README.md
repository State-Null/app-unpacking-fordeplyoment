# app-unpacking-fordeplyoment

A collection of lightweight, dependency-free PowerShell utility scripts designed for application packaging engineers, systems administrators, and deployment specialists (SCCM / Intune / MDT). 

These tools help you discover silent installation parameters, find where applications save their settings (Registry or AppData), and track configurations to build robust deployment packages.

## 🛠️ Included Tools

### 1. Registry Snapshot (`reg-snapshot.ps1`)
Takes a snapshot of a registry hive (e.g., `HKCU` or `HKLM`), pauses to let you change settings in an application's GUI, and then takes a second snapshot to compare and output the differences.
* **Best for:** Finding which registry keys/values control application settings or license states.
* **Usage:** 
  1. Open the script and set `$RegistryRoot` and `$FilterKeyword` at the top.
  2. Run the script in an administrative PowerShell terminal.
  3. Change the settings in your target app.
  4. Press any key in the terminal to view the differences.

---

### 2. AppData/ProgramData Tracker (`app-program-data-tracker.ps1`)
Tracks file creations, modifications, and deletions in a target folder structure (like `AppData` or `ProgramData`).
* **Best for:** Finding configuration XMLs, INI files, JSON profiles, or logs modified when application settings change.
* **Usage:** 
  1. Open the script and configure `$FolderPath` and `$FilterKeyword`.
  2. Run the script in an administrative PowerShell terminal.
  3. Modify settings in your app.
  4. Press any key in the terminal to see which files were added or modified.

---

### 3. MSI Property Extractor (`msi-property-extractor.ps1`)
Queries the internal database of a `.msi` installer file and lists all properties. It automatically highlights **`[PUBLIC]`** properties (fully uppercase) which can be overridden directly via the command line.
* **Best for:** Discovering silent installation switches, autostart configurations, directory variables, and auto-update toggles.
* **Usage:**
  1. Set `$MsiPath` to point to your target `.msi` file.
  2. Run the script to output the property list.
  3. Customize your silent installation command (e.g., `msiexec /i installer.msi PUBLIC_PROPERTY=value /qn`).

---

## 📋 Requirements
* **OS:** Windows 7 / Windows Server 2008 R2 or newer.
* **Shell:** PowerShell 3.0 or higher.
* **Privileges:** Administrator rights are required for `reg-snapshot.ps1` and `app-program-data-tracker.ps1` to query system directories and registry hives.

## 🤝 Contributing
Contributions, issue reports, and new utility ideas are welcome! Feel free to open a Pull Request.
