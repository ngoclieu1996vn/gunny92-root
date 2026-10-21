[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLEXPR_x64_ENU.exe"
$dest = "C:\Users\Administrator\Downloads\SQLEXPR_x64_ENU.exe"

if (-not (Test-Path $dest) -or (Get-Item $dest).Length -ne 261082544) {
    Write-Host "Downloading SQL Server 2019 Express (261MB)..."
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $dest)
    Write-Host "Download complete. File size: $((Get-Item $dest).Length)"
} else {
    Write-Host "File already downloaded."
}
