$connStr = "Server=127.0.0.1;User Id=sa;Password=abcd@12344;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

Write-Host "=== Mem_Account top 5 ==="
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT TOP 5 UserID, Email, Password FROM Db_Member.dbo.Mem_Account"
$r = $cmd.ExecuteReader()
$dt = New-Object System.Data.DataTable
$dt.Load($r)
$dt | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "=== Db_Tank41 Sys_Users_Detail / Players ==="
$cmd.CommandText = "SELECT TOP 5 UserID, UserName, NickName, Grade, Money, Gold, GiftToken FROM Db_Tank41.dbo.Sys_Users_Detail"
try {
    $r = $cmd.ExecuteReader()
    $dt = New-Object System.Data.DataTable
    $dt.Load($r)
    $dt | Format-Table -AutoSize | Out-String | Write-Host
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}

$conn.Close()
