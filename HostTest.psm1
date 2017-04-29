Function Connect-Vcenter{
    param([String]$VIServer, $Credential)
    if($Credential){
        Connect-VIServer -Server $VIServer -Credential $Credential
    }
    else{
        Connect-VIServer -Server $VIServer
    }
    }

 Function Move-Host{
    param([String]$VMHost, [String]$ClusterName)
    Set-VMHost -VMHost $VMHost -State Maintenance 
    Move-VMHost -VMHost $VMHost -Destination $ClusterName
    Set-VMHost -VMHost $VMHost -State Connected
    }

Function New-HostTest{
    <#
        .DESCRIPTION
        This cmdlet automatically creates a cluster, pulls the specified esxi host out of its 
        cluster, adds it to the test created cluster, and stress tests it by creating vms.
        .SYNOPSIS
        This Script is for starting an esxi host stress test
        .EXAMPLE
        New-HostTest -VMHost Host -DataCenter datacenter -Template template -VIServer vcenter
        .NOTES
        If you do not specifiy a cluster name it will default to "test-clus"
    #>

    param(
        [parameter(Mandatory=$true)]
        [String]$VMCount,
        [parameter(Mandatory=$true)]
        [String]$VMHost,
        [parameter(Mandatory=$true)]
        [String]$DataCenter,
        [parameter(Mandatory=$true)]
        [String]$VIServer,
        [parameter(Mandatory=$true)]
        [String]$Template,
        [String]$ClusterName ="test-clus",
        [PSCredental]$Credential = $false
    )
    $ErrorActionPreference = "Stop"

    Connect-Vcenter -VIServer $VIServer -Credential $Credential
    #Check if cluster already exists
    if (!$ClusterName in (Get-Cluster -Name *).Name){
        New-Cluster -Name $ClusterName -Location $Datacenter
    }
    Move-Host -VMHost $VMHost -ClusterName $ClusterName
    $count = 0
    #stuff host full of vms
    while($count -le $VMCount ){
        New-VM -VMHost $VMHost -Name (-join("TestVM",$count)) -Template $Template | Out-Null
        Start-VM -VM (-join("TestVM",$count)) | Out-Null
        $count +=1
    }
    Write-Host "$VMHost VM stuffing completed!"
    Disconnect-VIServer -Force
}

Function Stop-HostTest{
    <#
        .DESCRIPTION
        This script tears down what New-HostTest does. Deletes the test cluster, removes all test vms,
        and moves the host back to its original cluster
        .SYNOPSIS
        This Script is for tearing down an esxi host stress test
        .EXAMPLE
        Stop-HostTest -VMHost Host  -VIServer vcenter
        .NOTES
        If you do not specifiy a cluster name it will default to "test-clus"
    #>
    param([parameter(Mandatory=$true)]
        [String]$VMHost,
        [parameter(Mandatory=$true)]
        [String]$VIServer,
        [String]$ClusterName ="test-clus",
        [PSCredental]$Credential = $false)

    $ErrorActionPreference = "Stop"
    Connect-Vcenter -VIServer $VIServer -Credential $Credential
    foreach($vm in (Get-VM)){
        if($vm.VMHost -eq $VMHost){
            #-Confirm for testing
            Stop-VM -VM $vm -WhatIf
            Remove-VM -VM $vm -DeletePermanently -WhatIf
        }
    }
    Move-Host -VMHost $VMHost -ClusterName $ClusterName
    Remove-Cluster -Cluster $ClusterName
    Write-Host "Host back in service in $ClusterName Cluster"
}