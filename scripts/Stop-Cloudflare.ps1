$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskStatePath = Join-Path $taskRoot '.local/quick-tunnel.json'
if (-not (Test-Path -LiteralPath $taskStatePath)) { Write-Output 'Chua co tunnel do project nay khoi dong.'; return }
$taskState = Get-Content -Raw -LiteralPath $taskStatePath | ConvertFrom-Json
$taskProcess = Get-Process -Id $taskState.ProcessId -ErrorAction SilentlyContinue
$taskExpectedExecutable = Join-Path $taskRoot '.local/tools/cloudflared.exe'
if ($taskProcess -and $taskProcess.Path -eq $taskExpectedExecutable -and
    $taskProcess.StartTime.ToUniversalTime().ToString('O') -eq $taskState.StartedAtUtc) {
    Stop-Process -Id $taskProcess.Id
    Write-Output 'Da dung Quick Tunnel cua project.'
} elseif ($taskProcess) {
    throw 'PID hien tai khong khop tunnel da luu. Khong dung tien trinh khac.'
} else { Write-Output 'Tunnel da dung truoc do.' }
Remove-Item -LiteralPath $taskStatePath
