$connStr = "Server=127.0.0.1;User Id=sa;Password=abcd@12344;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

Write-Host "=== Db_Tank41.dbo.Server_Config ==="
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT * FROM Db_Tank41.dbo.Server_Config"
$r = $cmd.ExecuteReader()
$dt = New-Object System.Data.DataTable
$dt.Load($r)
$dt | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "=== Db_Tank41.dbo.Server_List ==="
$cmd.CommandText = "SELECT * FROM Db_Tank41.dbo.Server_List"
$r = $cmd.ExecuteReader()
$dt = New-Object System.Data.DataTable
$dt.Load($r)
$dt | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "=== Db_Tank.dbo.Server_List ==="
$cmd.CommandText = "SELECT * FROM Db_Tank.dbo.Server_List"
$r = $cmd.ExecuteReader()
$dt = New-Object System.Data.DataTable
$dt.Load($r)
$dt | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "=== Db_Member.dbo.Server_List ==="
$cmd.CommandText = "SELECT * FROM Db_Member.dbo.Server_List"
$r = $cmd.ExecuteReader()
$dt = New-Object System.Data.DataTable
$dt.Load($r)
$dt | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "=== Mem_Account schema ==="
$cmd.CommandText = "SELECT COLUMN_NAME, DATA_TYPE FROM Db_Member.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Mem_Account'"
$r = $cmd.ExecuteReader()
$dt = New-Object System.Data.DataTable
$dt.Load($r)
$dt | Format-Table -AutoSize | Out-String | Write-Host

$conn.Close()
