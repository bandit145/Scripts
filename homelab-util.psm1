Function New-DomainController{
    param(
        [ValidateSet($true,$false)]
        [bool]$Dns = $false,
        [parameter(Mandatory=$true)]
        [pscredential]$Credential,
        [parameter(Mandatory=$true)]
        [string]$Domain,
        [parameter(Mandatory=$true)]
        [string]$ComputerName
        )

    $session = New-Pssession -ComputerName $ComputerName -Credential $Credential
    Invoke-Command -Session $session -Args $Dns, $Domain, $Credential -ScriptBlock{
        param($Dns, $Domain, $Credential)
        Install-WindowsFeature -Name "AD-Domain-Services"
        if($Dns -eq $true){
            Install-ADDSDomainController -DomainName $Domain -Credential $Credential -InstallDns
            exit
        }
        Install-ADDSDomainController -DomainName $Domain -Credential $Credential
    }
}
Function Set-StaticIp{
    param(
        [parameter(Mandatory=$true)]
        [pscredential]$Credential,
        [parameter(Mandatory=$true)]
        [string]$ComputerName
        )
    $session = New-Pssession -ComputerName $ComputerName -Credential $Credential
    Invoke-Command -Session $session -ScriptBlock{
        $addressfamily = "IPv4"
        $alias = "Ethernet0"
        $dnssuffix = "meme.com"
        $ipaddress = Get-NetIPAddress -InterfaceAlias $alias
        $ipaddress = $ipaddress.IPv4Address
        $dnsservers = Get-DnsClientServerAddress -InterfaceAlias $alias -AddressFamily $addressfamily
        $dnsservers = $dnsservers.ServerAddresses

         foreach ($ip in $ipaddress){
            if ($ip -like "*192.168.1.*"){
                Remove-NetIpAddress -InterfaceAlias $alias -Confirm:$false
                New-NetIpAddress -InterfaceAlias $alias -AddressFamily $addressfamily -PrefixLength 24 -IPAddress $ip -DefaultGateway "192.168.1.1"
                Set-DnsClient -InterfaceAlias $alias -ConnectionSpecificSuffix $dnssuffix
                Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses $dnsservers
            }
            else{
                Write-Host "No proper IP Found"
            }

        }
    }
}