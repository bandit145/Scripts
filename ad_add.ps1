#todo: move to ou for user
param(
	[parameter(Mandatory=$true)]
	[string]$file
)
$csv = Import-CSV $file

for($person in $csv){
	try:
		$splitname = $person.name.split("")
		$length = $splitname.length
		$usrname = $splitname[0][0] $splitname[$length -1] 
		New-ADUser -Name $usrname -GivenName $splitname[0] -SurName $splitname[1..$length -1]
		Add-ADGroupMember -Identity $person.group -Member $usrname

	catch:#duplicate usr accounts, group does not exist, etc.


} 