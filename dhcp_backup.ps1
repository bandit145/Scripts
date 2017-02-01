$ErrorActionPreference = "Stop"
$dest = "\\meme-file001\backups\dhcp\"
try{
    New-EventLog -LogName Application -Source "dhcp backup" -ErrorAction "SilentlyContinue"
    if (Get-Item -Path C:\Windows\system32\dhcp\backup){
        $files = Get-ChildItem -Path $dest
        $count = 0
        foreach($file in $files.Name){
            if ($file -like "*DhcpCfg*"){
                $count += 1
            }
        }
        try{
            $newdest = -join($dest,$count,"new")
            $dhcpcfgdest = -join($location,$count,"DhcpCfg")
        	Copy-Item  -Name "C:\Windows\system32\dhcp\backup\new" -Destination $newdest
            Copy-Item  -Name "C:\Windows\system32\dhcp\backup\DhcpCfg" -Destination $dhcpcfgdest
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