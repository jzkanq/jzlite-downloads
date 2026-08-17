# JZLite Windows PowerShell 1-Click Installer
# Usage in PowerShell:
#   irm https://raw.githubusercontent.com/jzkanq/jzlite-downloads/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$version = "1.0.5"
$downloadUrl = "https://github.com/jzkanq/jzlite-downloads/releases/download/v$version/JZLite-$version-UNSIGNED-EXPERIMENTAL.tgz"
$downloadsFolder = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
$installDir = Join-Path $downloadsFolder "JZLite-$version"
$archivePath = Join-Path $installDir "JZLite.tgz"

Write-Host ""
Write-Host "  ██╗███████╗██╗     ██╗████████╗███████╗" -ForegroundColor Cyan
Write-Host "  ██║╚══███╔╝██║     ██║╚══██╔══╝██╔════╝" -ForegroundColor Cyan
Write-Host "  ██║  ███╔╝ ██║     ██║   ██║   █████╗  " -ForegroundColor Cyan
Write-Host "████║ ███╔╝  ██║     ██║   ██║   ██╔══╝  " -ForegroundColor Cyan
Write-Host "╚███║███████╗███████╗██║   ██║   ███████╗" -ForegroundColor Cyan
Write-Host "  JZLite Cloud-Connected Router Engine v$version" -ForegroundColor Green
Write-Host ""

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

if (Test-Path -LiteralPath $installDir) {
    Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

Write-Host "Downloading JZLite v$version package..." -ForegroundColor Yellow
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    & curl.exe -fSL -o $archivePath $downloadUrl
} else {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing
}

Write-Host "Extracting installer..." -ForegroundColor Yellow
tar.exe -xzf $archivePath -C $installDir

Set-Location -LiteralPath $installDir
Write-Host "Launching installer..." -ForegroundColor Green
if ($args.Count -gt 0) {
    & ".\Install-JZLite.bat" $args
} else {
    & ".\Install-JZLite.bat"
}
