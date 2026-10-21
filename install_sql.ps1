Write-Host "Starting SQL Server 2019 Express silent installation..."
$installer = "C:\Users\Administrator\Downloads\SQLEXPR_x64_ENU.exe"
$args = "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=`"NT AUTHORITY\SYSTEM`" /SQLSYSADMINACCOUNTS=`"BUILTIN\Administrators`" /SECURITYMODE=SQL /SAPWD=`"abcd@12344`" /TCPENABLED=1 /NPENABLED=1"

$process = Start-Process -FilePath $installer -ArgumentList $args -Wait -PassThru
Write-Host "Installer finished with ExitCode: $($process.ExitCode)"
