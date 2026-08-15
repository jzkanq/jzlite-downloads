# JZLite Windows PowerShell 1-Click Installer
# Usage in PowerShell:
#   irm https://raw.githubusercontent.com/jzkanq/jzlite-downloads/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$version = "1.0.3"
$downloadUrl = "https://github.com/jzkanq/jzlite-downloads/releases/download/v$version/JZLite-$version-UNSIGNED-EXPERIMENTAL.tgz"
$tempDir = Join-Path $env:TEMP "JZLite-$version-Setup"
$archivePath = Join-Path $tempDir "JZLite.tgz"

Write-Host ""
Write-Host "  ██╗███████╗██╗     ██╗████████╗███████╗" -ForegroundColor Cyan
Write-Host "  ██║╚══███╔╝██║     ██║╚══██╔══╝██╔════╝" -ForegroundColor Cyan
Write-Host "  ██║  ███╔╝ ██║     ██║   ██║   █████╗  " -ForegroundColor Cyan
Write-Host "████║ ███╔╝  ██║     ██║   ██║   ██╔══╝  " -ForegroundColor Cyan
Write-Host "╚███║███████╗███████╗██║   ██║   ███████╗" -ForegroundColor Cyan
Write-Host "  JZLite Cloud-Connected Router Engine v$version" -ForegroundColor Green
Write-Host ""

if (Test-Path -LiteralPath $tempDir) {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

Write-Host "Downloading JZLite v$version package..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing

Write-Host "Extracting installer..." -ForegroundColor Yellow
tar.exe -xzf $archivePath -C $tempDir

Set-Location -LiteralPath $tempDir
Write-Host "Launching installer..." -ForegroundColor Green
& ".\Install-JZLite.bat" --install-persistent
