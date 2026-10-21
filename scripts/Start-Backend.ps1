param(
    [switch]$NoBuild
)
$projectRoot = Split-Path $PSScriptRoot -Parent
$apiDir = Join-Path $projectRoot 'api\phamlehuyhoang'

# Khởi động PostgreSQL local nếu chưa chạy
& (Join-Path $PSScriptRoot 'Start-Database.ps1')

Write-Host "Khoi dong ASP.NET Core WebAPI phamlehuyhoang..." -ForegroundColor Cyan
Set-Location $apiDir
dotnet run --launch-profile "http"
