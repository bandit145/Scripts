param(
    [parameter(Mandatory=$true)]
    [int]$days,
    [parameter(Mandatory=$true)]
    [string]$server
)
Import-Module -Name VMware.VimAutomation.Core
Connect-VIServer $server -Force
$days = $days*-1
$date = Get-Date
$date = $date.AddDays($days)
foreach($snap in (Get-Snapshot *)){
    if($snap.created -lt $date){
         Remove-Snapshot -Snapshot $snap -Confirm:$false
    }
}