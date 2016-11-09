#Powershell implementation of DomJoinPermissions.CMD, Original CMD by Paul Williams, msresource.net http://bit.ly/2flkiRy
param(
    [Parameter(Mandatory = $true)]
    [string]$groupname
    [Parameter(Mandatory = $true)]
    [string]$dn
    )

$compcont = "CN=Computers,"
$namingcontexts = Get-ADRootDSE
$namingcontexts = $namingcontexts.namingContexts

Write-Host "Configuring replication extended rights..."
#give permissions to all naming contexts
foreach($context in $namingcontexts){
    dsacls $context /G $groupname:CA;"Add/Remove Replica In Domain";
    dsacls $context /G $groupname:CA;"Replicating Directory Changes";
    dsacls $context /G $groupname:CA;"Manage Replication Topology";
    dsacls $context /G $groupname:CA;"Replicating Directory Changes All";
    dsacls $context /G $groupname:CA;"Monitor Active Directory Replication";
}

Write-Host "Configuring permissions on the sites container..."

dsacls "CN=Sites, CN=Configuration,"$dn /G $groupname:CC;server; /I:S
dsacls "CN=Sites, CN=Configuration,"$dn /G $groupname:CC;nTDSDSA; /I:S
dsacls "CN=Sites, CN=Configuration,"$dn /G $groupname:WD;;nTDSDSA /I:S
dsacls "CN=Sites, CN=Configuration,"$dn /G $groupname:CC;nTDSConnection; /I:S

Write-Host "Configuring permissions on the source (computers or staging, etc.) container..."

dsacls -join($compcont,$dn) /G $groupname:WP;cn;computer /I:S
dsacls -join($compcont,$dn) /G $groupname:WP;name;computer /I:S
dsacls -join($compcont,$dn) /G $groupname:WP;distinguishedName;computer /I:S
dsacls -join($compcont,$dn) /G $groupname:WP;servicePrincipalName;computer /I:S
dsacls -join($compcont,$dn) /G $groupname:WP;serverReference;computer /I:S
dsacls -join($compcont,$dn) /G $groupname:WP;userAccountControl;computer /I:S
dsacls -join($compcont,$dn) /G $groupname:DC;computer;

Write-Host "Configuring permissions on the domain controllers OU..."

dsacls "OU=Domain Controllers,"$dn /G $groupname:CC;computer;

Write-Host "Granting WP for the msDS-NC-Replica-Locations attribute of the discoverer partition"

dsacls -join("CN=Partitions, CN=Configuration,",$dn) /G $groupname:WP;msDS-NC-Replica-Locations;