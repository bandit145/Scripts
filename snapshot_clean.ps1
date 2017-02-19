param(
    [parameter(Mandatory=$true)]
    [int]$days,
    [parameter(Mandatory=$true)]
    [string]$server
)
$ErrorActionPreference = "Stop"
Import-Module -Name VMware.VimAutomation.Core
try{
    Connect-VIServer $server -Force
}
catch {
    "Connection to Vcenter server failed" | Out-File log.txt -Append
}
$days = $days*-1
$date = Get-Date
$date = $date.AddDays($days)
foreach($snap in (Get-Snapshot *)){
    if($snap.created -lt $date){
         Remove-Snapshot -Snapshot $snap -Confirm:$false
    }
}