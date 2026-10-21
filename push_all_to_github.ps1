# ==============================================================================
# Gunny 9.2 - Push All Repositories to GitHub in 1-Click (PowerShell)
# Usage:
#   .\push_all_to_github.ps1 -GitHubUser "myaccount" [-Protocol "https"|"ssh"]
# ==============================================================================
param(
    [string]$GitHubUser = "ngoclieu1996vn",
    [string]$Protocol = "https",
    [string]$Token = ""
)

$ErrorActionPreference = "Continue"

if ($env:Path -notlike "*Git\cmd*") {
    $env:Path += ";C:\Program Files\Git\cmd"
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Pushing all Gunny 9.2 Repositories to GitHub" -ForegroundColor Cyan
Write-Host " Account:  $GitHubUser" -ForegroundColor Yellow
Write-Host " Protocol: $Protocol" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

function Get-RepoUrl {
    param([string]$RepoName)
    if ($Protocol -eq "ssh") {
        return "git@github.com:$GitHubUser/$RepoName.git"
    } elseif ($Token) {
        return "https://${Token}@github.com/$GitHubUser/$RepoName.git"
    } else {
        return "https://github.com/$GitHubUser/$RepoName.git"
    }
}

function Push-Repo {
    param(
        [string]$RepoName,
        [string]$RepoDir
    )
    $repoUrl = Get-RepoUrl $RepoName
    if (Test-Path "$RepoDir\.git") {
        Write-Host "`n--------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "[PUSHING] $RepoName ($RepoDir) -> $repoUrl..." -ForegroundColor Green
        git -C $RepoDir remote remove origin 2>$null
        git -C $RepoDir remote add origin $repoUrl
        git -C $RepoDir branch -M master
        git -C $RepoDir push -u origin master
    } else {
        Write-Host "[SKIP] $RepoDir is not a git repository." -ForegroundColor Yellow
    }
}

$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

Push-Repo "gunny92-root" $root
Push-Repo "gunny92-webportal" "$root\WebPortal"
Push-Repo "gunny92-macos-client" "$root\macOS_Client"
Push-Repo "gunny92-server" "$root\Gunny92\Server"
Push-Repo "gunny92-flash" "$root\Gunny92\Flash"
Push-Repo "gunny92-request" "$root\Gunny92\Request"
Push-Repo "gunny92-launcher" "$root\Gunny92\launcher_base"
Push-Repo "gunny92-flashbase" "$root\Gunny92\flashbaseSrc"
Push-Repo "gunny92-gamesrc" "$root\Gunny92\gameSrc"
Push-Repo "gunny92-db" "$root\Gunny92_DB"
Push-Repo "gunny92-resource" "$root\Gunny92\Resource.Server"

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host " Push script execution finished!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
