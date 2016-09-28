#Written by Philip Bove
#9/28/2016
#
$files = Get-ChildItem E:/downloads #Put path to folder you would like to run against
$date = Get-Date
$date = $date.AddDays(-1)
foreach($file in $files){
	$fileinfo = Get-Item $file.PSPath
	if($file.CreationTime -le $date){
		Remove-Item $file.PSPath -Recurse -Force
	}

}