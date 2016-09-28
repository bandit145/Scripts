$files = Get-ChildItem userprofiles
$date = Get-Date
$date = $date.AddDays(-10)
foreach($file in $files){
	$fileinfo = Get-Item $file
	if($file.CreationTime -le $date){
		Remove-Item -Recurse -Force
	}

}