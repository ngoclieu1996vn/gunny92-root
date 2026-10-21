$connStr = "Server=127.0.0.1;User Id=sa;Password=abcd@12344;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)

try {
    $conn.Open()
    Write-Host "Connected to SQL Server successfully! Version: $($conn.ServerVersion)"
} catch {
    Write-Error "Failed to connect to SQL Server: $($_.Exception.Message)"
    exit 1
}

# Find SQL data directory
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT SERVERPROPERTY('InstanceDefaultDataPath')"
$dataDir = [string]$cmd.ExecuteScalar()
if (-not $dataDir -or -not (Test-Path $dataDir)) {
    $dataDir = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA"
}
if (-not (Test-Path $dataDir)) {
    $dataDir = "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
}
Write-Host "Data directory: $dataDir"

$baseDir = "c:\Users\Administrator\Desktop\Gunny92\Gunny92"
if (-not (Test-Path "$baseDir\admin.bak") -and (Test-Path "$baseDir\admin.bak.zip")) {
    Write-Host "Extracting $baseDir\admin.bak.zip..."
    Expand-Archive -Path "$baseDir\admin.bak.zip" -DestinationPath $baseDir -Force
}

$backups = @(
    @{ DbName = "Db_Admin";  BakFile = "$baseDir\admin.bak" },
    @{ DbName = "Db_GM";     BakFile = "$baseDir\gm.bak" },
    @{ DbName = "Db_Member"; BakFile = "$baseDir\member.bak" },
    @{ DbName = "Db_Tank";   BakFile = "$baseDir\tank.bak" },
    @{ DbName = "Db_Tank41"; BakFile = "$baseDir\tank41.bak" }
)

foreach ($b in $backups) {
    $dbName = $b.DbName
    $bakFile = $b.BakFile

    Write-Host "`nProcessing $dbName from $bakFile..."

    # Get file list from backup
    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 600
    $cmd.CommandText = "RESTORE FILELISTONLY FROM DISK = N'$bakFile'"
    $reader = $cmd.ExecuteReader()
    $fileList = @()
    while ($reader.Read()) {
        $fileList += [PSCustomObject]@{
            LogicalName = $reader["LogicalName"].ToString()
            Type        = $reader["Type"].ToString() # D = data, L = log
        }
    }
    $reader.Close()

    # Build RESTORE statement
    $moveClauses = @()
    $dataIndex = 1
    $logIndex = 1
    foreach ($f in $fileList) {
        $logical = $f.LogicalName
        if ($f.Type -eq 'D') {
            $destFile = "$dataDir\${dbName}_data_${dataIndex}.mdf"
            $moveClauses += "MOVE N'$logical' TO N'$destFile'"
            $dataIndex++
        } elseif ($f.Type -eq 'L') {
            $destFile = "$dataDir\${dbName}_log_${logIndex}.ldf"
            $moveClauses += "MOVE N'$logical' TO N'$destFile'"
            $logIndex++
        }
    }

    $moveSql = $moveClauses -join ", "
    $restoreSql = @"
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'$dbName')
BEGIN
    ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$dbName];
END
RESTORE DATABASE [$dbName] FROM DISK = N'$bakFile' WITH REPLACE, $moveSql;
ALTER DATABASE [$dbName] SET MULTI_USER;
"@
    Write-Host "Restoring $dbName..."
    $restoreCmd = $conn.CreateCommand()
    $restoreCmd.CommandTimeout = 1200
    $restoreCmd.CommandText = $restoreSql
    try {
        $restoreCmd.ExecuteNonQuery() | Out-Null
        Write-Host "Database $dbName restored successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore ${dbName}: $($_.Exception.Message)"
    }
}

# Verify restored databases
$checkCmd = $conn.CreateCommand()
$checkCmd.CommandText = "SELECT name, state_desc FROM sys.databases WHERE name IN ('Db_Admin', 'Db_GM', 'Db_Member', 'Db_Tank', 'Db_Tank41')"
$r = $checkCmd.ExecuteReader()
Write-Host "`nDatabase Status:"
while ($r.Read()) {
    Write-Host " - $($r['name']): $($r['state_desc'])"
}
$r.Close()

$conn.Close()
Write-Host "`nAll restore operations completed."
