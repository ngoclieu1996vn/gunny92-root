$appcmd = "$env:SystemRoot\System32\inetsrv\appcmd.exe"

Write-Host "1. Crossdomain.xml"
$crossdomain = @"
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
    <allow-access-from domain="*" to-ports="*" />
    <site-control permitted-cross-domain-policies="all"/>
</cross-domain-policy>
"@
Set-Content -Path "C:\inetpub\wwwroot\crossdomain.xml" -Value $crossdomain
Set-Content -Path "C:\Gunny92\Flash\crossdomain.xml" -Value $crossdomain
Set-Content -Path "C:\Gunny92\Resource.Server\crossdomain.xml" -Value $crossdomain

Write-Host "2. AppPool"
& $appcmd delete apppool "GunnyAppPool"
& $appcmd add apppool /name:GunnyAppPool /managedRuntimeVersion:v4.0
& $appcmd set apppool "GunnyAppPool" /enable32BitAppOnWin64:true
& $appcmd set apppool "GunnyAppPool" /processModel.identityType:LocalSystem

Write-Host "3. Remove old apps/vdirs"
& $appcmd delete app "Default Web Site/request"
& $appcmd delete vdir "Default Web Site/flash"
& $appcmd delete vdir "Default Web Site/res"

Write-Host "4. Add /request app"
& $appcmd add app /site.name:"Default Web Site" /path:/request /physicalPath:"C:\Gunny92\Request" /applicationPool:GunnyAppPool

Write-Host "5. Add /flash and /res vdirs"
& $appcmd add vdir /app.name:"Default Web Site/" /path:/flash /physicalPath:"C:\Gunny92\Flash"
& $appcmd add vdir /app.name:"Default Web Site/" /path:/res /physicalPath:"C:\Gunny92\Resource.Server"

Write-Host "6. Add MIME types"
& $appcmd set config /section:staticContent /+"[fileExtension='.swf',mimeType='application/x-shockwave-flash']"
& $appcmd set config /section:staticContent /+"[fileExtension='.xml',mimeType='text/xml']"
& $appcmd set config /section:staticContent /+"[fileExtension='.json',mimeType='application/json']"

Write-Host "7. Permissions"
icacls "C:\Gunny92" /grant "Everyone:(OI)(CI)F" /grant "IIS_IUSRS:(OI)(CI)F"

Write-Host "8. IIS Reset"
iisreset /restart

Write-Host "IIS Setup Completed Successfully!"
