#Configure configmgr intergration
Function New-Cred{
    <#
    .SYNOPSIS
    This Is a helper function that returns a PSSession from the data passed to it.
    .DESCRIPTION
    The function supports implicict winrm (withn your logged in account), explicit, and CredSSP Authentication
    .EXAMPLE
    Implicit Session: New-Cred -Computer Domaincomp
    Explicit Session: New-Cred -Credential "User" -Computer Domaincomp
    CredSSP Session: New-Cred -Credential "User" -Computer Domaincomp -CredSSP $true
    .Notes
    CredSSP must be enabled through a GPO or other means on the machines you are trying to connect to (See link section).
    CredSSP always needs explicit credentials, it passes the credentials directly to the machine you initiate a session with.
    This solves the Kerberos double hop issue (Accessing an smb share through the remoted into machine for example)
    .Link
    CredSSP GPO: https://msdn.microsoft.com/en-us/library/windows/desktop/bb204773(v=vs.85).aspx
    CredSSP Manual: https://blogs.technet.microsoft.com/heyscriptingguy/2012/11/14/enable-powershell-second-hop-functionality-with-credssp/
    #>
    param([String]$Credential, [String]$Computer, [bool]$CredSSP)
    if($Credential -eq "none"){
        $session = New-PSSession -ComputerName $Computer
    }
    elseif($CredSSP){
        $creds = Get-Credential -UserName $Credential -Message "Enter Credentials"
        $session = New-PSSession -ComputerName $Computer -Credential $creds -Authentication "CredSSP" 
    }
    else{
        $creds = Get-Credential -UserName $Credential -Message "Enter Credentials"
        $session = New-PSSession -ComputerName $Computer -Credential $creds
    }

    return $session
}

Function New-WSUSServer{
    <#
    .SYNOPSIS
    New-WSUSServer deploys the WSUS server role to the targeted computer and does the initial sync
    .DESCRIPTION
    This cmdlet handles all options you would ever want from a base WSUS Install.
    .Example
    Basic: New-WSUSServer -Computer Domaincomp -ContentDir "C:\WSUSdata"
    Language Specification: New-WSUSServer -Computer Domaincomp -ContentDir "C:\WSUSdata" -UpdateLanguages "ru"
    SQL Server: New-WSUSServer -Computer Domaincomp -ContentDir "C:\WSUSdata" -SQLServer SQL001
    Upstream WSUS server: New-WSUSServer -Computer Domaincomp -ContentDir "C:\WSUSdata" -UpstreamWSUS WSUS001
    .NOTES
    Default language is set to english
    UpstreamWSUS is set to false by default, but will force SSL if used

    #>
    param(
        [parameter(Mandatory=$true)]
        [String]$Computer,
        [String]$Credential = "none",
        [String]$SQLServer = "no",
        [parameter(Mandatory=$true)]
        [String]$ContentDir,
        [String]$UpstreamWSUS = "no",
        [String[]]$UpdateLanguages= @("en")
        )
    $ErrorActionPreference = "Stop"
    #Check to make sure user did not enter both sqlserver and contendir

    $session = New-Cred -Credential $Credential -Computer $Computer 
    Invoke-Command -Session $session -Args $SQLServer, $ContentDir, $UpstreamWSUS, $UpdateLanguages -ScriptBlock {
        param([String]$SQLServer,[String]$ContentDir, [String]$UpstreamWSUS,[String[]]$UpdateLanguages)
        if((Test-Path -Path "$ContentDir") -eq $false){
          New-Item -ItemType directory -Path "$ContentDir" | Out-Null 
        }
        if($SQLServer -eq "no"){
            Write-Host "Wid install..."
            Install-WindowsFeature -Name UpdateServices -IncludeManagementTools | Out-Null
            #& is the call operator
            #NOTE: wsusutil needs to be called directly because windows does not recognize it as an installed tool 
            #until reboot
            #Args a seperated by spacing
            &"C:\Program Files\Update Services\Tools\wsusutil.exe" "postinstall" "CONTENT_DIR=$ContentDir"
        }
        elseif($SQLServer -ne "no"){
            Write-Host "SQL server install..."
            Install-WindowsFeature -Name UpdateServices-Services,UpdateServices-DB -IncludeManagementTools | Out-Null
            &"C:\Program Files\Update Services\Tools\wsusutil.exe" "postinstall" "SQL_INSTANCE_NAME=$SQLServer CONTENT_DIR=$ContentDir"
        }

        if($UpstreamWSUS -eq "no"){
            Set-WsusServerSynchronization -SyncFromMU
        }
        else{
            Set-WsusServerSynchronization -USsServerName $UpstreamWSUS -UseSSL
        }
        #praise scripting guy 
        #https://blogs.technet.microsoft.com/heyscriptingguy/2013/04/15/installing-wsus-on-windows-server-2012/
        $wsus = Get-WSUSServer
        #Base configuration
        $wsusconfig = $wsus.GetConfiguration()
        $wsusconfig.AllUpdateLanguagesEnabled = $false
        $wsusconfig.SetEnabledUpdateLanguages($UpdateLanguages)
        $wsusconfig.Save()
        #Subscriptions and start sync to get latest subs
        $subscription = $wsus.GetSubScription()
        $subscription.StartSynchronizationForCategoryOnly()
        #LOADING BAR
        #decided to steal scriping guys loading bar because it was neat-o
        Write-Host "[" -NoNewline
        While($subscription.GetSynchronizationStatus() -ne "NotProcessing"){
            Write-Host "#" -NoNewline
            Start-Sleep -Seconds 5
        }
        Write-Host "]"

        Write-Host "Completed! Please select the subcriptions you wish to pull updates for from WSUS admin console"

    }
}

Function New-SCCMCfgServer{
    <#
    .SYNOPSIS
    New-SCCMCfgServer configures the targeted server as an SCCM Config Manager server
    .DESCRIPTION
    Installs all prerequisites for SCCM Configuration Manager and installs it
    .EXAMPLE
    Base: New-SCCMCCfgServer -Computer domaincomp -UnattendedFile C:\unattended.ini -SCCMLocation \\fileshare\SCCM -ADKLocation \\fileshare\ADK -DotNetLocation \\fileshare\dotnet


    #>
    param(
        [String]$Credential = "none",
        [parameter(Mandatory=$true)]
        [String]$Computer,
        [parameter(Mandatory=$true)]
        [String]$UnattendedFile,
        [parameter(Mandatory=$true)]
        [String]$SCCMLocation,
        [parameter(Mandatory=$true)]
        [String]$ADKLocation,
        [parameter(Mandatory=$true)]
        [String]$DotNetLocation
        )

    $ErrorActionPreference= "Stop"
    $infolderlocation = "\SMSSETUP\BIN\X64\"
    $session = New-Cred -Credential $Credential -Computer $Computer -CredSSP $true
    Copy-Item -Path $UnattendedFile -Destination C:\Unattended.ini -ToSession $session 
    Invoke-Command -Session $session -Args $SCCMLocation, $infolderlocation, $ADKLocation,$DotNetLocation -Scriptblock{
        param([String]$SCCMLocation, [String]$infolderlocation, [String]$ADKLocation, [String]$DotNetLocation)
        Write-Host "Installing .NET 3.5"
        Install-WindowsFeature -Name "net-framework-core" -source "$DotNetLocation\dotnetfx35.exe"
        $installed = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName
        if($installed -like "*Assesment and Deployment Toolkit*" ){
            Write-Host "Installing ADK"
            & "$ADKLocation/adksetup.exe" "/quiet" "/installpath" "C:\adk"
            if($LastExitCode -ne 0){
            Write-Host "setup.exe failed!"
            Exit
            }
        }
       
        if($installed -like "*System Center Configuration*"){
            Write-Host "Installing SCCM Config Manager..."
            & "$SCCMLocation$infolderlocation\setup.exe" "/script" "c:\UnattendedFile.ini"
            if($LastExitCode -ne 0){
                Write-Host "setup.exe failed!"
                Exit
            } 
        }
       
        
        Remove-Item -Path c:\UnattendedFile.ini | Out-Null
        Write-Host "Done!"

    }
}

Function New-MSSQLServer{
    #needs Domain Admin permissions
    param(
        [parameter(Mandatory=$true)]
        [String]$Computer,
        [String]$Credential= "none",
        [String]$Features = @("SQL"),
        [parameter(Mandatory=$true)]
        [String]$InstallerLocation,
        [parameter]$SQLSysadminAccnts = @("Administrator"),
        [parameter(Mandatory=$true)]
        [String]$InstanceID
        )
    $ErrorActionPreference = "Stop"
    $session = New-Cred -Credential $Credential -CredSSP $true
    $agtsvcaccount = Read-Host "Enter account for SQL Server Agent Service"
    $agtsvcaccount = Read-Host "Enter password for SQL Server Agent Service account" -AsSecureString
    $sqlsvcaccount = Read-Host "Enter account for SQL Server Service (Can Be Domain\User)"
    $sqlsvcpassword = Read-Host "Enter SQL Server Agent Service Account password" -AsSecureString
    Invoke-Command -Session $Session -Args -ScriptBlock{

    }
    #Add service principle name for remote SQL Server
    & "setspn.exe" "-S" "MSSQLSvc/$Computer':1433'"



}

Function Add-WinServer{
    <#
    .SYNOPSIS
    Adds a windows server to the domain
    .DESCRIPTION
    Used to add a windows server to the domain and put in a specific OU/CN
    .EXAMPLE
    Base: Add-WinServer -Credential "Administrator" -HostName newcomputername -Computer 192.168.1.2 -OU "ou=test servers, dc=ncc,dc=commnet,dc=edu" -DomainJoinCred (Get-Credential "admin@domain.domain")
    Specify Domain: Add-WinServer -Credential "Administrator" -Domain domain.domain -HostName newcomputername -Computer 192.168.1.2 -OU "ou=test servers, dc=ncc,dc=commnet,dc=edu" -DomainJoinCred (Get-Credential "admin@domain.domain")
    .NOTES
    Domain defaults to ncc.commnet.edu when not specified 
    #>
    param(
        [parameter(Mandatory=$true)]
        $HostName,
        [parameter(Mandatory=$true)]
        $Computer,
        [parameter(Mandatory=$true)]
        [String]$Credential,
        [String]$Domain = "ncc.commnet.edu",
        [parameter(Mandatory=$true)]
        [String]$OU,
        [parameter(Mandatory=$true)]
        [PSCredential]$DomainJoinCred
        )
    $ErrorActionPreference = "Stop"
    $session = New-Cred -Credential $Credential -Computer $Computer

    Invoke-Command -Session $session -Args $HostName, $Computer, $DomainJoinCred, $OU -ScriptBlock{
        param([String]$HostName, [PSCredential]$DomainJoinCred, [String]$OU)
        Add-Computer -Domain $Domain -New-Name $HostName -Credential $DomainJoinCred -OUPath $OU -Restart

    }

}

Function New-WindowsServer{
    param(
        [parameter(Mandatory=$true)]
        [String]$Name,
        [parameter(Mandatory=$true)]
        [String]$Template,
        [parameter(Mandatory=$true)]
        [String]$Server
        )
    $ErrorActionPreference = "Stop"
    Import-Module VMWare.VimAutomation.Core
    New-VM -Name $Name -Template $Template
    Write-Host "Deploying VM:"
    do{
        Write-Host "#" -NoNewline
        Start-Sleep -Seconds 5
    }
    until(Get-VMGuest -VM $Name)
    do{
        $data = (Get-VMGuest -VM $Name).IPAddress
        #ipv4 regex
        $ipaddr = Select-String -Pattern "/d{1-3}./d{1-3}./d{1-3}./d{1-3}" -Path (Get-VMGuest -VM $Name).IPAddress | Select-Matches
    }
    until($ipaddr -match "/d{1-3}./d{1-3}./d{1-3}./d{1-3}")
    Write-Host "Deployed VM $Name"
    Write-Host "IPv4 Address is: "
    return $ipaddr
}

