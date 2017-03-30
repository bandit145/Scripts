param(
    [parameter(Mandatory=$true)]
    [String]$Computer,
    [PSCredential]$Credential,
    [String]$SQLServer,
    [String]$ContentDir,
    [String]$UpstreamWSUS,
    [String[]]$UpdateLangages= "en"
    )
$ErrorActionPreference = "Stop"
Function Check-Creds{
    param([PSCredential]$Credential, [String]$Computer)
    if($Credential -eq $null){
        $session = New-PSSession -ComputerName $Computer
    }
    else{
        $session = New-PSSession -ComputerName $Computer -Credential $Credential
    }

    return $session
}
#Check to make sure user did not enter both sqlserver and contendir
if($SQLServer -ne $null && $ContentDir -ne $null){
    Write-Host "Error: You cannot specify both an SQL Server and a WID dir"
    Exit-PSSession
}

$session = Check-Creds($Credential, $Computer) 

Invoke-Command -Session $session -Args $SQLServer, $ContentDir, $UpstreamWSUS, $UpdateLangages -ScriptBlock {
    param([String]$SQLServer,[String]$ContentDir, [String]$UpstreamWSUS,[String[]]$UpdateLangages)
    New-Item -ItemType directory -Path '"'+$ContentDir+'"'
    if($SQLServer -eq $null){
        Install-WindowsFeature -Name UpdateServices -IncludeManagementTools
        wsusutil.exe postinstall CONTENT_DIR='"'+$ContentDir+'"'
    }
    elseif($SQLServer -ne $null){
        Install-WindowsFeature -Name UpdateServices,UpdateServices-DB -IncludeManagementTools
        wsusutil.exe postinstall SQL_INSTANCE_NAME='"'+$SQLServer+'"' CONTENT_DIR='"'+$ContentDir+'"'
    }

    if($UpstreamWSUS -ne $null){
        Set-WsusServerSynchronization -SyncFromMU
    }
    else{
        Set-WsusServerSynchronization -USsServerName $UpstreamWSUS -UseSSL
    }

    $wsus = Get-WSUSServer
    #Base configuration
    $wsusconfig = $wsus.GetConfiguration()
    $wsusconfig.AllUpdateLanguagesEnabled = $false
    $wsusconfig.SetEnabledUpdateLanguages($UpdateLangages)
    $wsusconfig.Save()
    #Subscriptions and start sync to get latest subs
    $subscription = $wsus.GetSubScription()
    $subscription.StartSynchronizationForCategoryOnly()

    While($subscription.GetSynchronizationStatus() -ne "NotProcessing"){
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 5
    }

    Write-Host "Completed! Please select the platforms you wish to pull updates for from WSUS admin console"

}

