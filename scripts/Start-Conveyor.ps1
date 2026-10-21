$conveyorPaths = @(
    "$env:LOCALAPPDATA\ConveyorByKeyoti\Conveyor.exe",
    "C:\Program Files\Keyoti\Conveyor\Conveyor.exe",
    "C:\Program Files (x86)\Keyoti\Conveyor\Conveyor.exe"
)

$conveyor = $null
foreach ($p in $conveyorPaths) {
    if (Test-Path $p) {
        $conveyor = $p
        break
    }
}

if (-not $conveyor) {
    Write-Host "Conveyor CLI chua duoc tim thay o duong dan mac dinh." -ForegroundColor Yellow
    Write-Host "Huong dan mo Conveyor bang Visual Studio:" -ForegroundColor Cyan
    Write-Host "1. Mo phamlehuyhoang.slnx bang Visual Studio 2022/2026."
    Write-Host "2. Chay profile IIS Express hoac Kestrel tren cong 5000/5001."
    Write-Host "3. Mo cua so Conveyor trong Visual Studio de lay Remote URL (https://xxx.conveyor.cloud)."
    Write-Host "4. Nhap URL nay vao nut Cai dat tren man hinh Dang nhap cua app Flutter."
} else {
    Write-Host "Khoi chay Conveyor: $conveyor" -ForegroundColor Green
    & $conveyor -p 5000
}
