Write-Host "Upgrading SQL Server instance to SQL Server 2022..."
$installer = "C:\SQL2022\SQLEXPR_x64_ENU.exe"
$args = "/ACTION=Upgrade /INSTANCENAME=MSSQLSERVER /IACCEPTSQLSERVERLICENSETERMS /Q"

$p = Start-Process -FilePath $installer -ArgumentList $args -Wait -PassThru
Write-Host "Upgrade finished with ExitCode: $($p.ExitCode)"
