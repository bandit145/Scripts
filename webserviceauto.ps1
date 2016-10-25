#Pulls data from sensu and updates DNS/DHCP entries
$data = Invoke-RestMethod -uri http://sensu.meme.com:4567/clients
$existing_servers = Get-Content -Path server.txt
$Newinv = New-Object System.Collections.ArrayList
foreach($existing_server in $existing_servers){
	$Newinv.Add($existing_server)
}

foreach($name in $data.name){
	if ($name -NotIn $Newinv){
		$Newinv.Add($name)
		$address = Invoke-RestMethod -uri http://sensu.meme.com:4567/clients/$name
		Get-DhcpServerv4Lease -IPAddress $address.address -ComputerName $name | Add-DhcpServerv4Reservation
		Add-DnsServerResourceRecordA -ZoneName meme.com -name $name -IPv4Address $address.address
	}
}
foreach($name in $existing_servers){
	if($name -NotIn $data.name){
		$Newinv.Remove($name)
		$ipaddr = Get-DNSServerResourceRecord -ZoneName meme.com -Name $name
		Remove-DnsServerReseourceRecord -ZoneName meme.com -Name $name
		Remove-DhcpServerv4Reservation -ScopeID 192.168.1.0 -IPAddress $ipaddr.RecordData.IPv4Address.IPAddressToString
	}



}
$Newinv | Out-File server.txt


