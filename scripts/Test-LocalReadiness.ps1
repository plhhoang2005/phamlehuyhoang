$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskSettingsPath = Join-Path $taskRoot '.local/api-settings.json'
if (-not (Test-Path -LiteralPath $taskSettingsPath)) { throw 'Chua khoi tao cau hinh local.' }
$taskSettings = Get-Content -Raw -LiteralPath $taskSettingsPath | ConvertFrom-Json
function Get-SettingOrEnvironment([string]$Name) {
    $taskValue = [Environment]::GetEnvironmentVariable('SMTP_' + $Name.ToUpperInvariant())
    if (-not [string]::IsNullOrWhiteSpace($taskValue)) { return $taskValue }
    if ($taskSettings.Smtp) { return $taskSettings.Smtp.$Name }
    return $null
}
$taskSmtpReady = $true
foreach ($taskField in @('Host','User','Password')) {
    if ([string]::IsNullOrWhiteSpace((Get-SettingOrEnvironment $taskField))) { $taskSmtpReady = $false }
}
[pscustomobject]@{
    SmtpConfigured = $taskSmtpReady
    BootstrapAdminConfigured = [bool]($taskSettings.BootstrapAdmin.Username -and $taskSettings.BootstrapAdmin.Email -and $taskSettings.BootstrapAdmin.Password)
    FaceDetectorInstalled = Test-Path -LiteralPath (Join-Path $taskRoot '.local/models/face/face_detection_yunet_2023mar.onnx')
    FaceRecognizerInstalled = Test-Path -LiteralPath (Join-Path $taskRoot '.local/models/face/face_recognition_sface_2021dec.onnx')
}
Write-Host 'Chi kiem tra su hien dien cua cau hinh; khong in bi mat, khong thay the kiem tra email/nhan dien thuc te.'
