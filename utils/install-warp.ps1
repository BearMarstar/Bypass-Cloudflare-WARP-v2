# ============================================================
# Cloudflare WARP Installer Selector
# ============================================================

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host

# Определяем рабочую директорию (папка, где лежит сам скрипт)
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

Write-Host "Сканирование папки на наличие установщиков..." -ForegroundColor Yellow

# Автоматический поиск файлов по имени во всех подпапках
$newWarp = Get-ChildItem -Path $ScriptDir -Filter "install-Cloudflare_WARP.msi" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
$oldWarp = Get-ChildItem -Path $ScriptDir -Filter "Cloudflare WARP.msi" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Установка Cloudflare WARP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Формируем подсказки для меню, чтобы сразу видеть статус файлов
$newStatus = if ($newWarp) { "[Доступен]" } else { "[X НЕ НАЙДЕН]" }
$oldStatus = if ($oldWarp) { "[Доступен]" } else { "[X НЕ НАЙДЕН]" }

Write-Host "1 - Новый WARP (install-Cloudflare_WARP.msi) -- $newStatus"
Write-Host "2 - Старый WARP (Cloudflare WARP.msi) -------- $oldStatus"
Write-Host ""

$choice = Read-Host "Выберите вариант"

switch ($choice)
{
    "1" {
        if (!$newWarp)
        {
            Write-Host ""
            Write-Host "Ошибка: Файл install-Cloudflare_WARP.msi не найден в директории скрипта!" -ForegroundColor Red
            pause
            exit
        }

        Write-Host ""
        Write-Host "Запуск установки нового WARP..." -ForegroundColor Green
        Write-Host "Файл: $($newWarp.FullName)" -ForegroundColor DarkGray

        Start-Process "msiexec.exe" -ArgumentList "/i `"$($newWarp.FullName)`"" -Wait
    }

    "2" {
        if (!$oldWarp)
        {
            Write-Host ""
            Write-Host "Ошибка: Файл Cloudflare WARP.msi не найден в директории скрипта!" -ForegroundColor Red
            pause
            exit
        }

        Write-Host ""
        Write-Host "Запуск установки старого WARP..." -ForegroundColor Green
        Write-Host "Файл: $($oldWarp.FullName)" -ForegroundColor DarkGray

        Start-Process "msiexec.exe" -ArgumentList "/i `"$($oldWarp.FullName)`"" -Wait
    }

    default {
        Write-Host ""
        Write-Host "Неверный выбор." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Готово."
pause
