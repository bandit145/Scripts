<#
    .Synopsis
    New-FileShare creates a new smb file share on a provided computer and gives ntfs
    permissions to accounts in the provided hash table
    .Description
    This script is mostly idempotent and will only do the work if it detects the share
    does not already exist but file permissions are always applied so you can use this to update permissions.

    This technically violates powershell scripting best practices and in the future this might be changed
    and a "Set-FilePermission" cmdlet written.

    .Example
    Please reference https://msdn.microsoft.com/en-us/library/bb727008.aspx for info on the specific
    file permissions

    New-File -ComputerName file001 -Path C:\myshare -ShareName Files -Users @{"Users" = "Read"}

    New-File -ComputerName file001 -Path C:\myshare -ShareName Files -Users @{"Users"="FullControl"}

#>
param(
    [parameter(Mandatory=$true)]
    [string]$ComputerName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    [parameter(Mandatory=$true)]
    [string]$ShareName,
    [pscredential]$Credential = $null,
    [parameter(Mandatory=$true)]
    [hashtable]$Users

    )

if($Credential -eq $null){
    $session = New-PSSession -ComputerName $ComputerName
}
else{
    $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
}
$arg = @($Path, $ShareName, $Users) 
Invoke-Command -Session $session -ArgumentList $arg  -ScriptBlock {
    $Path, $ShareName, $Users = $args
    $ErrorActionPreference = "Stop"
    if(!(Test-Path $Path)){
        New-Item $Path -Type "Directory"
    }
    foreach($user in $Users){
        $acrule = New-Object System.Security.AccessControl.FileSystemAccessRule($user.keys,$user.values,"ContainerInherit,ObjectInherit","None","Allow")
        $acl = Get-Acl -Path $Path
        $acl.SetAccessRule($acrule)
        Set-Acl -Path $path -AclObject $acl
    }
    if(!((Get-SmbShare) -like "*$ShareName*")){
        New-SmbShare -Name $ShareName -Path $Path -FullAccess "Everyone"
    }
}