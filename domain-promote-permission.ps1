#Powershell implementation of DomJoinPermissions.CMD, Original CMD by Paul Williams, msresource.net http://bit.ly/2flkiRy
#written 11/9/2016
param(
    [Parameter(Mandatory = $true)]
    [string]$groupname,
    [Parameter(Mandatory = $true)]
    [string]$dn
    )
$compcont = "CN=Computers,"
$namingcontexts = Get-ADRootDSE
$namingcontexts = $namingcontexts.namingContexts 
function Error-Check{
    param([string]$out)
    if($out -like "*The command failed to complete successfully*"){
        Write-Host $out
        exit
    }
    "Hello "+$out
}

Write-Host "Configuring replication extended rights..."
#give permissions to all naming contexts
foreach($context in $namingcontexts){
    $cmd  = -join('dsacls ',$context,' /G ',$groupname,':CA;"Add/Remove Replica In Domain";')
    $out = Invoke-Expression $cmd
    Error-Check -out $out
    #replace all this
    $cmd = sacls $context '/G' $groupname':CA;"Replicating Directory Changes";'
    dsacls $context '/G' $groupname':CA;"Manage Replication Topology";'
    dsacls $context '/G' $groupname':CA;"Replicating Directory Changes All";'
    dsacls $context '/G' $groupname':CA;"Monitor Active Directory Replication";'
}

Write-Host "Configuring permissions on the sites container..."
$string = -join('"CN=Sites, CN=Configuration,',$dn)
dsacls $string' /G '$groupname':CC;server; /I:S'
dsacls $string '/G' $groupname':CC;nTDSDSA; /I:S'
dsacls $string '/G' $groupname':WD;;nTDSDSA /I:S'
dsacls $string '/G' $groupname':CC;nTDSConnection; /I:S'

Write-Host "Configuring permissions on the source (computers or staging, etc.) container..."
$string = -join($compcont,$dn)
dsacls $string '/G' $groupname':WP;cn;computer /I:S'
dsacls $string '/G' $groupname':WP;name;computer /I:S'
dsacls $string '/G' $groupname':WP;distinguishedName;computer /I:S'
dsacls $string '/G' $groupname':WP;servicePrincipalName;computer /I:S'
dsacls $string '/G' $groupname':WP;serverReference;computer /I:S'
dsacls $string '/G' $groupname':WP;userAccountControl;computer /I:S'
dsacls $string '/G' $groupname':DC;computer;'

Write-Host "Configuring permissions on the domain controllers OU..."

$string = -join("OU=Domain Controllers,",$dn)
dsacls $string '/G' $groupname':CC;computer;'
Write-Host "Granting WP for the msDS-NC-Replica-Locations attribute of the discoverer partition..."

$string = -join("CN=Partitions, CN=Configuration,",$dn)
dsacls $string '/G' $groupname':WP;msDS-NC-Replica-Locations;'

Write-Host "Success!"