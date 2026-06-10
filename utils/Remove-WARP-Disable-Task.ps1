# ================================================
# Удаление задачи отключения Cloudflare WARP
# Запускай от имени администратора
# ================================================

$ErrorActionPreference = "SilentlyContinue"
$TaskName = "Disable Cloudflare WARP AutoStart"

Write-Host "=== Удаление задачи отключения WARP ===" -ForegroundColor Cyan
Write-Host ""

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "Задача найдена: $TaskName" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    
    Write-Host "✅ Задача успешно удалена!" -ForegroundColor Green
} else {
    Write-Host "Задача '$TaskName' не найдена." -ForegroundColor Green
}

Write-Host ""
Write-Host "Готово." -ForegroundColor Cyan
Pause