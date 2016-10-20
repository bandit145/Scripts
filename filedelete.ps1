#Written by Philip Bove
#9/28/2016
#
$files = Get-ChildItem folder #Put path to folder you would like to run against
$date = Get-Date
$date = $date.AddDays(-1)#amount of days wanted to keep
foreach($file in $files){
	$fileinfo = Get-Item $file.PSPath
	if($file.Name -eq 'folder to not delete'){
		Write-Host "Folder not Deleted"
	}
	Elseif($file.CreationTime -le $date){
		Remove-Item $file.PSPath -Recurse -Force
	}

}