Write-Host "=== 1. Updating Windows Firewall ==="
$ports = @(80, 8080, 9200, 9202, 9208, 9302, 9308, 843, 1433)
foreach ($port in $ports) {
    $ruleName = "Gunny_Port_$port"
    Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow -Profile Any | Out-Null
    Write-Host "Opened firewall port: $port"
}

Write-Host "`n=== 2. Updating Server_List in Db_Tank41 and Db_Member ==="
$connStr = "Server=127.0.0.1;User Id=sa;Password=abcd@12344;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
UPDATE Db_Tank41.dbo.Server_List 
SET IP = '221.121.4.241', Port = 9200, State = 2, Online = 1
WHERE ID = 4;

IF NOT EXISTS (SELECT 1 FROM Db_Tank41.dbo.Server_List WHERE ID = 4)
BEGIN
    INSERT INTO Db_Tank41.dbo.Server_List (ID, Name, IP, Port, State, Online, Total, Room, Remark, RSA)
    VALUES (4, N'Gà Chọi', '221.121.4.241', 9200, 2, 1, 1200, 1000, '11', '');
END

IF OBJECT_ID('Db_Member.dbo.Server_List') IS NOT NULL
BEGIN
    UPDATE Db_Member.dbo.Server_List
    SET Host = '127.0.0.1', Password = 'abcd@12344',
        LinkRequest = 'http://221.121.4.241/request/',
        LinkConfig = 'http://221.121.4.241/flash/config.xml',
        LinkFlash = 'http://221.121.4.241/flash/',
        LinkCenter = 'http://127.0.0.1:2108/CenterService/'
    WHERE ServerID = 1001 OR ServerID = 4;
END
"@
$cmd.ExecuteNonQuery() | Out-Null
Write-Host "Server_List updated in databases!"

Write-Host "`n=== 3. Updating Center.Service.exe.config ==="
$centerConfigPath = "c:\Users\Administrator\Desktop\Gunny92\Gunny92\Server\center\Center.Service.exe.config"
$xml = [xml](Get-Content $centerConfigPath)
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "conString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank41;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "crosszoneString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "IP" }).value = "127.0.0.1"
$xml.'system.serviceModel'.services.service.host.baseAddresses.add.baseAddress = "http://127.0.0.1:2108/CenterService/"
$xml.'system.serviceModel'.services.service.endpoint[0].address = "net.tcp://127.0.0.1:2109/"
$xml.Save($centerConfigPath)
Write-Host "Center config updated!"

Write-Host "`n=== 4. Updating Fighting.Service.exe.config ==="
$fightConfigPath = "c:\Users\Administrator\Desktop\Gunny92\Gunny92\Server\fight\Fighting.Service.exe.config"
$xml = [xml](Get-Content $fightConfigPath)
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "conString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank41;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "crosszoneString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "IP" }).value = "127.0.0.1"
$xml.Save($fightConfigPath)
Write-Host "Fight config updated!"

Write-Host "`n=== 5. Updating Road.Service.exe.config ==="
$roadConfigPath = "c:\Users\Administrator\Desktop\Gunny92\Gunny92\Server\road\Road.Service.exe.config"
$xml = [xml](Get-Content $roadConfigPath)
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "conString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank41;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "crosszoneString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "IP" }).value = "0.0.0.0"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "Port" }).value = "9200"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "LoginServerIp" }).value = "127.0.0.1"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "WorldServerIp" }).value = "127.0.0.1"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "FightServerIp" }).value = "127.0.0.1"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "request" }).value = "http://127.0.0.1/request"
$xml.'system.serviceModel'.client.endpoint[0].address = "http://127.0.0.1/request/PassPort.asmx"
$xml.'system.serviceModel'.client.endpoint[1].address = "net.tcp://127.0.0.1:2109/"
$xml.Save($roadConfigPath)
Write-Host "Road config updated!"

Write-Host "`n=== 6. Updating Request Web.config ==="
$reqConfigPath = "c:\Users\Administrator\Desktop\Gunny92\Gunny92\Request\Web.config"
$xml = [xml](Get-Content $reqConfigPath)
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "conString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank41;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "crosszoneString" }).value = "Data Source=127.0.0.1;Initial Catalog=Db_Tank;Persist Security Info=True;User ID=sa;Password=abcd@12344"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "LoginIP" }).value = "127.0.0.1|221.121.4.241|0.0.0.0|15.235.163.5"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "ChargeIP" }).value = "127.0.0.1|221.121.4.241|0.0.0.0|15.235.163.5"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "AdminIP" }).value = "127.0.0.1|221.121.4.241|0.0.0.0|15.235.163.5"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "SentRewardIP" }).value = "127.0.0.1|221.121.4.241|0.0.0.0|15.235.163.5"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "ExitURL" }).value = "http://221.121.4.241/"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "PayURL" }).value = "http://221.121.4.241/"
($xml.configuration.appSettings.add | Where-Object { $_.key -eq "FavoriteUrl" }).value = "http://221.121.4.241/"
$xml.Save($reqConfigPath)
Write-Host "Request Web.config updated!"

Write-Host "`n=== 7. Updating Flash config.xml ==="
$flashConfigPath = "c:\Users\Administrator\Desktop\Gunny92\Gunny92\Flash\config.xml"
$xml = [xml](Get-Content $flashConfigPath)
$cfg = $xml.root.config
$cfg.FLASHSITE.value = "http://221.121.4.241/flash/"
$cfg.BACKUP_FLASHSITE.value = "http://221.121.4.241/flash/"
$cfg.SITE.value = "http://221.121.4.241/res/"
$cfg.FIRSTPAGE.value = "http://221.121.4.241/"
$cfg.REGISTER.value = "http://221.121.4.241/"
$cfg.REQUEST_PATH.value = "http://221.121.4.241/request/"
$cfg.LOGIN_PATH.value = "http://221.121.4.241/"
$cfg.FILL_PATH.value = "http://221.121.4.241/"
$cfg.WEEKLYSITE.value = "http://221.121.4.241/flash/"
$cfg.POLICY_FILES.file.value = "http://221.121.4.241/crossdomain.xml"
$xml.Save($flashConfigPath)
Write-Host "Flash config.xml updated!"

$conn.Close()
Write-Host "`nConfiguration updates complete!"
