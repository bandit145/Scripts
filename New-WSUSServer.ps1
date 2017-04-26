param(
    [parameter(Mandatory=$true)]
    [String]$Computer,
    [String]$Credential = $false,
    [String]$SQLServer = $false,
    [parameter(Mandatory=$true)]
    [String]$ContentDir,
    [String]$UpstreamWSUS = $false,
    [String[]]$UpdateLanguages= @("en")
    )
$ErrorActionPreference = "Stop"
Function Check-Creds{
    param([String]$Credential, [String]$Computer)
    if(!$Credential){
        $session = New-PSSession -ComputerName $Computer
    }
    else{
        $creds = Get-Credential -UserName $Credential -Message "Enter Credentials"
        $session = New-PSSession -ComputerName $Computer -Credential $creds
    }

    return $session
}
#Check to make sure user did not enter both sqlserver and contendir

$session = Check-Creds -Credential $Credential -Computer $Computer 
Invoke-Command -Session $session -Args $SQLServer, $ContentDir, $UpstreamWSUS, $UpdateLanguages -ScriptBlock {
    param([String]$SQLServer,[String]$ContentDir, [String]$UpstreamWSUS,[String[]]$UpdateLanguages)
    if((Test-Path -Path "$ContentDir") -eq $false){
      New-Item -ItemType directory -Path "$ContentDir" | Out-Null 
    }
    if(!$SQLServer){
        Write-Host "Wid install..."
        Install-WindowsFeature -Name UpdateServices -IncludeManagementTools | Out-Null
        #& is the call operator
        #NOTE: wsusutil needs to be called directly because windows does not recognize it as an installed tool 
        #until reboot
        #Args a seperated by spacing
        &"C:\Program Files\Update Services\Tools\wsusutil.exe" "postinstall" "CONTENT_DIR=$ContentDir"
    }
    else($SQLServer){
        Write-Host "SQL server install..."
        Install-WindowsFeature -Name UpdateServices-Services,UpdateServices-DB -IncludeManagementTools | Out-Null
        &"C:\Program Files\Update Services\Tools\wsusutil.exe" "postinstall" "SQL_INSTANCE_NAME=$SQLServer CONTENT_DIR=$ContentDir"
    }

    if(!$UpstreamWSUS){
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

