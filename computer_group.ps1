param(
    [parameter(Mandatory=$true)]
    [String]$Group
    )
if($env:computername in (Get-ADgroupMember -Identity $Group) -eq $false){
        Add-ADGroupMember -Identity $Group -members $env:computername
}