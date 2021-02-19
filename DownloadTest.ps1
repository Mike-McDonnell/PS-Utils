

#Download function usage DownlaodTest {Uri} {Iteration} e.g DownlaodTest "https://www.google.com" 10
function DownloadTest {

    Param(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $FileUrl,
    [Parameter(Mandatory=$false, Position=1)]
    [bool] $ReturnNAT = $false,
    [Parameter(Mandatory=$false, Position=2)]
    [int] $Iterations = 5,
    [bool] $IgnoreTLSandCertificateCheck = $false
         )

    Write-Host ""
    Write-Host "Download Test v1.0 - download bandwidth utility"
    Write-Host ""

    $returnValue = ""

    If($IgnoreTLSandCertificateCheck)
    {
        Write-Warning "Insecure Connection, ignoring Certificate validation and system TLS protocal requirements. Use only for testing"
        add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
        $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12,Tls13'
        [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

        
    }

    $Ping = Get-WMIObject Win32_PingStatus -Filter "Address = '$IP' AND ResolveAddressNames = TRUE"
    try
    {
        $uri = [System.Uri]$FileUrl
        If($uri.Host -ne $null) { $DestinationIP = ([System.Net.Dns]::Resolve($uri.Host).AddressList[0]) } 
        Else { $DestinationIP = ([System.Net.Dns]::Resolve($uri.OriginalString).AddressList[0]) }
    }
    catch { Write-Host $PSItem.Exception.InnerException.Message; break; }
    
    $returnValue += "Client Source IP: $($Ping.IPV4Address), Destination IP: $($DestinationIP)"
    Write-Host "Client Source IP: $($Ping.IPV4Address), Destination IP: $($DestinationIP)"

    If($ReturnNAT -eq $true)
    {
        $dest = "https://api.myip.com"
        $proxyurl = ([System.Net.WebRequest]::GetSystemWebproxy()).GetProxy($dest)
        
        try{ Write-Host "Client NAT(Public IP):$((Invoke-WebRequest $dest -Proxy $proxyurl -ProxyUseDefaultCredentials).Content)"; $returnValue += [Environment]::NewLine + "" }             
        catch{ Write-Host "Unable to retrive public IP adddress of client" }
    }

    $Results = [PSCustomObject]@{
        Times = New-Object Collections.Generic.List[double]($Iterations)
        BitRates = New-Object Collections.Generic.List[double]($Iterations)
        Count = $Iterations
        TotalContentLength = 0
        FailCount = 0
    }

    $totaltime = Measure-Command {
        For ($i=0; $i -lt $Results.Count; $i++)
        {
            Try
            {
                $time = Measure-Command {
                    $file = Invoke-WebRequest $FileUrl
                }
                $Results.Times.Add($time.TotalSeconds)
                $Results.TotalContentLength = $file.Content.Length
                $Results.BitRates.Add(($file.Content.Length/1024/1024) / $time.TotalSeconds)
                $Output = [string]::Format("$([Datetime]::UtcNow.ToString()), Host: {4}, Source IP: {5}, Destination IP: {6}, File: {0}, Time: {1}s, Rate :{2} MB/Sec, Size: {3} bytes", $file.BaseResponse.ResponseUri.OriginalString, $time.TotalSeconds, [Math]::Round((($file.Content.Length/1024/1024) / $time.TotalSeconds), 2), $file.Content.Length, $env:COMPUTERNAME, $Ping.IPV4Address, $DestinationIP )
            }
            catch { $Output = "Error Conencting to $($FileUrl):$($PSItem.Exception.InnerException.Message)"; $Results.BitRates.Add(0); $Results.FailCount++}
            Write-Host ($Output)
            $returnValue += [Environment]::NewLine + $Output
        }
        }

    Write-Host ""
    Write-Host "Download statistics for $($FileUrl)"
    Write-Host ([string]::Format("Total Iterations: {0}, Total Run Time: {1} ,Downloaded = {2}, Failed = {3} ({4}% Fail)", $Results.Count, $totaltime, ($Results.Count - $Results.FailCount), $Results.FailCount, ($Results.FailCount/$Results.Count) * 100))
    $returnValue += [Environment]::NewLine + ([string]::Format("Total Iterations: {0}, Total Run Time: {1} ,Downloaded = {2}, Failed = {3} ({4}% Fail)", $Results.Count, $totaltime, ($Results.Count - $Results.FailCount), $Results.FailCount, ($Results.FailCount/$Results.Count) * 100))
    Write-Host ([string]::Format("Minimum: {0:0.00} Mbps, Maximum: {1:0.00} Mbps, Avarage: {2:0.00} Mbps , {3:0.00} MB/sec", [Linq.Enumerable]::Min($Results.BitRates) * 8, [Linq.Enumerable]::Max($Results.BitRates) * 8, [Linq.Enumerable]::Average($Results.BitRates) * 8, [Linq.Enumerable]::Average($Results.BitRates)))
    $returnValue += [Environment]::NewLine + ([string]::Format("Minimum: {0:0.00} Mbps, Maximum: {1:0.00} Mbps, Avarage: {2:0.00} Mbps , {3:0.00} MB/sec", [Linq.Enumerable]::Min($Results.BitRates) * 8, [Linq.Enumerable]::Max($Results.BitRates) * 8, [Linq.Enumerable]::Average($Results.BitRates) * 8, [Linq.Enumerable]::Average($Results.BitRates)))

    return $returnValue
  }



