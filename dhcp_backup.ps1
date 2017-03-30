$ErrorActionPreference = "Stop"
$dest = "\\meme-file001\backups\dhcp\"
try{
    New-EventLog -LogName Application -Source "dhcp backup" -ErrorAction "SilentlyContinue"
    if (Get-Item -Path C:\Windows\system32\dhcp\backup){
        $files = Get-ChildItem -Path $dest
        $count = 0
        foreach($file in $files){
            $count += 1
        }
        try{
            $newdest = -join($dest,"backup-,"$count)
        	Copy-Item  -Path "C:\Windows\system32\dhcp\backup\*" -Destination $newdest -Recurse
            Write-EventLog -LogName Application -Source "dhcp backup" -EntryType Information -EventId 1 -Message "Backup Successful"
        }
        catch{
            Write-EventLog -LogName Application -Source "dhcp backup" -EntryType Error -EventId 2 -Message "Backup Failed"
        }
    }
}
catch {
     Write-EventLog -LogName Application -Source "dhcp backup" -EntryType Information -EventId 3 -Message "dhcp backup file does not exist on local machine!"
}