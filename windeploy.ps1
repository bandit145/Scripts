$session = New-PSSession -Computername $ipaddress -Credential $user
try{
	Invoke-Command -Session $session -ScriptBlock{
		Install-WindowsFeature -Name $feature -IncludeAllSubFeature -IncludeManagementTools
		Add-Computer -DomainName -NewName $pcname -Credential $domainuser

	}
}