#This powershell script looks at for inactive users on AD and disables the accounts
$date = Get-Date
$date = $date.AddDays(-20)
foreach($user in Search-ADAccount -AccountInactive -DateTime $date -Usersonly){
	if(Get-ADuser -Identity $user -Properties memberOf | Where-Object {($_.memberOf -match "enter group here")}){
		Disable-ADAccount -Identity $user
	}
}