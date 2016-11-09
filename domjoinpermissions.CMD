:: Ripped from http://bit.ly/2flkiRy
:: DomJoinPermissions.CMD
::  Paul Williams, msresource.net, October 2006 
:: 
:: Version: 		V01.00.00cmd
:: Written: 		17/10/2006
:: Last updated: 	17/10/2006
:: Last updated by:	Paul Williams
:: 
:: 
:: Script sets the necessary permissions in the domain passed as an 
:: argument (1) for the trustee passed as an argument (0) so that
:: that trustee can add domain controllers to the domain.
:: 
:: Script expects both ADFIND.EXE (V01.32.00cpp or higher) and 
:: DSACLS.EXE to be present in the same directory as this script.
:: 
:: Example usage:
:: 
:: 	domjoinpermissions "TEST-LAB\Add domain controllers to the domain" "DC=test-lab,DC=com"
:: 
:: 
:: 		** Note ** 	The script must be run from the CD of the script
:: 				location if ADFIND isn't within the %PATH% otherwise
:: 				the script will fail with a "Cannot find ADFIND error"
:: 		
:: 		** Note ** 	Non-standard permissions are required to implement 
:: 				this script.  See accompanying documentation for
:: 				exact requirements.
:: 
:: 
:: Versions
:: 
:: 	V01.00.00 (17/10/2006)	:	Original build
:: 

@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

SET APPNAME=DomJoinPermissions
SET APPVERSION=V01.00.00cmd
SET APPAUTHOR=Paul Williams (
 paul@msresource.net)
SET APPWRITTEN=Oct. 2006

:: Output script info.
echo/
echo %APPNAME% %APPVERSION% %APPAUTHOR% %APPWRITTEN%
echo/

:: Check that we have the correct arguments
if [%1]==[] (
	GOTO :Usage
) else (
	SET TRUSTEE=%1
)

:: Check that we have the correct arguments
if [%2]==[] (
	GOTO :USAGE
) else (
	SET DOMDN=%2
)

echo Configuring replication extended rights...


:: Set permissions on all local NCs
for /f "tokens=*" %%a in ('adfind -b -s base namingContexts -list') do (
	echo/
	echo [%%a]
	dsacls "%%a" /G %TRUSTEE%:CA;"Add/Remove Replica In Domain";
	dsacls "%%a" /G %TRUSTEE%:CA;"Replicating Directory Changes";
	dsacls "%%a" /G %TRUSTEE%:CA;"Manage Replication Topology";
	dsacls "%%a" /G %TRUSTEE%:CA;"Replicating Directory Changes All";
	dsacls "%%a" /G %TRUSTEE%:CA;"Monitor Active Directory Replication";
)

echo/
echo Configuring permissions on the sites container...


:: Set the necessary permissions on the sites container
dsacls "CN=Sites, CN=Configuration,%DOMDN%" /G %TRUSTEE%:CC;server; /I:S
dsacls "CN=Sites, CN=Configuration,%DOMDN%" /G %TRUSTEE%:CC;nTDSDSA; /I:S
dsacls "CN=Sites, CN=Configuration,%DOMDN%" /G %TRUSTEE%:WD;;nTDSDSA /I:S
dsacls "CN=Sites, CN=Configuration,%DOMDN%" /G %TRUSTEE%:CC;nTDSConnection; /I:S

echo/
echo Configuring permissions on the source (computers or staging, etc.) container...


:: Set the necessary permission on the default computers container
::  NOTE.  If REDIRCOMP has been run, %COMPCONT% must be changed to 
::  reflect this.
SET COMPCONT=OU=Staging,%DOMDN%

dsacls "%COMPCONT%" /G %TRUSTEE%:WP;cn;computer /I:S
dsacls "%COMPCONT%" /G %TRUSTEE%:WP;name;computer /I:S
dsacls "%COMPCONT%" /G %TRUSTEE%:WP;distinguishedName;computer /I:S
dsacls "%COMPCONT%" /G %TRUSTEE%:WP;servicePrincipalName;computer /I:S
dsacls "%COMPCONT%" /G %TRUSTEE%:WP;serverReference;computer /I:S
dsacls "%COMPCONT%" /G %TRUSTEE%:WP;userAccountControl;computer /I:S
dsacls "%COMPCONT%" /G %TRUSTEE%:DC;computer;

echo/
echo Configuring permissions on the domain controllers OU...


:: Set the necessary permissions on the domain controllers OU
dsacls "OU=Domain Controllers,%DOMDN%" /G %TRUSTEE%:CC;computer;


:: Add permission to add NDNC replicas for SVC acct.
:: 
:: 	** Added 05/01/2007 (V01.00.03cmd) **
:: 
echo Granting WP for the msDS-NC-Replica-Locations attribute of the discoverer partition

for /f "tokens=*" %%b in ('adfind -configuration -rb CN=Partitions -f "nCName=DC=DiscovererPartition,%DOMDN%" -list distinguishedName') do (
	echo [%%b]
	dsacls %%b /G %TRUSTEE%:WP;msDS-NC-Replica-Locations;
)

echo/


::Clean up
SET APPNAME=
SET APPVERSION=
SET APPAUTHOR=
SET APPWRITTEN=

SET TRUSTEE=
SET DOMDN=
SET COMPCONT=

echo The application completed successfully

GOTO :EXIT

:USAGE
echo   Usage:
echo/
echo   DomJoinPermissions ^<trustee^> ^<domain DN^>
echo/
echo     ^<trustee^>	::	The security principal to give permissions to.  This
echo 			is usually a group, and should be in the format of
echo 			"DOMAIN-NAME\Group-name", e.g. "test-lab\Promote DCs"
echo/
echo     ^<domain DN^>	::	This is the DN of the domain in which you want to set
echo 			these permissions, e.g. "dc=test-lab,dc=com"
echo/
echo/


:Exit
echo/
