# ================================================
# Автоматическое создание задачи в Планировщике
# Отключает автоподключение Cloudflare WARP при запуске ПК
# Запускай от имени АДМИНИСТРАТОРА
# ================================================

$ErrorActionPreference = "Stop"
Write-Host "=== Создание задачи для отключения автоподключения WARP ===" -ForegroundColor Cyan

# === НАСТРОЙКИ (можно изменить) ===
$TaskName        = "Disable Cloudflare WARP AutoStart"
$TaskDescription = "Автоматически отключает автоподключение Cloudflare WARP при запуске компьютера"
$ScriptPath      = Join-Path $PSScriptRoot "Disable-WARP-AutoStart.ps1"   # путь к скрипту отключения

# Проверяем, существует ли скрипт отключения
if (-not (Test-Path $ScriptPath)) {
    Write-Host "Ошибка: Файл Disable-WARP-AutoStart.ps1 не найден рядом со скриптом!" -ForegroundColor Red
    Write-Host "Положи оба скрипта в одну папку (например, в utils)" -ForegroundColor Yellow
    Pause
    exit 1
}

# Удаляем старую задачу, если она уже существует
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "Старая задача найдена. Удаляем..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Создаём новую задачу
Write-Host "Создаём новую задачу..." -ForegroundColor Green

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description $TaskDescription `
    -Force | Out-Null

Write-Host ""
Write-Host "✅ Задача успешно создана!" -ForegroundColor Green
Write-Host "Название задачи: $TaskName" -ForegroundColor Cyan
Write-Host ""
Write-Host "Теперь при каждом включении компьютера WARP будет автоматически отключаться." -ForegroundColor Green
Write-Host "Ты можешь запускать WARP вручную, когда он тебе нужен." -ForegroundColor Cyan

Pause