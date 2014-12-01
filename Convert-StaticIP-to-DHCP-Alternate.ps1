$dns1 = "134.39.20.27"
$dns2 = "134.39.20.250"

Import-Module \\docs.ghc.local\Departments\Public\DHCPAlternateConfiguration\DHCPAlternateConfiguration

# Check if NIC is statically assigned.
$WMI_Nic = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"

if ($WMI_Nic.DHCPEnabled -ne "True") {
	# Get current nic
	$NicName = get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2" | select NetConnectionID
	$NicName = $NicName.NetConnectionID

	# Get static values
	$ipAddress = [System.Net.IPAddress]::parse($WMI_Nic.IPAddress)
	$gateway = [System.Net.IPAddress]::parse($WMI_Nic.DefaultIPGateway)
	$subnet = [System.Net.IPAddress]::parse($WMI_Nic.IPSubnet)
	$dns1 = [System.Net.IPAddress]::parse($dns1)
	$dns2 = [System.Net.IPAddress]::parse($dns2)

	# set static values to alternate ones
	"About to run this command: Set-DHCPAlternateConfiguration -NicName $NicName -IpAddress $ipAddress -SubnetMask $subnet -Gateway $gateway -DnsServer1 $dns1 -DnsServer2"
	Set-DHCPAlternateConfiguration -NicName $NicName -IpAddress $ipAddress -SubnetMask $subnet -Gateway $gateway -DnsServer1 $dns1 -DnsServer2 $dns2

	# set main nic to DHCP
	$WMI_Nic.EnableDHCP()

} else {
	"This computer is already configured for DHCP."
}

