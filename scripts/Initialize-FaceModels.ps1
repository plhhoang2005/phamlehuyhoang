[CmdletBinding()]
param([switch]$IncludeTestImages)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$repository = Split-Path -Parent $PSScriptRoot
$modelDirectory = Join-Path $repository '.local/models/face'
New-Item -ItemType Directory -Path $modelDirectory -Force | Out-Null

function Get-VerifiedFile {
    param([string]$Url, [string]$Destination, [string]$Sha256)
    if ((Test-Path -LiteralPath $Destination) -and
        ((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -eq $Sha256)) {
        Write-Host "Verified $Destination"
        return
    }
    $temporary = "$Destination.$([Guid]::NewGuid().ToString('N')).download"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $temporary
        $actual = (Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash
        if ($actual -ne $Sha256) { throw "SHA256 mismatch for $Url. Expected $Sha256; received $actual" }
        Move-Item -LiteralPath $temporary -Destination $Destination -Force
        Write-Host "Downloaded and verified $Destination"
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}

$revision = '48b10fa505aeb51fbd127fc60a5c660040e823b7'
$media = "https://media.githubusercontent.com/media/opencv/opencv_zoo/$revision/models"
Get-VerifiedFile "$media/face_detection_yunet/face_detection_yunet_2023mar.onnx" `
    (Join-Path $modelDirectory 'face_detection_yunet_2023mar.onnx') `
    '8F2383E4DD3CFBB4553EA8718107FC0423210DC964F9F4280604804ED2552FA4'
Get-VerifiedFile "$media/face_recognition_sface/face_recognition_sface_2021dec.onnx" `
    (Join-Path $modelDirectory 'face_recognition_sface_2021dec.onnx') `
    '0BA9FBFA01B5270C96627C4EF784DA859931E02F04419C829E83484087C34E79'

# Keep each upstream license with the locally installed weights.
$raw = "https://raw.githubusercontent.com/opencv/opencv_zoo/$revision/models"
foreach ($license in @(
    @{ Model = 'face_detection_yunet'; Name = 'LICENSE-YuNet-MIT.txt' },
    @{ Model = 'face_recognition_sface'; Name = 'LICENSE-SFace-Apache-2.0.txt' }
)) {
    $destination = Join-Path $modelDirectory $license.Name
    if (-not (Test-Path -LiteralPath $destination)) {
        Invoke-WebRequest -Uri "$raw/$($license.Model)/LICENSE" -OutFile $destination
    }
}

if ($IncludeTestImages) {
    $testDirectory = Join-Path $modelDirectory 'test-images'
    New-Item -ItemType Directory -Path $testDirectory -Force | Out-Null
    Get-VerifiedFile 'https://raw.githubusercontent.com/scikit-image/scikit-image/v0.24.0/skimage/data/astronaut.png' `
        (Join-Path $testDirectory 'astronaut.png') `
        '88431CD9653CCD539741B555FB0A46B61558B301D4110412B5BC28B5E3EA6CB5'
    Get-VerifiedFile 'https://www.nasa.gov/wp-content/uploads/2024/07/sts093-309-027orig.jpg' `
        (Join-Path $testDirectory 'collins-shuttle.jpg') `
        '294434D55C19F00BFE4C078DA58A93C908BC3DF20E6925DAFF7C71830986E667'
    Get-VerifiedFile 'https://raw.githubusercontent.com/matplotlib/matplotlib/v3.10.0/lib/matplotlib/mpl-data/sample_data/grace_hopper.jpg' `
        (Join-Path $testDirectory 'grace_hopper.jpg') `
        'A8CA6D734765703B09728AB47FE59F473D93AE3967FC24C7C0288C3C7ADB7130'
}
Write-Host 'Face models ready. See docs/FACE_SETUP.md for runtime requirements and re-enrollment.'
