Powershell Utils.

1. Downloadtest - bandwidth tester (Download Only)

Usage. 

DownloadTest "https://www.w3.org/People/mimasa/test/imgformat/img/w3c_home.png" 5

e.g

$logFile = "C:\temp\$([Datetime]::UtcNow.ToString("MM-dd-yy"))-result.log"
"###Begin Log Entry: $([Datetime]::UtcNow.ToString()) ####" | Out-File $logFile -Force -Append 

$AvrOutPut = DownloadTest "https://www.w3.org/People/mimasa/test/imgformat/img/w3c_home.png" -ReturnNAT $false -Iterations 5

$AvrOutPut | Out-File $logFile -Force -Append 
"###End Log Entry: $([Datetime]::UtcNow.ToString()) ####" | Out-File $logFile -Force -Append 

2. TCPPing - Test tcp latancy 

usage.

TCPPing https://www.w3.org -Iterations 100
