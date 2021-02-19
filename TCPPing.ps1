function TCPPing {
    Param(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $Hostname,
    [Parameter(Mandatory=$false, Position=1)]
    [int] $Port = 443,
    [Parameter(Mandatory=$false, Position=2)]
    [int] $Iterations = 4
         )
Write-Host ""
Write-Host "TCP Ping v1.0 - Ping, latency utility"
Write-Host ""
try
{
    $IPAddress = ([System.Net.Dns]::Resolve($Hostname).AddressList[0])
}
catch { Write-Host $PSItem.Exception.InnerException.Message; break; }
Write-Host "TCP connect to $($IPAddress.IPAddressToString):$port"
Write-Host "$($iterations) iterations ping test:"
$times = New-Object Collections.Generic.List[double]($Iterations)
$loss = 0 
For ($i=0; $i -lt $times.Capacity; $i++)
{
    $Sock = New-Object System.Net.Sockets.Socket -ArgumentList "InterNetwork", "Stream", "Tcp"
    $Sock.Blocking = $true
    $ConnectTime = Measure-Command {
        $connect = $Sock.BeginConnect($IPAddress, $Port, $null, $null)
        $success = $connect.AsyncWaitHandle.WaitOne(5000, $true)
    }
    If ($success -eq $true)
    {
        $Sock.EndConnect($connect);
        $times.Add($ConnectTime.TotalMilliseconds);
        $result = "$($ConnectTime.TotalMilliseconds)ms"
    }
    Else 
    { 
        $result = "This operation returned because the timeout period expired"
        $Sock.Close()
        $times.Add(0); $loss++
    }
     Write-Host ([string]::Format("Connecting to {0}:{1}: from {2}:{3}: {4}", $IPAddress.IPAddressToString, $Port, $Sock.LocalEndPoint.Address.IPAddressToString, $Sock.LocalEndPoint.Port, $result))
    Start-Sleep 1
}
Write-Host ""
Write-Host "TCP connect statistics for $($IPAddress.IPAddressToString):$port"
Write-Host ([string]::Format("  Sent = {0}, Received = {1}, Lost = {2} ({3}% loss),", $times.Capacity, $times.Count, $loss, ($loss/$times.Capacity) * 100 ))
Write-Host ([string]::Format("  Minimum = {0:0.00}ms, Maximum = {1:0.00}ms, Average =  {2:0.00}ms", [Linq.Enumerable]::Min($times), [Linq.Enumerable]::Max($times), [Linq.Enumerable]::Average($times)))
}