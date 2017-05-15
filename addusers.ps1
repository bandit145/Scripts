<#
    .SYNOPSIS
    This script takes new user data from a csv file and creates them, it also assaigns
    them to their groups and OUs
    .EXAMPLE
    ./adduasers.ps1 -CSVFile file.csv
    .NOTES
    If user is not admin they are put in default User OU with default Domain\Users group
    .LINK
    https://github.com/bandit145/Scripts

#>

param (
	[Parameter(Mandatory = $true)]
	[String]$CSVFile
)
$ErrorActionPreference = "Stop"
Import-Module -Name ActiveDirectory
$adminpath = "ou=admins,dc=meme,dc=com"
$domain = "meme.com"
$data = Import-CSV -Path $csvfile
$accountous = Get-ChildItem "AD:\dc=meme,dc=com"

#problems with script, if the script fails and you rerun the csv it will fail again
#because new-aduser will error on the users it created successfully
foreach( $user in $data){
    New-ADUser -Name (-join($user.first," ",$user.last)) `
            -SamAccountName (-join($user.first[1]),$user.last)`
            -DisplayName (-join($user.last, " , ",$user.first))`
            -AccountPassword (Read-Host "Enter Password for User: " (-join($user.first[1]),$user.last) -AsSecureString)`
            -UserPrincipalName (-join($user.first[1]),$user.last,"@$domain")`
            -Enabled $True`

    if ($user.type -eq "admin"){
        $moveuser = Get-ADUser -Identity (-join($user.first[1]),$user.last)
        Move-ADUser -Identity $moveuser.DistinguishedName -TargetPath $adminpath
        Add-ADGroupMember -Identity "admins" -Members $moveuser
    }
}

Write-Host $data.Count" Accounts Created"