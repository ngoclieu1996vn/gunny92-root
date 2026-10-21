# ==============================================================================
# Gunny 9.2 - Automated Multi-Repository Initialization Script (PowerShell)
# Usage:
#   .\init.ps1 [-GitHubUser "myuser"] [-Protocol "https"|"ssh"]
# ==============================================================================
param(
    [string]$GitHubUser = "YOUR_USERNAME",
    [string]$Protocol = "https"
)

$ErrorActionPreference = "Continue"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Gunny 9.2 - Cloning and Assembling Full Source Code" -ForegroundColor Cyan
Write-Host " Target GitHub Account: $GitHubUser" -ForegroundColor Yellow
Write-Host " Protocol:              $Protocol" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan

if ($GitHubUser -eq "YOUR_USERNAME") {
    Write-Host "WARNING: Using default placeholder 'YOUR_USERNAME'." -ForegroundColor Red
    Write-Host "To clone from your own account, run: .\init.ps1 -GitHubUser <your_username>`n" -ForegroundColor Yellow
}

function Get-RepoUrl {
    param([string]$RepoName)
    if ($Protocol -eq "ssh") {
        return "git@github.com:$GitHubUser/$RepoName.git"
    } else {
        return "https://github.com/$GitHubUser/$RepoName.git"
    }
}

function Clone-Or-Pull {
    param(
        [string]$RepoName,
        [string]$DestDir
    )
    $repoUrl = Get-RepoUrl $RepoName
    if (Test-Path "$DestDir\.git") {
        Write-Host "[EXISTS] $DestDir already initialized. Pulling latest..." -ForegroundColor DarkGray
        git -C $DestDir pull
    } else {
        Write-Host "[CLONING] $RepoName -> $DestDir..." -ForegroundColor Green
        $parent = Split-Path $DestDir -Parent
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        git clone $repoUrl $DestDir
    }
}

$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

# 1. Clone top-level subdirectories
Clone-Or-Pull "gunny92-webportal" "$root\WebPortal"
Clone-Or-Pull "gunny92-macos-client" "$root\macOS_Client"

# 2. Ensure Gunny92 directory exists
$gunnyDir = "$root\Gunny92"
if (-not (Test-Path $gunnyDir)) { New-Item -ItemType Directory -Path $gunnyDir -Force | Out-Null }

# 3. Clone Gunny92 submodules
Clone-Or-Pull "gunny92-server" "$gunnyDir\Server"
Clone-Or-Pull "gunny92-flash" "$gunnyDir\Flash"
Clone-Or-Pull "gunny92-request" "$gunnyDir\Request"
Clone-Or-Pull "gunny92-resource" "$gunnyDir\Resource.Server"
Clone-Or-Pull "gunny92-gamesrc" "$gunnyDir\gameSrc"
Clone-Or-Pull "gunny92-flashbase" "$gunnyDir\flashbaseSrc"
Clone-Or-Pull "gunny92-launcher" "$gunnyDir\launcher_base"

# 4. Clone Web frontends & tools
$webTemp = "$gunnyDir\web_temp"
Clone-Or-Pull "gunny92-web" $webTemp
if (Test-Path $webTemp) {
    Write-Host "[SYNC] Moving web components into Gunny92..." -ForegroundColor DarkGray
    Get-ChildItem -Path $webTemp | ForEach-Object {
        $dest = Join-Path $gunnyDir $_.Name
        if (-not (Test-Path $dest)) {
            Move-Item -Path $_.FullName -Destination $dest -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item -Path $webTemp -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Clone and assemble Database backups
$dbTemp = "$gunnyDir\db_temp"
Clone-Or-Pull "gunny92-db" $dbTemp
if (Test-Path $dbTemp) {
    Write-Host "[SYNC] Moving database backups into Gunny92..." -ForegroundColor DarkGray
    Get-ChildItem -Path $dbTemp | ForEach-Object {
        $dest = Join-Path $gunnyDir $_.Name
        if (-not (Test-Path $dest)) {
            Move-Item -Path $_.FullName -Destination $dest -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item -Path $dbTemp -Recurse -Force -ErrorAction SilentlyContinue
}

# 6. Extract admin.bak.zip if needed
$adminBak = "$gunnyDir\admin.bak"
$adminZip = "$gunnyDir\admin.bak.zip"
if ((-not (Test-Path $adminBak)) -and (Test-Path $adminZip)) {
    Write-Host "[EXTRACT] Extracting $adminZip..." -ForegroundColor Cyan
    Expand-Archive -Path $adminZip -DestinationPath $gunnyDir -Force
}

# 7. Create directory junction C:\Gunny92 -> $gunnyDir
if (-not (Test-Path "C:\Gunny92")) {
    Write-Host "[JUNCTION] Creating directory junction C:\Gunny92 -> $gunnyDir..." -ForegroundColor Cyan
    cmd.exe /c "mklink /J C:\Gunny92 `"$gunnyDir`""
}

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host " Project Initialization Complete!" -ForegroundColor Green
Write-Host " Next step: Read README.md for complete instructions on running the project." -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Green
