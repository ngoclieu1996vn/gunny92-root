param(
    [string]$Url = 'http://127.0.0.1:8888/play2.aspx?user=admin123',
    [string]$FlashBrowserDirectory = 'C:\Program Files (x86)\FlashBrowser',
    [int]$DurationSeconds = 120,
    [ValidateRange(500,60000)][int]$CaptureIntervalMs = 8000,
    [switch]$ShowWindow,
    [switch]$DiagnosticClient
)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if ($DiagnosticClient -and -not (Test-Path -LiteralPath (Join-Path $root 'Gunny92/Flash/2.diagnostic.png'))) {
    throw 'Create Gunny92/Flash/2.diagnostic.png before enabling -DiagnosticClient.'
}
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
$env:GUNNY_PROBE_CAPTURE_MS = [string]$CaptureIntervalMs
$env:GUNNY_PROBE_SHOW = [string][int]$ShowWindow.IsPresent
$env:GUNNY_PROBE_DIAGNOSTIC = [string][int]$DiagnosticClient.IsPresent
try {
    $windowStyle = if ($ShowWindow) { 'Normal' } else { 'Hidden' }
    Start-Process -FilePath (Join-Path $output 'FlashBrowser.exe') -WorkingDirectory $output -WindowStyle $windowStyle
} finally {
    Remove-Item Env:GUNNY_PROBE_URL, Env:GUNNY_PROBE_FLASH, Env:GUNNY_PROBE_DURATION, Env:GUNNY_PROBE_CAPTURE_MS, Env:GUNNY_PROBE_SHOW, Env:GUNNY_PROBE_DIAGNOSTIC -ErrorAction SilentlyContinue
}
Write-Output "Flash probe started. Screenshots and network logs: $output"
