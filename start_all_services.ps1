$ErrorActionPreference = 'SilentlyContinue'

$center = Get-Process -Name "Center.Service" -ErrorAction SilentlyContinue
if (-not $center) {
    Write-Host "Starting Center.Service..."
    cmd.exe /c "start `"Center`" /d `"C:\Gunny92\Server\center`" Center.Service.exe"
    Start-Sleep -Seconds 6
}

$fight = Get-Process -Name "Fighting.Service" -ErrorAction SilentlyContinue
if (-not $fight) {
    Write-Host "Starting Fighting.Service..."
    cmd.exe /c "start `"Fight`" /d `"C:\Gunny92\Server\fight`" Fighting.Service.exe"
    Start-Sleep -Seconds 4
}

$road = Get-Process -Name "Road.Service" -ErrorAction SilentlyContinue
if (-not $road) {
    Write-Host "Starting Road.Service..."
    cmd.exe /c "start `"Road`" /d `"C:\Gunny92\Server\road`" Road.Service.exe"
    Start-Sleep -Seconds 6
}

Get-Process -Name "Center.Service", "Fighting.Service", "Road.Service" -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, WorkingSet
