param(  
    [Parameter(Mandatory = $true)]
    $serverName,
	
    [Parameter(Mandatory = $true)]
    $backupDirectory,
	
    [Parameter(Mandatory = $true)]
    $daysToStoreBackups
)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName
$dbs = $server.Databases
foreach ($database in $dbs | Where-Object { $_.IsSystemObject -eq $False }) {
    $dbName = $database.Name

    $timestamp = Get-Date -format yyyy-MM-dd-HHmmss
    $targetPath = $backupDirectory + "\" + $dbName + "_" + $timestamp + ".bak"

    $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
    $smoBackup.Action = "Database"
    $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
    $smoBackup.BackupSetName = $dbName + " Backup"
    $smoBackup.Database = $dbName
    $smoBackup.MediaDescription = "Disk"
    $smoBackup.Devices.AddDevice($targetPath, "File")
    $smoBackup.SqlBackup($server)

    "backed up $dbName ($serverName) to $targetPath"
    Compress-Archive -LiteralPath "$targetPath" -DestinationPath "$targetPath.zip"
    Remove-Item "$targetPath"
}

Get-ChildItem "$backupDirectory\*.zip" | Where-Object { $_.lastwritetime -le (Get-Date).AddDays(-$daysToStoreBackups)} | ForEach-Object {Remove-Item $_ -force }  
"removed all previous backups older than $daysToStoreBackups days"