param(
    [string]$PostgresBin = 'C:\Program Files\PostgreSQL\18\bin'
)
$projectRoot = Split-Path $PSScriptRoot -Parent
$localDir = Join-Path $projectRoot '.local'
$dataDir = Join-Path $localDir 'pg-data'

if (-not (Test-Path $dataDir)) {
    & (Join-Path $PSScriptRoot 'Initialize-Local.ps1')
    return
}

& (Join-Path $PostgresBin 'pg_ctl.exe') -D $dataDir status *> $null
if ($LASTEXITCODE -ne 0) {
    & (Join-Path $PostgresBin 'pg_ctl.exe') -D $dataDir -l (Join-Path $localDir 'postgres.log') -w start
}
