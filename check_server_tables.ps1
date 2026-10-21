$connStr = "Server=127.0.0.1;User Id=sa;Password=abcd@12344;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

Write-Host "--- Checking Server_Info in Db_Tank41 ---"
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT * FROM Db_Tank41.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%Server%'"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "Table: $($r['TABLE_NAME'])"
}
$r.Close()

Write-Host "--- Checking Server_List / Server_Info content in Db_Tank41 ---"
$cmd.CommandText = "IF OBJECT_ID('Db_Tank41.dbo.Server_Info') IS NOT NULL SELECT * FROM Db_Tank41.dbo.Server_Info"
try {
    $r = $cmd.ExecuteReader()
    $dt = New-Object System.Data.DataTable
    $dt.Load($r)
    $dt | Format-Table -AutoSize | Out-String | Write-Host
} catch {
    Write-Host "Error reading Server_Info: $($_.Exception.Message)"
}

Write-Host "--- Checking Server_List / Server_Info content in Db_Tank ---"
$cmd.CommandText = "IF OBJECT_ID('Db_Tank.dbo.Server_Info') IS NOT NULL SELECT * FROM Db_Tank.dbo.Server_Info"
try {
    $r = $cmd.ExecuteReader()
    $dt = New-Object System.Data.DataTable
    $dt.Load($r)
    $dt | Format-Table -AutoSize | Out-String | Write-Host
} catch {
    Write-Host "Error reading Server_Info: $($_.Exception.Message)"
}

Write-Host "--- Checking Db_Member tables ---"
$cmd.CommandText = "SELECT TABLE_NAME FROM Db_Member.INFORMATION_SCHEMA.TABLES"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "Member Table: $($r['TABLE_NAME'])"
}
$r.Close()

$conn.Close()
