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

        $headers = Get-IISLogFileDataHeaders -logFilePath $logFilePath
        if($headers.Count -gt 0){
            $reader = [System.IO.StreamReader]::new($logFilePath)
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
    if($parsedFiles.Count -gt 0){
        Write-Host "Parsed log files are below:" -ForegroundColor Yellow
        $parsedFiles | ForEach-Object {
            Write-Host $_.Name -ForegroundColor Cyan
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
