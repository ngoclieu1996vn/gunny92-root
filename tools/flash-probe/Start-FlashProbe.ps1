param(
    [string]$Url = 'http://127.0.0.1:8888/play2.aspx?user=admin123',
    [string]$FlashBrowserDirectory = 'C:\Program Files (x86)\FlashBrowser',
    [int]$DurationSeconds = 120
)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$output = Join-Path $root 'scratch/flash-probe'
$plugin = Join-Path $FlashBrowserDirectory 'resources/app/flashver/pepflashplayer64.dll'
if (-not (Test-Path -LiteralPath $plugin)) { throw 'FlashBrowser Flash plugin was not found.' }
if (Get-CimInstance Win32_Process -Filter "name='FlashBrowser.exe'" | Where-Object { $_.ExecutablePath -eq (Join-Path $output 'FlashBrowser.exe') }) {
    throw 'A probe is already running. Wait for its configured duration before starting another.'
}
New-Item -ItemType Directory -Path (Join-Path $output 'resources/app'), (Join-Path $output 'locales') -Force | Out-Null
Get-ChildItem -LiteralPath $FlashBrowserDirectory -File | Copy-Item -Destination $output -Force
Copy-Item -LiteralPath (Join-Path $FlashBrowserDirectory 'locales/en-US.pak') -Destination (Join-Path $output 'locales') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'index.js'), (Join-Path $PSScriptRoot 'package.json') -Destination (Join-Path $output 'resources/app') -Force
$env:GUNNY_PROBE_URL = $Url
$env:GUNNY_PROBE_FLASH = $plugin
$env:GUNNY_PROBE_DURATION = [string]$DurationSeconds
try {
    Start-Process -FilePath (Join-Path $output 'FlashBrowser.exe') -WorkingDirectory $output -WindowStyle Hidden
} finally {
    Remove-Item Env:GUNNY_PROBE_URL, Env:GUNNY_PROBE_FLASH, Env:GUNNY_PROBE_DURATION -ErrorAction SilentlyContinue
}
Write-Output "Flash probe started. Screenshots and network logs: $output"
