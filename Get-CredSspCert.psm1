 #grab thumbprint of self signed cert for credssp
function Get-CredSspCert{
    param( [String[]]$Computer = $Null,
            [parameter(Mandatory=$true)]
            [PSCredential]$Credential
        )
    foreach($comp in $Computer){
        if($Credential = $Null){
            $session = New-Pssession -ComputerName $comp
            Invoke-Command -Session $session -ScriptBlock {
                $creds = Get-ChildItem "Cert:\LocalMachine\Remote Desktop\"
                Write-Host $creds
            } 
        }
        else{
            $session = New-Pssession -ComputerName $comp -Credential
            Invoke-Command -Session $session -ScriptBlock{
                $creds = Get-ChildItem "Cert:\LocalMachine\Remote Desktop\"
                Write-Host $creds
            }
        }
    }
}
#Cert:\LocalMachine\Remote Desktop\