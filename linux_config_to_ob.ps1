#ADVANCED FUNCTIONS MUAHAHAH
[CmdletBinding(SupportsShouldProcess=$true)]
#prepmpt output type
[OutputType("PSObject")]
param(
    [parameter(Mandatory=$true, Position=1)]
    $File
    )

Begin{
    $ErrorActionPreference = "Stop"
    $ConfigObj = New-Object -TypeName PSObject
    $file_input = Get-Content $File  | Where-Object {!($_ -match "^#")}  
    foreach($line in $file_input){
        if($line.Length -gt 1){
            $key, $value = $line.Split(" ")
            #this will only work if the same keys are right under each other
            if($ConfigObj.$key -and $ConfigObj.$key.GetType() -ne [System.Array]){
                $ConfigObj.$key = @($ConfigObj.$key)
                $ConfigObj.$key += $value
            }
            elseif($ConfigObj.$key){
                $ConfigObj.$key += $value
            }
            else{
                Add-Member -InputObject $ConfigObj -Name $key -Value $value -MemberType NoteProperty
            }
        }
    }
    return $ConfigObj
}

