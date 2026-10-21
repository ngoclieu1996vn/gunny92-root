[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://download.microsoft.com/download/29654887-7cde-4397-bba3-d7f087970845/SQL2022-SSEI-Expr.exe"
$dest = "C:\Users\Administrator\Downloads\SQL2022-SSEI-Expr.exe"

if (-not (Test-Path $dest)) {
    Write-Host "Downloading SQL2022-SSEI-Expr.exe..."
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $dest)
    Write-Host "Downloaded SQL2022-SSEI-Expr.exe, size: $((Get-Item $dest).Length)"
}

New-Item -ItemType Directory -Path "C:\SQL2022" -Force | Out-Null

Write-Host "Downloading Core media via SSEI..."
$p = Start-Process -FilePath $dest -ArgumentList "/ACTION=Download /MEDIAPATH=C:\SQL2022 /MEDIATYPE=Core /QUIET" -Wait -PassThru
Write-Host "SSEI exit code: $($p.ExitCode)"
Get-ChildItem "C:\SQL2022"
