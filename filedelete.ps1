#Written by Philip Bove
#9/28/2016
#
$files = Get-ChildItem userprofiles #Put path to folder you would like to run against
$date = Get-Date
$date = $date.AddDays(-10)
foreach($file in $files){
	$fileinfo = Get-Item $file
	if($file.CreationTime -le $date){
		Remove-Item -Recurse -Force
	}

}