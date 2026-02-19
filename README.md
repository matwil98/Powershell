# IIS Log Parser Module

A PowerShell module for parsing, analyzing, and formatting Internet Information Services (IIS) log files.

## Functions

### 1. `Get-IISLogFileHeaders`
**Description:** Extracts and returns the field headers from an IIS log file.

**Parameters:**
- `$logFilePath` (string) - The full path to the IIS log file.

**Returns:** Array of header field names (date, time, c-ip, cs-method, sc-status, cs-uri-stem, etc.)

**Usage Example:**
```powershell
$headers = Get-IISLogFileHeaders -logFilePath "C:\inetpub\logs\LogFiles\W3SVC1\u_ex210101.log"
```

---

### 2. `Get-IISLogFileData`
**Description:** Parses an IIS log file and extracts key fields (date, time, client IP, request method, status code, URI, query string, and referer). Outputs a simplified parsed log file to the `$logParsedDir` directory.

**Parameters:**
- `$logFilePath` (string) - The full path to the IIS log file to parse.

**Behavior:**
- Creates `$env:USERPROFILE\IISLogs\Parsed` directory if it doesn't exist
- Processes each non-comment line from the log file
- Extracts and writes key fields to a timestamped output file
- Displays processing time in seconds

**Usage Example:**
```powershell
Get-IISLogFileData -logFilePath "C:\inetpub\logs\LogFiles\W3SVC1\u_ex210101.log"
```

---

### 3. `Get-ParsedLogFileName`
**Description:** Lists all parsed log files in the parsed logs directory and prompts the user to select one by number. Returns the full path of the selected file.

**Returns:** Full file path of the selected parsed log file.

**Behavior:**
- Displays all `*_parsed.log` files sorted by last write time (newest first)
- Prompts user to enter a number (1-N) corresponding to their choice
- Validates input and returns the selected file path

**Usage Example:**
```powershell
$selectedFile = Get-ParsedLogFileName
```

---

### 4. `Get-IISUniqueLogUri`
**Description:** Extracts unique URIs from a parsed log file and writes them to a new log file. Uses a HashSet for efficient duplicate detection.

**Behavior:**
- Prompts user to select a parsed log file using `Get-ParsedLogFileName`
- Creates `$env:USERPROFILE\IISLogs\Unique` directory if needed
- Extracts unique request URIs and writes to a timestamped output file
- Displays processing time in seconds

**Usage Example:**
```powershell
Get-IISUniqueLogUri
```

---

### 5. `Get-FormattedLog`
**Description:** Formats parsed log data into a human-readable aligned format with columns for timestamp, client IP, request method, status code, URI, query string, and referer.

**Behavior:**
- Prompts user to select a parsed log file using `Get-ParsedLogFileName`
- Creates `$env:USERPROFILE\IISLogs\Formatted` directory if needed
- Outputs data with aligned columns for easy reading
- Writes results to a timestamped output file
- Displays processing time in seconds

**Usage Example:**
```powershell
Get-FormattedLog
```

---

### 6. `Get-IISRandomLog`
**Description:** Selects a random sample of entries from a parsed IIS log file. Useful for quick spot-checks or sampling large logs.

**Parameters:**
- `$Count` (int) - Number of random entries to return. Default: 10
- `$ParsedLogPath` (string) - Optional path to a specific parsed log file. If omitted, the function will prompt for a file using `Get-ParsedLogFileName`.

**Behavior:**
- Prompts user to select a parsed log file when `$ParsedLogPath` is not provided
- Reads the parsed log file and returns `$Count` random lines (or fewer if file is smaller)
- Optionally writes the sample to `$env:USERPROFILE\IISLogs\Samples` with a timestamped filename

**Usage Example:**
```powershell
Get-IISRandomLog -Count 20
```

---

## Installation

### Option 1: Copy to PowerShell Modules Directory

1. **Locate your PowerShell Modules directory:**
   ```powershell
   $PROFILE | Split-Path
   ```
   Or use the default module path:
   ```powershell
   $env:PSModulePath -split ";"
   ```

2. **Create a module folder:**
   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\Documents\PowerShell\Modules\IISModule" -Force
   ```

3. **Copy the module file:**
   ```powershell
   Copy-Item -Path "C:\path\to\IISModule.psm1" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\IISModule\" -Force
   ```

4. **Create a module manifest (optional but recommended):**
   ```powershell
   New-ModuleManifest -Path "$env:USERPROFILE\Documents\PowerShell\Modules\IISModule\IISModule.psd1" `
     -ModuleVersion "1.0.0" `
     -Author "Your Name" `
     -Description "IIS Log Parser Module" `
     -RootModule "IISModule.psm1"
   ```

5. **Import the module:**
   ```powershell
   Import-Module -Name IISModule
   ```

### Option 2: Download from GitHub (if available)

```powershell
git clone https://github.com/matwil98/IISModule.git
cd IISModule
Copy-Item -Path "IISModule.psm1" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\IISModule\" -Force
Import-Module -Name IISModule
```

### Option 3: Download and Run Directly

```powershell
# Download the module
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/matwil98/IISModule/main/IISModule.psm1" `
  -OutFile "$env:TEMP\IISModule.psm1"

# Import directly
Import-Module -Name "$env:TEMP\IISModule.psm1"
```

## Verify Installation

After installation, verify the module is loaded:

```powershell
Get-Module -Name IISModule
Get-Command -Module IISModule
```

You should see all 6 functions listed.

## Output Directories

The module automatically creates and organizes logs in subdirectories under `$env:USERPROFILE\IISLogs`:

- **Parsed:** Contains simplified parsed log files
- **Unique:** Contains files with unique URIs extracted from parsed logs
- **Formatted:** Contains human-readable formatted log files
- **Samples:** Contains random sample outputs generated by `Get-IISRandomLog`

## Requirements

- PowerShell 5.0 or higher
- Windows operating system (IIS is Windows-only)
- Read access to IIS log files
- Write access to `$env:USERPROFILE\IISLogs` directory
