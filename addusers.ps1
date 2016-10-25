param (
	[Parameter(Mandatory) = $true]
	[string]$csvfile

)
$data = Import-CSV $csvfile

for $name in $data.Name