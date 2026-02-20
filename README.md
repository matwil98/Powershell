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
**Description:** Generates random IIS log entries for testing purposes. Creates a sample log file with randomly generated entries containing various HTTP methods, status codes, URIs, and client IPs.

**Parameters:**
- None (prompts user for input)

**Behavior:**
- Prompts user to enter the number of random log entries to generate
- Creates `$env:USERPROFILE\IISLogs` directory if needed
- Generates entries with random values from predefined lists (methods, status codes, URIs, IPs, etc.)
- Writes output to a timestamped `_random.log` file
- Displays completion message

**Usage Example:**
```powershell
Get-IISRandomLog
```

---

### 7. `Get-IISLogMenu`
**Description:** Interactive menu-driven interface for accessing all IIS log parsing functions. Provides a persistent menu that allows users to perform multiple operations without re-launching the function.

**Behavior:**
- Displays an interactive menu with 5 options:
  1. Parse IIS Log File - Calls `Get-IISLogFileData`
  2. Get Unique URIs from Parsed Log - Calls `Get-IISUniqueLogUri`
  3. Get Formatted Log Output - Calls `Get-FormattedLog`
  4. Generate Random IIS Log File - Calls `Get-IISRandomLog`
  5. Exit - Closes the menu
- After completing an operation (options 1-4), the menu returns and prompts the user to press Enter
- The menu loops continuously until the user selects option 5
- Validates user input and displays error messages for invalid choices

**Usage Example:**
```powershell
Get-IISLogMenu
```

**Example Workflow:**
1. Run `Get-IISLogMenu`
2. Enter `1` to parse an IIS log file
3. Press Enter to return to the menu
4. Enter `2` to extract unique URIs from the parsed log
5. Press Enter to return to the menu
6. Enter `5` to exit

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
