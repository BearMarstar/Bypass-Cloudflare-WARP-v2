# ================================================
# Отключает автоподключение WARP при запуске Windows
# Запускай от имени администратора
# ================================================

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Отключение автозапуска Cloudflare WARP ===" -ForegroundColor Cyan

$warpCli = "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"

# Останавливаем службу
Stop-Service -Name "warp-svc" -Force -ErrorAction SilentlyContinue

# Отключаем автоподключение через CLI
if (Test-Path $warpCli) {
    Write-Host "Настраиваем WARP на ручной режим..."
    
    & $warpCli disconnect | Out-Null
    & $warpCli set-mode off | Out-Null          # основной режим - отключён
    & $warpCli set-proxy-mode off | Out-Null
    & $warpCli set-dns-mode off | Out-Null
    
    Write-Host "Автоподключение WARP отключено." -ForegroundColor Green
} else {
    Write-Host "Ошибка: warp-cli.exe не найден" -ForegroundColor Red
}

# Делаем службу "Вручную"
sc.exe config warp-svc start= demand | Out-Null

Write-Host ""
Write-Host "Готово. Теперь WARP не будет подключаться автоматически при включении компьютера." -ForegroundColor Green
Write-Host "Ты можешь запускать его вручную, когда нужно." -ForegroundColor Cyan
Start-Sleep -Seconds 2