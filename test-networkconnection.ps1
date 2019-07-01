
$hostname = "www.google.com" # or www.centurylink.com, comcast.net, etc
$hostport = 80 # or 22, or 443
$timeout = 1000
$verbose = $false # true for errors only, false to see all status messages.

####################################################
# This script checks your computer NIC shows a connection status of OK
# then checks your gateway, then checks a foreign hostname - I suggest
# your ISPs website. Mine's centurylink

function CheckConnection() {
    param(
        $conn = $(throw "Please supply a connection object.")
    )
    try {
        $conn = Get-NetRoute | ? DestinationPrefix -eq '0.0.0.0/0' | Get-NetIPInterface | Where ConnectionState -eq 'Connected'
    } catch {
        $conn = $false
    }
    return $conn
}

function TestPort() {
    param(
        $hostname = $(throw "Please supply the hostname"),
        $port = $(throw "please provide the port number, 80 generally is what you want"),
        $timeout = $(throw "Provide the timeout in miliseconds, usually 1000 is good")
    )
    try {
        $requestCallback = $state = $null
        $client = New-Object System.Net.Sockets.TcpClient
        $beginConnect = $client.BeginConnect($hostname,$port,$requestCallback,$state)
        Start-Sleep -milli $timeOut
        if ($client.Connected) {
            $open = $true
        } else { 
            $open = $false 
        }
        $client.Close()
        [pscustomobject]@{hostname=$hostname;port=$port;open=$open}
    } catch {
        return $false
    }
}

function GetGateway() {
    Get-WmiObject -Class Win32_IP4RouteTable | where { $_.destination -eq '0.0.0.0' -and $_.mask -eq '0.0.0.0'} | Sort-Object metric1 | select nexthop, metric1, interfaceindex
}

"Testing computer connection ..."

$i = 0
do {
    $now = get-date
    $conn = $null
    $conn = CheckConnection -conn $conn
    $gateway = (GetGateway).NextHop

    start-sleep 1
    if ($conn.ConnectionState -eq "Connected") {
        if ($verbose) {
            Write-Host "... This computer is connected ... " -ForegroundColor Green
        }
    } else {
        Write-Host "... This computer is DISCONNECTED! X" -ForegroundColor Yellow
        write-host "[INFO] This computer disconnected at $now" -ForegroundColor Yellow
    }
    start-sleep 1
    if ((TestPort -hostname $gateway -port 22 -timeout 1000).open -eq $false) {
        Write-Host "... ... local router gateway connection FAILED! X" -ForegroundColor Yellow
        write-host "       [INFO] Local network disconnect at $now" -ForegroundColor Yellow
    } else {
        if ($verbose) {
            Write-Host "... ... local router gateway connects ok" -ForegroundColor Green
        }
    }
    start-sleep 1
    if ((TestPort -hostname $hostname -port $hostport -timeout $timeout).open -eq $false) {
        Write-Host "... ... ... ISP / external host connection FAILED! X" -ForegroundColor Yellow
        write-host "           [INFO] ISP/ External disconnect detected at $now ( $hostname : $hostport )" -ForegroundColor Yellow
    } else {
        if ($verbose) {
            Write-Host "... ... ... ISP / external host connects ok" -ForegroundColor Green
        }
    }
    start-sleep 1
    start-sleep 1
} while ($i -eq 0)
