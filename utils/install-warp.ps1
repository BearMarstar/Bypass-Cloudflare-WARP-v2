# ============================================================
# Cloudflare WARP Installer Selector
# ============================================================

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Установка Cloudflare WARP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1 - Новый WARP (install-Cloudflare_WARP.msi)"
Write-Host "2 - Старый WARP (Cloudflare WARP.msi)"
Write-Host ""

$choice = Read-Host "Выберите вариант"

switch ($choice)
{
    "1" {
        $msi = Join-Path "C:\Users\Administrator\Desktop\Bypass-Cloudflare WARP-v2\utils\Две версии Cloudflare WARP старый и новый" "install-Cloudflare_WARP.msi"

        if (!(Test-Path $msi))
        {
            Write-Host ""
            Write-Host "Файл не найден:" -ForegroundColor Red
            Write-Host $msi
            pause
            exit
        }

        Write-Host ""
        Write-Host "Запуск установки нового WARP..." -ForegroundColor Green

        Start-Process "msiexec.exe" -ArgumentList "/i `"$msi`"" -Wait
    }

    "2" {
        $msi = Join-Path "C:\Users\Administrator\Desktop\Bypass-Cloudflare WARP-v2\utils\Две версии Cloudflare WARP старый и новый" "Cloudflare WARP.msi"

        if (!(Test-Path $msi))
        {
            Write-Host ""
            Write-Host "Файл не найден:" -ForegroundColor Red
            Write-Host $msi
            pause
            exit
        }

        Write-Host ""
        Write-Host "Запуск установки старого WARP..." -ForegroundColor Green

        Start-Process "msiexec.exe" -ArgumentList "/i `"$msi`"" -Wait
    }

    default {
        Write-Host ""
        Write-Host "Неверный выбор." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Готово."
pause