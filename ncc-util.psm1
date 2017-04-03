#Configure configmgr intergration
Function Check-Creds{
    param([String]$Credential, [String]$Computer)
    if($Credential -eq "none"){
        $session = New-PSSession -ComputerName $Computer
    }
    else{
        $creds = Get-Credential -UserName $Credential -Message "Enter Credentials"
        $session = New-PSSession -ComputerName $Computer -Credential $creds
    }

    return $session
}

Function New-WSUSServer{
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

    $session = Check-Creds -Credential $Credential -Computer $Computer 
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
    param(
        [String]$Credential = "none",
        [parameter(Mandatory=$true)]
        [String]$Computer,
        [parameter(Mandatory=$true)]
        [String]$UnattendedFile,
        [parameter(Mandatory=$true)]
        [String]$InstallerLocation
        )

    $ErrorActionPreference= "Stop"
    $infolderlocation = "/SMSSETUP/BIN/X64/"
    $file = Get-Content $UnattendedFile
    $session = Check-Creds -Credential $Credential -Computer $Computer
    Invoke-Command -Session $session -Args $file, $InstallerLocation ,$infolderlocation-Scriptblock{
        param([String]$file,[String]$InstallerLocation, [String]$infolderlocation)
        $file | Out-File C:\UnattendedFile.ini
        Write-Host "Running pre-req checks for SCCM"
        #Run prereq checks
        & "$InstallerLocation$infolderlocation/prereqchk.exe" "/LOCAL"
        if($LastExitCode -ne 0){
            Write-Host "prereqchk.exe failed!"
            Exit-PSSession
        }

        Write-Host "Installing SCCM Config Manager..."
        & "$InstallerLocation$infolderlocation/setup.exe" "/script" "c:\UnattendedFile.ini"
        if($LastExitCode -ne 0){
            Write-Host "setup.exe failed!"
            Exit-PSSession
        }
        
        Remove-Item -Path c:\UnattendedFile.ini | Out-Null
        Write-Host "Done!"

    }
}

Function New-MSSQLServer{
    param(
        [parameter(Mandatory=$true)]
        [String]$Computer,
        [String]$Credential= "none",
        [String]$Features = @("SQL"),
        [parameter(Mandatory=$true)]
        [String]$InstallerLocation,
        [parameter]$SQlSysadminAccnts = @("Administrator"),
        [parameter(Mandatory=$true)]
        [String]$InstanceID
        )
    $ErrorActionPreference = "Stop"
    $session = Check-Creds -Credential $Credential
    $agtsvcaccount = Read-Host "Enter account for SQL Server Agent Service"
    $agtsvcaccount = Read-Host "Enter password for SQL Server Agent Service account" -AsSecureString
    $sqlsvcaccount = Read-Host "Enter account for SQL Server Service (Can Be Domain\User)"
    $sqlsvcpassword = Read-Host "Enter SQL Server Agent Service Account password" -AsSecureString



}

Function Add-WinServer{
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
    $session = Check-Creds -Credential $Credential -Computer $Computer

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

