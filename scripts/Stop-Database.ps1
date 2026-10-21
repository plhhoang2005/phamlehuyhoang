param(
    [string]$PostgresBin = 'C:\Program Files\PostgreSQL\18\bin'
)
$projectRoot = Split-Path $PSScriptRoot -Parent
$dataDir = Join-Path $projectRoot '.local\pg-data'

if (Test-Path $dataDir) {
    & (Join-Path $PostgresBin 'pg_ctl.exe') -D $dataDir stop -m fast
}
