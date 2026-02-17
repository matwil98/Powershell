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
        $fileHeaders = Get-Content -Path $logFilePath | Where-Object {$_.StartsWith("#Fields:")} | Select-Object -First 1
        if($fileHeaders.Length -gt 0){
            $headers = $fileHeaders -replace("#Fields: ", "") -split " "
            return $headers
        }
    }
}