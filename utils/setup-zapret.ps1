# ============================================================
#  setup-zapret-cloudflare.ps1
#  Расположение: [корень]\utils\setup-zapret-cloudflare.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ── Пути ────────────────────────────────────────────────────
$ROOT_DIR = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$REPO     = "Flowseal/zapret-discord-youtube"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Zapret Download" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Корневая папка: $ROOT_DIR" -ForegroundColor DarkGray
Write-Host ""

# ── Шаг 1: Получение версии ──────────────────────────────────
Write-Host "[1/3] Проверяем версию zapret на GitHub..." -ForegroundColor Green
try {
    $apiUrl   = "https://api.github.com/repos/$REPO/releases/latest"
    $headers  = @{ "User-Agent" = "zapret-setup-script" }
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing
    $RELEASE_VERSION = $response.tag_name -replace '^v', ''
    Write-Host "      Актуальная версия: $RELEASE_VERSION"
} catch {
    $RELEASE_VERSION = "1.9.9a"
    Write-Host "      GitHub недоступен. Версия по умолчанию: $RELEASE_VERSION" -ForegroundColor Yellow
}

$ARCHIVE_NAME = "zapret-discord-youtube-$RELEASE_VERSION.zip"
$DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$RELEASE_VERSION/$ARCHIVE_NAME"
$ARCHIVE_PATH = Join-Path $ROOT_DIR $ARCHIVE_NAME
$EXTRACT_PATH = Join-Path $ROOT_DIR "zapret-discord-youtube-$RELEASE_VERSION неизменённый"

# ── Шаг 2: Скачивание ────────────────────────────────────────
if (Test-Path $EXTRACT_PATH) {
    Write-Host "[2/3] Папка уже существует, скачивание пропущено." -ForegroundColor Yellow
} else {
    Write-Host "[2/3] Скачиваем $ARCHIVE_NAME..." -ForegroundColor Green
    try {
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ARCHIVE_PATH -UseBasicParsing
    } catch {
        Write-Host "[ОШИБКА] Не удалось скачать архив: $_" -ForegroundColor Red
        pause; exit 1
    }
    Unblock-File -Path $ARCHIVE_PATH -ErrorAction SilentlyContinue

    # ── Шаг 3: Распаковка ────────────────────────────────────
    Write-Host "[3/3] Распаковываем архив..." -ForegroundColor Green
    $TEMP_PATH = Join-Path $ROOT_DIR "_zapret_tmp"
    if (Test-Path $TEMP_PATH) { Remove-Item -Path $TEMP_PATH -Recurse -Force }
    Expand-Archive -Path $ARCHIVE_PATH -DestinationPath $TEMP_PATH -Force

    $tempChildren = Get-ChildItem -Path $TEMP_PATH
    if ($tempChildren.Count -eq 1 -and $tempChildren[0].PSIsContainer) {
        Rename-Item -Path $tempChildren[0].FullName -NewName (Split-Path $EXTRACT_PATH -Leaf)
        Move-Item -Path (Join-Path $TEMP_PATH (Split-Path $EXTRACT_PATH -Leaf)) -Destination $ROOT_DIR
        Remove-Item -Path $TEMP_PATH -Force -ErrorAction SilentlyContinue
    } else {
        Rename-Item -Path $TEMP_PATH -NewName (Split-Path $EXTRACT_PATH -Leaf)
    }
    if (Test-Path $ARCHIVE_PATH) { Remove-Item -Path $ARCHIVE_PATH -Force }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Готово! Папка: $(Split-Path $EXTRACT_PATH -Leaf)" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan