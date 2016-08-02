#This takes a DHCP lease and makes it a reservation, This is mostly for linux servers which do not have their hostnames automatically
#picked up by windows domain controllers 
param (	[Parameter(Mandatory=$True)]
		[string]$admin,
		[Parameter(Mandatory=$True)]
		[string]$ipaddress,
		[Parameter(Mandatory=$True)]
		[string]$computername)
$session = New-PSSession -ComputerName dc1 -Credential meme\$admin
try{
	Invoke-Command -Session $session -ScriptBlock {
		Get-DhcpServerv4Lease -IPAddress $ipaddress -ComputerName dc1.meme.com | Add-DhcpServerv4Reservation
		Add-DnsServerResourceRecordA -zonename meme.com -name $computername -ipv4address $ipaddress
		Exit-PSSession
		}
}
catch{
	Write-Host "Some of your Information is incorrect"
}