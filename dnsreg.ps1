#Pulls data from sensu and updates DNS/DHCP entries
$dnsserver = "DC1.meme.com"
$dhcpserver = "DC1.meme.com"
#get absolute path of script for the server.txt file
$path = Get-Location
$path = -join($path.path,"\server.txt")
$data = Invoke-RestMethod -Method GET -uri http://sensu.meme.com:4567/clients
$existing_servers = Get-Content -Path $path
$Newinv = New-Object System.Collections.ArrayList
foreach($existing_server in $existing_servers){
	$Newinv.Add($existing_server)
}

foreach($name in $data.name){
	if ($name -NotIn $Newinv){
		$Newinv.Add($name)
		$address = Invoke-RestMethod -Method GET -uri http://sensu.meme.com:4567/clients/$name
		Get-DhcpServerv4Lease -IPAddress $address.address -ComputerName $dhcpserver | Add-DhcpServerv4Reservation -ComputerName $dhcpserver
		Add-DnsServerResourceRecordA -ZoneName meme.com -Name $name -IPv4Address $address.address -ComputerName $dnsserver
	}
}
foreach($name in $existing_servers){
	if($name -NotIn $data.name){
		$Newinv.Remove($name)
		$ipaddr = Get-DNSServerResourceRecord -ZoneName meme.com -Name $name -ComputerName $dnsserver
		Remove-DnsServerResourceRecord -ZoneName meme.com -Name $name -ComputerName $dnsserver -RRType "A" -Force
		Remove-DhcpServerv4Reservation -IPAddress $ipaddr.RecordData.IPv4Address.IPAddressToString -ComputerName $dhcpserver
	}



}
$Newinv | Out-File $path