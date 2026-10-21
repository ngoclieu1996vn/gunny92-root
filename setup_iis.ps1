Import-Module WebAdministration

Write-Host "=== Setting up IIS Application Pool ==="
$poolName = "GunnyAppPool"
if (-not (Test-Path "IIS:\AppPools\$poolName")) {
    New-Item "IIS:\AppPools\$poolName" | Out-Null
}
Set-ItemProperty "IIS:\AppPools\$poolName" -Name "managedRuntimeVersion" -Value "v4.0"
Set-ItemProperty "IIS:\AppPools\$poolName" -Name "enable32BitAppOnWin64" -Value $true
Set-ItemProperty "IIS:\AppPools\$poolName" -Name "processModel.identityType" -Value "LocalSystem"

Write-Host "=== Ensuring crossdomain.xml in wwwroot ==="
$crossdomainContent = @"
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
    <allow-access-from domain="*" to-ports="*" />
    <site-control permitted-cross-domain-policies="all"/>
</cross-domain-policy>
"@
Set-Content -Path "C:\inetpub\wwwroot\crossdomain.xml" -Value $crossdomainContent

Write-Host "=== Configuring Default Web Site ==="
$siteName = "Default Web Site"

# Remove existing apps/vdirs if any
Remove-WebApplication -Site $siteName -Name "request" -ErrorAction SilentlyContinue
Remove-WebVirtualDirectory -Site $siteName -Name "flash" -ErrorAction SilentlyContinue
Remove-WebVirtualDirectory -Site $siteName -Name "res" -ErrorAction SilentlyContinue

# Create Request Web Application
$requestPath = "C:\Gunny92\Request"
New-WebApplication -Site $siteName -Name "request" -PhysicalPath $requestPath -ApplicationPool $poolName | Out-Null
Write-Host "Created /request application -> $requestPath"

# Create Flash Virtual Directory
$flashPath = "C:\Gunny92\Flash"
New-WebVirtualDirectory -Site $siteName -Name "flash" -PhysicalPath $flashPath | Out-Null
Write-Host "Created /flash virtual directory -> $flashPath"

# Create Res Virtual Directory
$resPath = "C:\Gunny92\Resource.Server"
New-WebVirtualDirectory -Site $siteName -Name "res" -PhysicalPath $resPath | Out-Null
Write-Host "Created /res virtual directory -> $resPath"

Write-Host "=== Ensuring MIME types ==="
$mimes = @(
    @{ Ext = ".swf"; Type = "application/x-shockwave-flash" },
    @{ Ext = ".xml"; Type = "text/xml" },
    @{ Ext = ".png"; Type = "image/png" },
    @{ Ext = ".jpg"; Type = "image/jpeg" },
    @{ Ext = ".mp3"; Type = "audio/mpeg" },
    @{ Ext = ".json"; Type = "application/json" }
)

foreach ($m in $mimes) {
    try {
        Add-WebConfigurationProperty -PSPath "MACHINE/WEBROOT/APPHOST" -Filter "system.webServer/staticContent" -Name "." -Value @{fileExtension=$m.Ext; mimeType=$m.Type} -ErrorAction SilentlyContinue
    } catch {}
}

# Grant full permissions to IIS_IUSRS and Everyone on C:\Gunny92
$acl = Get-Acl "C:\Gunny92"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.AddAccessRule($rule)
$rule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.AddAccessRule($rule2)
Set-Acl "C:\Gunny92" $acl

# Restart IIS
iisreset /restart

Write-Host "IIS Setup Completed!"
