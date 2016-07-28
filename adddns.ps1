#This takes a DHCP lease and makes it a reservation, This is mostly for linux servers which do not have their hostnames automatically
#picked up by windows domain controllers 
$user = Read-Host 'Domain admin name'
$session = New-PSSession -ComputerName dc1 -Credential meme\$user
try{
	Invoke-Command -Session $session -ScriptBlock {
		$ipaddress = Read-Host 'What IP address are you adding to dns? '
		$computername = Read-Host 'What will the computer address be? '
		Get-DhcpServerv4Lease -IPAddress $ipaddress -ComputerName dc1.meme.com | Add-DhcpServerv4Reservation
		Add-DnsServerResourceRecordA -zonename meme.com -name $computername -ipv4address $ipaddress
		Exit-PSSession
		}
}
catch{
	Write-Host "Some of your Information is incorrect"
}