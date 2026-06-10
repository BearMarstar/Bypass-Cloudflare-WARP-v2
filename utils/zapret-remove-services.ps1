$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       Remove Zapret Services"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Остановка и удаление службы zapret
$service = Get-Service -Name "zapret" -ErrorAction SilentlyContinue

if ($service) {
    Write-Host "Останавливаем службу zapret..."
    Stop-Service -Name "zapret" -Force -ErrorAction SilentlyContinue

    Write-Host "Удаляем службу zapret..."
    sc.exe delete zapret | Out-Null
}
else {
    Write-Host 'Служба "zapret" не установлена.'
}

# Завершаем winws.exe
$winws = Get-Process -Name "winws" -ErrorAction SilentlyContinue

if ($winws) {
    Write-Host "Завершаем winws.exe..."
    $winws | Stop-Process -Force
}

# WinDivert
$windivert = Get-Service -Name "WinDivert" -ErrorAction SilentlyContinue

if ($windivert) {
    Write-Host "Останавливаем WinDivert..."
    Stop-Service -Name "WinDivert" -Force -ErrorAction SilentlyContinue

    Write-Host "Удаляем WinDivert..."
    sc.exe delete WinDivert | Out-Null
}

# WinDivert14
$windivert14 = Get-Service -Name "WinDivert14" -ErrorAction SilentlyContinue

if ($windivert14) {
    Write-Host "Останавливаем WinDivert14..."
    Stop-Service -Name "WinDivert14" -Force -ErrorAction SilentlyContinue

    Write-Host "Удаляем WinDivert14..."
    sc.exe delete WinDivert14 | Out-Null
}

Write-Host ""
Write-Host "Готово." -ForegroundColor Green
Write-Host ""

Pause