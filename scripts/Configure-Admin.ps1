param(
    [string]$Username,
    [string]$Email,
    [Security.SecureString]$Password
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Username)) { $Username = Read-Host 'Ten dang nhap quan tri vien MOI' }
if ([string]::IsNullOrWhiteSpace($Email)) { $Email = Read-Host 'Email THAT de nhan OTP quan tri vien' }
$Username = $Username.Trim().ToLowerInvariant()
$Email = $Email.Trim().ToLowerInvariant()
if ($Username -notmatch '^[a-z0-9_.-]{3,50}$') { throw 'Ten dang nhap can 3-50 ky tu: chu, so, _, ., -.' }
try { $null = [System.Net.Mail.MailAddress]::new($Email) }
catch { throw 'Email khong hop le.' }
if (-not $Password) { $Password = Read-Host 'Mat khau moi (toi thieu 8 ky tu)' -AsSecureString }
$taskCredential = [System.Net.NetworkCredential]::new('', $Password)
$taskPassword = $taskCredential.Password
if ($taskPassword.Length -lt 8) { throw 'Mat khau can toi thieu 8 ky tu.' }
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskSettingsPath = Join-Path $taskRoot '.local/api-settings.json'
if (-not (Test-Path -LiteralPath $taskSettingsPath)) { throw 'Chay scripts/Initialize-Local.ps1 truoc.' }
$taskSettings = Get-Content -Raw -LiteralPath $taskSettingsPath | ConvertFrom-Json
$taskSettings | Add-Member -NotePropertyName 'BootstrapAdmin' -NotePropertyValue ([pscustomobject]@{
    Username = $Username; Email = $Email; Password = $taskPassword
}) -Force
$taskSettings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskSettingsPath -Encoding utf8
$taskPassword = $null
$taskCredential = $null
Write-Host 'Da luu cau hinh admin rieng. Dung username/email moi, khong ghi de tai khoan cu.'
Write-Host 'Khoi dong lai WebAPI, dang nhap de nhan OTP kich hoat email, sau do dang nhap voi OTP moi.'
Write-Host 'Sau khi tao thanh cong, xoa muc BootstrapAdmin trong .local/api-settings.json de bo mat khau bootstrap.'
