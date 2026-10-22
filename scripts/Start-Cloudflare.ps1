$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskLocal = Join-Path $taskRoot '.local'
$taskToolDirectory = Join-Path $taskLocal 'tools'
$taskExecutable = Join-Path $taskToolDirectory 'cloudflared.exe'
$taskStatePath = Join-Path $taskLocal 'quick-tunnel.json'
$taskOrigin = 'http://127.0.0.1:5000'

try {
    $taskHealth = Invoke-RestMethod -Uri "$taskOrigin/health" -TimeoutSec 5 -ErrorAction Stop
    if ($taskHealth.service -ne 'phamlehuyhoang.WebAPI' -or $taskHealth.status -ne 'Healthy') {
        throw 'WebAPI chua san sang.'
    }
} catch {
    Write-Host "`n[!] WebAPI (Backend) chua khoi dong! Hay mo mot terminal va chay truoc:" -ForegroundColor Yellow
    Write-Host "    powershell -ExecutionPolicy Bypass -File scripts\Start-Backend.ps1`n" -ForegroundColor Cyan
    throw "WebAPI chua san sang tai $taskOrigin."
}
if (Test-Path -LiteralPath $taskStatePath) {
    $taskPrevious = Get-Content -Raw -LiteralPath $taskStatePath | ConvertFrom-Json
    $taskExisting = Get-Process -Id $taskPrevious.ProcessId -ErrorAction SilentlyContinue
    if ($taskExisting -and $taskExisting.Path -eq $taskExecutable -and
        $taskExisting.StartTime.ToUniversalTime().ToString('O') -eq $taskPrevious.StartedAtUtc) {
        $externalHealthy = $false
        try {
            $checkResp = Invoke-RestMethod -Uri "$($taskPrevious.Url)/health" -TimeoutSec 4 -ErrorAction Stop
            if ($checkResp.status -eq 'Healthy') { $externalHealthy = $true }
        } catch { }
        if ($externalHealthy) {
            Write-Output "Tunnel dang chay: $($taskPrevious.Url)"
            Write-Output "Health: $($taskPrevious.Url)/health"
            return
        }
        Stop-Process -Id $taskExisting.Id -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $taskStatePath -ErrorAction SilentlyContinue
    }
}

# Portable client pinned to the verified official Cloudflare release.
New-Item -ItemType Directory -Path $taskToolDirectory -Force | Out-Null
$taskExpectedHash = '12C7C887F8AAAB779AEF1DFA9B60673530A5ADB88ECC55DD6DF8F56E0B70F199'
if (-not (Test-Path -LiteralPath $taskExecutable)) {
    Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/download/2026.10.2/cloudflared-windows-amd64.exe' -OutFile $taskExecutable -TimeoutSec 180
}
if ((Get-FileHash -LiteralPath $taskExecutable -Algorithm SHA256).Hash -ne $taskExpectedHash) {
    throw 'Cloudflared SHA256 khong khop ban chinh thuc. Khong thuc thi.'
}
foreach ($taskConfig in @('config.yml', 'config.yaml')) {
    if (Test-Path -LiteralPath (Join-Path $env:USERPROFILE ".cloudflared/$taskConfig")) {
        throw 'Phat hien cau hinh Cloudflare rieng trong user profile. Khong tu sua cau hinh nay; Quick Tunnel can moi truong khong nap cau hinh tunnel khac.'
    }
}
$taskLog = Join-Path $taskLocal ('cloudflare-' + [Guid]::NewGuid().ToString('N') + '.log')
$taskProcess = Start-Process -FilePath $taskExecutable -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -ArgumentList @(
    'tunnel', '--no-autoupdate', '--protocol', 'http2', '--url', $taskOrigin, '--logfile', ('"' + $taskLog + '"')
)
try {
    $taskDeadline = [DateTime]::UtcNow.AddSeconds(45)
    do {
        Start-Sleep -Milliseconds 500
        $taskProcess.Refresh()
        if ($taskProcess.HasExited) { throw "Cloudflared da dung. Xem $taskLog" }
        if (Test-Path -LiteralPath $taskLog) {
            $taskLogText = Get-Content -LiteralPath $taskLog -Raw
            $taskUrlMatch = [regex]::Match($taskLogText, 'https://[a-z0-9-]+\.trycloudflare\.com')
            if ($taskUrlMatch.Success -and $taskLogText.Contains('Registered tunnel connection')) {
                [pscustomobject]@{
                    Url = $taskUrlMatch.Value
                    Origin = $taskOrigin
                    ProcessId = $taskProcess.Id
                    StartedAtUtc = $taskProcess.StartTime.ToUniversalTime().ToString('O')
                    LogFile = $taskLog
                } | ConvertTo-Json | Set-Content -LiteralPath $taskStatePath -Encoding utf8
                Write-Output "API URL: $($taskUrlMatch.Value)"
                Write-Output "Health: $($taskUrlMatch.Value)/health"
                Write-Output 'Tunnel chay nen. Giu may, WebAPI va PostgreSQL dang chay. URL doi khi tao tunnel moi.'
                return
            }
        }
    } while ([DateTime]::UtcNow -lt $taskDeadline)
    throw "Chua ket noi duoc Cloudflare trong 45 giay. Xem $taskLog"
} catch {
    $taskProcess.Refresh()
    if (-not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id }
    throw
}
