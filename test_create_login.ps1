$user = "testgunny"
$key = "123456"
$time = [int][double]::Parse((Get-Date (Get-Date).ToUniversalTime() -UFormat %s))
$loginKey = "taolacuopday_WAN-0668-2555555-7ROAD-dandantang-love777nguyenluulathangloznaothe-gunny92"

$raw = "$user$key$time$loginKey"
$md5 = [System.Security.Cryptography.MD5]::Create()
$hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($raw))
$hash = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })

$content = "$user|$key|$time|$hash"
$url = "http://127.0.0.1/request/CreateLogin.aspx?content=" + [System.Uri]::EscapeDataString($content)

Write-Host "Calling URL: $url"
$res = Invoke-WebRequest -Uri $url -UseBasicParsing
Write-Host "Response: '$($res.Content)'"
