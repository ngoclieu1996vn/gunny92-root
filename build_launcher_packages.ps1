$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fixDir = 'C:\Users\Administrator\Desktop\Gunny92\scratch\Launcher_Fix'
if (Test-Path $fixDir) { Remove-Item $fixDir -Recurse -Force }
New-Item -ItemType Directory -Path "$fixDir\resources\app\flashver" -Force | Out-Null
New-Item -ItemType Directory -Path "$fixDir\resources\app\windows" -Force | Out-Null
New-Item -ItemType Directory -Path "$fixDir\resources\app\preloads" -Force | Out-Null

Copy-Item 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked\pepflashplayer.dll' "$fixDir\pepflashplayer.dll" -Force
Copy-Item 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked\pepflashplayer.dll' "$fixDir\resources\pepflashplayer.dll" -Force
Copy-Item 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked\resources\app\flashver\pepflashplayer.dll' "$fixDir\resources\app\flashver\pepflashplayer.dll" -Force
Copy-Item 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked\resources\app\flashver\pepflashplayer32_64.dll' "$fixDir\resources\app\flashver\pepflashplayer32_64.dll" -Force
Copy-Item 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked\resources\app\main.js' "$fixDir\resources\app\main.js" -Force
Copy-Item 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked\resources\app\windows\play.html' "$fixDir\resources\app\windows\play.html" -Force
Copy-Item 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked\resources\app\preloads\play.js' "$fixDir\resources\app\preloads\play.js" -Force

$readme = @"
==================================================
HUONG DAN FIX LOI 'COULDN'T LOAD PLUGIN' (NHANH CHONG)
==================================================
Ban khong can phai tai lai ca bo cai 340MB! Chi can lam 3 buoc sau:

1. Tat phan mem Launcher Gunny (neu dang mo).
2. Giai nen file zip nay, copy toan bo noi dung:
   - File 'pepflashplayer.dll'
   - Thu muc 'resources'
3. Dan (Paste) de vao thu muc Launcher Gunny 9.2 tren may ban.
   Khi Windows hoi, chon 'Replace the files in the destination' (Ghi de tat ca).
4. Mo lai 'EasyGunny Team.exe' va dang nhap -> Flash se load muot ma 100%!
==================================================
"@
[System.IO.File]::WriteAllText("$fixDir\HUONG_DAN_SUA_LOI.txt", $readme, [System.Text.Encoding]::UTF8)

$zipFix = 'c:\Users\Administrator\Desktop\Gunny92\WebPortal\Gunny92_Launcher_Fix.zip'
if (Test-Path $zipFix) { Remove-Item $zipFix -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($fixDir, $zipFix)
Write-Host "Created Gunny92_Launcher_Fix.zip: $((Get-Item $zipFix).Length) bytes"

# Also update the full Gunny92_Launcher_Windows.zip
$winUnpacked = 'c:\Users\Administrator\Desktop\Gunny92\Gunny92\launcher_base\dist\win-unpacked'
$zipFull = 'c:\Users\Administrator\Desktop\Gunny92\WebPortal\Gunny92_Launcher_Windows.zip'
if (Test-Path $zipFull) { Remove-Item $zipFull -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($winUnpacked, $zipFull)
Write-Host "Created Gunny92_Launcher_Windows.zip: $((Get-Item $zipFull).Length) bytes"
