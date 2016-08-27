param([Parameter(Mandatory=$True)]
				[string]$user,
				[string]$ipaddress,
				[string]$imagename,
				[string]$vmname,
				[int]$ram)
$ErrorActionPreference = "Stop"
$session = New-PSSession -Computername $ipaddress -Credential $user
$imagepath = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\images\" 
try{
	Invoke-Command -Session $session -ScriptBlock{
		$vhd = Get-VHD -Path -join($imagepath, $imagename)
		New-VHD -Path "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$vmanme" -ParentPath -join($imagepath, $imagename) -Differncing
		New-VM -Name $vmname -Generation 1 -VHDPath "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$vmname" -MemoryStartupBytes $ram
		Set-VM -AutomaticStartAction start
		Start-NM -Name $vmname
	}

}
catch{
	"An Error has occured, most likely with authentication"
	$error[0].Exception

}