param(
    [string]$SenderEmail,
    [Security.SecureString]$AppPassword,
    [string]$SmtpHost = 'smtp.gmail.com',
    [ValidateRange(1,65535)][int]$Port = 587
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SenderEmail)) {
    $SenderEmail = Read-Host 'Dia chi Gmail dung de GUI ma OTP'
}
try { $null = [System.Net.Mail.MailAddress]::new($SenderEmail) }
catch { throw 'Dia chi email khong hop le.' }
if (-not $AppPassword) {
    $AppPassword = Read-Host 'App Password cua tai khoan gui (khong phai mat khau Gmail)' -AsSecureString
}
$taskCredential = [System.Net.NetworkCredential]::new('', $AppPassword)
$taskPassword = $taskCredential.Password
if ($SmtpHost -eq 'smtp.gmail.com') { $taskPassword = $taskPassword.Replace(' ', '') }
if ([string]::IsNullOrWhiteSpace($taskPassword)) { throw 'Chua nhap App Password.' }

$taskRoot = Split-Path $PSScriptRoot -Parent
$taskLocal = Join-Path $taskRoot '.local'
$taskSettingsPath = Join-Path $taskLocal 'api-settings.json'
if (-not (Test-Path -LiteralPath $taskSettingsPath)) {
    throw 'Chay scripts/Initialize-Local.ps1 truoc de tao cau hinh database.'
}
$taskSettings = Get-Content -Raw -LiteralPath $taskSettingsPath | ConvertFrom-Json
$taskSettings | Add-Member -NotePropertyName 'Smtp' -NotePropertyValue ([pscustomobject]@{
    Host = $SmtpHost; Port = $Port; User = $SenderEmail; Password = $taskPassword
}) -Force
$taskSettings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskSettingsPath -Encoding utf8
$taskPassword = $null
$taskCredential = $null
Write-Host 'Da luu cau hinh email rieng trong .local/api-settings.json (duoc gitignore).'
Write-Host 'Khoi dong lai WebAPI de ap dung. Khong chia se file cau hinh hoac App Password.'
