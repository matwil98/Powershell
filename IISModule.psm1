$logTmpDir = "$env:USERPROFILE\IISLogs"
$logParsedDir = "$logTmpDir\Parsed"
$logFormattedDir = "$logTmpDir\Formatted"
$logUniqueDir = "$logTmpDir\Unique"

function Get-IISLogFileHeaders{
    param(
        [string]$logFilePath
    )

    if(-not(Test-Path $logFilePath)){
        Write-Error "Log file not found at path: $logFilePath"
        return
    } else {
        $fileHeaders = Get-Content -Path $logFilePath | Where-Object {$_.StartsWith("#Fields: ")} | Select-Object -First 1
        if($fileHeaders.Length -gt 0){
            $headers = $fileHeaders -replace("#Fields: ", "") -split " "
            return $headers
        }
    }
}

function Get-IISLogFileData{
    param(
        [string]$logFilePath
    )

    if(-not (Test-Path $logFilePath)){
        Write-Error "Log file not found at path: $logFilePath"
        return
    } else {

        if(-not (Test-Path $logParsedDir)){
            New-Item -Path $logParsedDir -ItemType Directory | Out-Null
            Write-Host "Created directory: $logParsedDir" -ForegroundColor Green
        } else {
            Write-Host "Directory already exists: $logParsedDir" -ForegroundColor Yellow
        }

        $headers = Get-IISLogFileHeaders -logFilePath $logFilePath
        if($headers.Count -gt 0){
            $reader = [System.IO.StreamReader]::new($logFilePath)
            $stoper = New-Object System.Diagnostics.Stopwatch
            $stoper.Start()
            Write-Host "Processing log file: $logFilePath" -ForegroundColor Blue
            try {
                $writer = [System.IO.StreamWriter]::new("$logParsedDir\$((Get-Date).ToString("yyyy-MM-dd_HHmmss"))" + "_parsed.log")
                while(-not $reader.EndOfStream){
                    $line = $reader.ReadLine()
                    if(-not $line.StartsWith("#")){
                        $date = $line.Split(" ")[$headers.IndexOf("date")]
                        $time = $line.Split(" ")[$headers.IndexOf("time")]
                        $clientIp = $line.Split(" ")[$headers.IndexOf("c-ip")]
                        $requestMethod = $line.Split(" ")[$headers.IndexOf("cs-method")]
                        $statusCode = $line.Split(" ")[$headers.IndexOf("sc-status")]
                        $requestUri = $line.Split(" ")[$headers.IndexOf("cs-uri-stem")]
                        $uriQuery = $line.Split(" ")[$headers.IndexOf("cs-uri-query")]
                        $referer = $line.Split(" ")[$headers.IndexOf("cs(Referer)")]
                        $writer.WriteLine("$date $time $clientIp $requestMethod $statusCode $requestUri $uriQuery $referer")
                    }
                }
                $stoper.Stop()
                Write-Host "Finished processing log file. Time taken: $($stoper.Elapsed.TotalSeconds) seconds" -ForegroundColor Green
            }
            finally {
                $reader.Close()
                $writer.Close()
            }
        }
    }
}

function Get-ParsedLogFileName {
    $parsedFiles = Get-ChildItem -Path $logParsedDir -Filter "*_parsed.log" | Sort-Object LastWriteTime -Descending
    $i = 1
    if($parsedFiles.Count -gt 0){
        Write-Host "Parsed log files are below:" -ForegroundColor Yellow
        $parsedFiles | ForEach-Object {
            Write-Host "$i) $($_.Name) " -ForegroundColor Cyan
            $i++
        }
        $choice = Read-Host "Enter the number corresponding to the parsed log file you want to use (1-$($parsedFiles.Count))"
        if($choice -match "^[1-9]\d*$" -and $choice -gt 0 -and $choice -le $parsedFiles.Count){
            return $parsedFiles[$choice - 1].FullName
        } else {
            Write-Error "Invalid choice. Please enter a number between 1 and $($parsedFiles.Count)"
            return
        }
    } else {
        Write-Error "No parsed log files found in directory: $logParsedDir"
        return
    }
}

function Get-IISUniqueLogUri {
    if(-not (Test-Path $logUniqueDir)){
        New-Item -Path $logUniqueDir -ItemType Directory | Out-Null
        Write-Host "Created directory: $logUniqueDir" -ForegroundColor Green
    } else {
        Write-Host "Directory already exists: $logUniqueDir" -ForegroundColor Yellow 
    }

    try{
        $parsedLogFile = Get-ParsedLogFileName
        if($parsedLogFile.Length -gt 0){
            $reader = [System.IO.StreamReader]::new($parsedLogFile)
            $writer = [System.IO.StreamWriter]::new("$logUniqueDir\$((Get-Date).ToString("yyyy-MM-dd_HHmmss"))" + "_unique_uri.log")
            
            try{
                $stoper = New-Object System.Diagnostics.Stopwatch
                $stoper.Start()
                Write-Host "Processing parsed log file for unique URIs: $parsedLogFile" -ForegroundColor Blue
                $hashSet = New-Object System.Collections.Generic.HashSet[string]
                while(-not $reader.EndOfStream){
                    $line = $reader.ReadLine()
                    $requestUri = $line.Split(" ")[5]
                    if(-not $hashSet.Contains($requestUri)){
                        $hashSet.Add($requestUri) | Out-Null
                        $writer.WriteLine($requestUri)
                    }
                }
                $stoper.Stop()
                Write-Host "Finished processing unique URIs. Time taken: $($stoper.Elapsed.TotalSeconds) seconds" -ForegroundColor Green
            }
            finally {
                $reader.Close()
                $writer.Close()
            }
        }
    } catch {
        Write-Error "No file selected for processing."
    }
}

function Get-FormattedLog {
    if(-not (Test-Path $logFormattedDir)){
        New-Item -Path $logFormattedDir -ItemType Directory | Out-Null
        Write-Host "Created directory: $logFormattedDir" -ForegroundColor Green
    } else {
        Write-Host "Directory already exists: $logFormattedDir" -ForegroundColor Yellow 
    }

    try{
        $parsedLogFile = Get-ParsedLogFileName
        if($parsedLogFile.Length -gt 0){
            $reader = [System.IO.StreamReader]::new($parsedLogFile)
            $writer = [System.IO.StreamWriter]::new("$logFormattedDir\$((Get-Date).ToString("yyyy-MM-dd_HHmmss"))" + "_formatted.log")
            $stoper = New-Object System.Diagnostics.Stopwatch
            $stoper.Start()
            Write-Host "Processing parsed log file for formatted output: $parsedLogFile" -ForegroundColor Blue
            try{
                while(-not $reader.EndOfStream){
                    $line = $reader.ReadLine()
                    $parts = $line.Split(" ")
                    if($parts.Length -ge 8){
                        $dateTime = "$($parts[0])T$($parts[1])Z"
                        $clientIp = $parts[2]
                        $requestMethod = $parts[3]
                        $statusCode = $parts[4]
                        $requestUri = $parts[5]
                        $uriQuery = $parts[6]
                        $referer = $parts[7]
                        $f = "{0, -20} {1, -15} {2, -10} {3, -10} {4, -30} {5, -30} {6, -50}" -f $dateTime, $clientIp, $requestMethod, $statusCode, $requestUri, $uriQuery, $referer
                        $writer.WriteLine("$f")
                    }
                }
                $stoper.Stop()
                Write-Host "Finished processing formatted log. Time taken: $($stoper.Elapsed.TotalSeconds) seconds" -ForegroundColor Green
            }
            finally {
                $reader.Close()
                $writer.Close()
            }
        }
    } catch {
        Write-Error "No file selected for processing."
    }
}

function Get-IISRandomLog{
    if(-not (Test-Path $logTmpDir)){
        New-Item -Path $logTmpDir -ItemType Directory | Out-Null
        Write-Host "Created directory: $logTmpDir" -ForegroundColor Green
    } else {
        Write-Host "Directory already exists: $logTmpDir" -ForegroundColor Yellow 
    }
    $responseCodes = @(200, 301, 400, 401, 403, 404, 500)
    $methods = @("GET", "POST", "PUT", "DELETE", "PATCH")
    $uris = @("/index.php", "/webpage/login.php", "/webpage/dashobard.php", "/api/data", "/api/update", "/contact.html")
    $sIp = @("192.168.1.10", "192.168.1.11", "192.168.1.12")
    $cIp = @("192.168.1.101", "192.168.1.102", "192.168.1.103")
    $uriQuery = @("id=123", "user=admin", "page=1", "search=term", "sort=asc")
    $userAgents = @("Mozilla/5.0+(Windows+NT+10.0;+Win64;+x64)", "Mozilla/5.0+(Macintosh;+Intel+Mac+OS+X+10_15_7)", "Mozilla/5.0+(Linux;+Android+10;+SM-G973F)", "Mozilla/5.0+(iPhone;+CPU+iPhone+OS+14_0+like+Mac+OS+X)", "Mozilla/5.0+(iPad;+CPU+iPad+OS+14_0+like+Mac+OS+X)")
    $usernames = @("LAB\admin", "LAB\developer", "LAB\dbadmin", "LAB\hr", "LAB\guest")
    $scSubstatus = @(0, 1, 2, 3, 4, 5)
    $scWin32Status = @(0, 1, 2, 3, 4, 5)
    $timeTaken = @(10, 20, 30, 40, 50, 60)
    $numEntries = Read-Host "Enter the number of random log entries to generate"
    if(-not ($numEntries -match "^\d+$") -or $numEntries -le 0){
        Write-Error "Invalid input. Please enter a positive integer for the number of log entries."
        return
    }
    $i = 0
    try {
        Write-Host "Generating random log entries..." -ForegroundColor Green
        $writer = [System.IO.StreamWriter]::new("$logTmpDir\$((Get-Date).ToString("yyyy-MM-dd_HHmmss"))" + "_random.log")
        $writer.WriteLine("#Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) sc-status sc-substatus sc-win32-status time-taken")
    
        while ($i -lt $numEntries) {
            $date = (Get-Date).ToString("yyyy-MM-dd")
            $time = (Get-Date).ToString("HH:mm:ss.fff")
            $sIpRandom = $sIp | Get-Random
            $cIpRandom = $cIp | Get-Random
            $user = $usernames | Get-Random
            $requestMethodRandom = $methods | Get-Random
            $statusCodeRandom = $responseCodes | Get-Random
            $requestUriRandom = $uris | Get-Random
            $uriQueryRandom = $uriQuery | Get-Random
            $userAgentRandom = $userAgents | Get-Random
            $scSubstatusRandom = $scSubstatus | Get-Random
            $scWin32StatusRandom = $scWin32Status | Get-Random
            $timeTakenRandom = $timeTaken | Get-Random

            $logEntry = "$date $time $sIpRandom $requestMethodRandom $requestUriRandom $uriQueryRandom 443 $user $cIpRandom $userAgentRandom $statusCodeRandom $scSubstatusRandom $scWin32StatusRandom $timeTakenRandom"
           
            $writer.WriteLine($logEntry)
            $i++
        }
    }
    finally {
        $writer.Close()
        Write-Host "Finished generating random log entries." -ForegroundColor Green
    }
}