#Powershell implementation of DomJoinPermissions.CMD, Original CMD by Paul Williams, msresource.net
#
#written 11/9/2016
param(
    [Parameter(Mandatory = $true)]
    [string]$groupname,
    [Parameter(Mandatory = $true)]
    [string]$dn
    )
$namingcontextsperms = @(':CA;"Add/Remove Replica In Domain";',':CA;"Replicating Directory Changes";',
    ':CA;"Manage Replication Topology";',':CA;"Replicating Directory Changes All";',
    ':CA;"Monitor Active Directory Replication";')

$sitesperms = @(':CC;server; /I:S',':CC;nTDSDSA; /I:S',':WD;;nTDSDSA /I:S',':CC;nTDSConnection; /I:S')

$compcontperms = @(':WP;cn;computer /I:S',':WP;name;computer /I:S',':WP;distinguishedName;computer /I:S',':WP;servicePrincipalName;computer /I:S',
    ':WP;serverReference;computer /I:S',':WP;userAccountControl;computer /I:S',':DC;computer;')
$compcont = 'CN=Computers,'
$namingcontexts = Get-ADRootDSE
$namingcontexts = $namingcontexts.namingContexts 
function Run-Command{
    param([string]$cmd)
     $out = Invoke-Expression $cmd
    if($out -like "*The command failed to complete successfully*"){
        Write-Host $out
        exit
    }
    $cmd
}

Write-Host "Configuring replication extended rights..."
#give permissions to all naming contexts
foreach($context in $namingcontexts){
    foreach($perm in $namingcontextsperms){
        $cmd  = -join('dsacls ',$context,' /G ',$groupname,$perm)
        Run-Command -cmd $cmd
   
    }

}

Write-Host "Configuring permissions on the sites container..."
$cmd = -join('dsacls ','CN=Sites, CN=Configuration, ',$dn,' /G ', $groupname)
foreach($perm in $sitesperms){
    $cmd = -join($cmd,$perm)
    Run-Command -cmd $cmd
}

Write-Host "Configuring permissions on the source (computers or staging, etc.) container..."
$cmd = -join('dsacls ',$compcont,$dn,' /G ', $groupname)
foreach($perm in $compcontperms){
    $cmd = -join($cmd,$perm)
}

Write-Host "Configuring permissions on the domain controllers OU..."

$cmd = -join('dsacls ','"OU=Domain Controllers,"',$dn,' /G ',$groupname,':CC;computer;')
Run-Command -cmd $cmd
Write-Host "Granting WP for the msDS-NC-Replica-Locations attribute of the discoverer partition..."

$cmd =  -join('dsacls ','"CN=Partitions, CN=Configuration,"',$dn,' /G ',$groupname,':WP;msDS-NC-Replica-Locations;')
Run-Command -cmd $cmd
Write-Host "Success!"