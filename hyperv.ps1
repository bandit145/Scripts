param([Parameter(Mandatory=$true)]
				[string]$user,
				[Parameter(Mandatory=$true)]
				[string]$ipaddress,
				[Parameter(Mandatory=$true)]
				[string]$imagename,
				[Parameter(Mandatory=$true)]
				[string]$vmname,
				[Parameter(Mandatory=$true)]
				[int]$ram)
$ErrorActionPreference = "Stop"
$session = New-PSSession -Computername $ipaddress -Credential $user
try{
	Invoke-Command -Session $session -ScriptBlock{
		param($vmanme, $imagename, $ram)
		$imagepath = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\images\" 
		$vhd = Get-VHD -Path -join($imagepath, $imagename)
		New-VHD -Path "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$vmanme" -ParentPath -join($imagepath, $imagename) -Differncing
		New-VM -Name $vmname -Generation 1 -VHDPath "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$vmname" -MemoryStartupBytes $ram
		Set-VM -Name $vmname -AutomaticStartAction start
		Start-NM -Name $vmname
	} -Argumentlist $vmanme, $imagename, $ram
}
catch{
	"An Error has occured, most likely with authentication"
	$error[0].Exception

}