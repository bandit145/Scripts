#!/usr/bin/env powershell
param(
    [parameter(Mandatory=$true)]
    [string]$server,
    [parameter(Mandatory=$true)]
    [string]$template,
    [parameter(Mandatory=$true)]
    [string]$vmname
    )
$ram = New-Object System.Collections.ArrayList 
$vmhost = @{}
Import-Module VMWare.VimAutomation.Core -ErrorAction "SilentlyContinue"
Import-Module PowerCLI.ViCore -ErrorAction "SilentlyContinue"
$credential = Get-Credential
Connect-VIServer -Server $server -Credential $credential
$hosts = Get-VMHost
#make vmhost hash table correspond to open memeory and add open memeory to its own list
foreach($box in $hosts){
    $sub = $box.MemoryTotalGB - $box.MemoryUsageGB
    $vmhost.Add($sub, $box.Name)
    $ram.Add($sub)
}
$ram = $ram | Sort-Object -Descending #sort memory open from largest amount to smallest amount
#loop through ram arraylist and try to deploy to hosts
foreach($num in $ram){
    New-VM -VMHost $vmhost.$num -Template $template -Name $vmname  -ErrorAction "SilentlyContinue" | Wait-Task
    Start-VM -VM $vmname -ErrorAction "SilentlyContinue"
    Start-Sleep -s 30
    if($data = Get-VMGuest -VM $vmname -ErrorAction "SilentlyContinue"){
        Write-Host $vmname ip address is $data.IPAddress
        exit
    }
}