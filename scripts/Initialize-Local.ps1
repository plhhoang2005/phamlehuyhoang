param(
    [string]$PostgresBin = 'C:\Program Files\PostgreSQL\18\bin',
    [ValidateRange(1024,65535)][int]$Port = 54321,
    [switch]$StartOnly
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$projectRoot = Split-Path $PSScriptRoot -Parent
$localDir = Join-Path $projectRoot '.local'
$dataDir = Join-Path $localDir 'pg-data'
$statePath = Join-Path $localDir 'state.json'
New-Item -ItemType Directory -Path $localDir -Force | Out-Null

foreach ($binary in @('initdb.exe','pg_ctl.exe','psql.exe','createdb.exe')) {
    if (-not (Test-Path -LiteralPath (Join-Path $PostgresBin $binary))) { throw "Khong tim thay $binary trong $PostgresBin" }
}

function New-LocalSecret {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    [Convert]::ToBase64String($bytes)
}

if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $Port = $state.Port
} else {
    $state = [pscustomobject]@{
        Port = $Port
        OwnerPassword = New-LocalSecret
        AppPassword = New-LocalSecret
        JwtSecret = New-LocalSecret
        AdminPassword = ('Admin@' + (New-LocalSecret).Substring(0, 8))
    }
    $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
}

if (-not (Test-Path -LiteralPath (Join-Path $dataDir 'PG_VERSION'))) {
    $passwordFile = Join-Path $localDir 'init-password.txt'
    [System.IO.File]::WriteAllText($passwordFile, $state.OwnerPassword)
    try {
        & (Join-Path $PostgresBin 'initdb.exe') -D $dataDir -U plh_owner --auth=scram-sha-256 --encoding=UTF8 --locale=C --pwfile=$passwordFile
        if ($LASTEXITCODE -ne 0) { throw 'Khoi tao PostgreSQL that bai.' }
    } finally { Remove-Item -LiteralPath $passwordFile -ErrorAction SilentlyContinue }
}

& (Join-Path $PostgresBin 'pg_ctl.exe') -D $dataDir status *> $null
if ($LASTEXITCODE -ne 0) {
    & (Join-Path $PostgresBin 'pg_ctl.exe') -D $dataDir -l (Join-Path $localDir 'postgres.log') -o "-p $Port -h 127.0.0.1" -w start
    if ($LASTEXITCODE -ne 0) { throw 'Khong khoi dong duoc PostgreSQL. Xem .local/postgres.log.' }
}

$previousPassword = $env:PGPASSWORD
try {
    $env:PGPASSWORD = $state.OwnerPassword
    $roleExists = & (Join-Path $PostgresBin 'psql.exe') -h 127.0.0.1 -p $Port -U plh_owner -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='phamlehuyhoang_app'"
    if ($LASTEXITCODE -ne 0) { throw 'Khong ket noi duoc PostgreSQL local.' }
    if ($roleExists -ne '1') {
        "CREATE ROLE phamlehuyhoang_app LOGIN PASSWORD '$($state.AppPassword)';" | & (Join-Path $PostgresBin 'psql.exe') -h 127.0.0.1 -p $Port -U plh_owner -d postgres -v ON_ERROR_STOP=1
        if ($LASTEXITCODE -ne 0) { throw 'Khong tao duoc tai khoan database.' }
    }
    $dbExists = & (Join-Path $PostgresBin 'psql.exe') -h 127.0.0.1 -p $Port -U plh_owner -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='phamlehuyhoang'"
    if ($dbExists -ne '1') {
        & (Join-Path $PostgresBin 'createdb.exe') -h 127.0.0.1 -p $Port -U plh_owner -O phamlehuyhoang_app phamlehuyhoang
        if ($LASTEXITCODE -ne 0) { throw 'Khong tao duoc database.' }
    }
} finally { $env:PGPASSWORD = $previousPassword }

$connStr = "Host=127.0.0.1;Port=$Port;Database=phamlehuyhoang;Username=phamlehuyhoang_app;Password=$($state.AppPassword)"
$settings = @{
    ConnectionStrings = @{ DefaultConnection = $connStr }
    Jwt = @{ Secret = $state.JwtSecret }
    SeedAdmin = @{ Username = 'admin'; Password = $state.AdminPassword }
    Database = @{ AutoMigrate = $true; SeedDemo = $true }
}
$settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $localDir 'api-settings.json') -Encoding utf8

@"
PostgreSQL: 127.0.0.1:$Port / phamlehuyhoang
Username: phamlehuyhoang_app
Password: $($state.AppPassword)

Admin:
Username: admin
Password: $($state.AdminPassword)
"@ | Set-Content -LiteralPath (Join-Path $localDir 'dev-accounts.txt') -Encoding utf8

Write-Host "PostgreSQL local da san sang tai 127.0.0.1:$Port / phamlehuyhoang"
Write-Host "ConnectionString: $connStr"
