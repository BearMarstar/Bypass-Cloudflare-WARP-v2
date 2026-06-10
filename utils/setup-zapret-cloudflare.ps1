# ============================================================
#  setup-zapret-cloudflare.ps1
#  Расположение: [корень]\utils\setup-zapret-cloudflare.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ── Пути ────────────────────────────────────────────────────
$ROOT_DIR = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$REPO     = "Flowseal/zapret-discord-youtube"

# ── Домены Cloudflare для list-general ──────────────────────
$CLOUDFLARE_DOMAINS = @"
signin.aws.amazon.com
cloudfront.net
s3.amazonaws.com
awsstatic.com
console.aws.a2z.com
amazonaws.com
awsapps.com
sso.amazonaws.com
deadbydaylight.com
deadbydaylight.fandom.com
argotunnel.com
cfargotunnel.com
cfl.re
cloudflare-dns.com
cloudflare-ech.com
cloudflare-esni.com
cloudflare-gateway.com
cloudflare-quic.com
cloudflare.com
cloudflare.net
cloudflare.tv
cloudflareaccess.com
cloudflareapps.com
cloudflarebolt.com
cloudflareclient.com
cloudflareinsights.com
cloudflareok.com
cloudflarepartners.com
cloudflareportal.com
cloudflarepreview.com
cloudflareresolve.com
cloudflaressl.com
cloudflarestatus.com
cloudflarestorage.com
cloudflarestream.com
cloudflaretest.com
cloudflarewarp.com
every1dns.net
isbgpsafeyet.com
pacloudflare.com
pages.dev
trycloudflare.com
videodelivery.net
warp.plus
workers.dev
cloudflare-ipfs.com
"@

# ── Стратегии Cloudflare ─────────────────────────────────────
$NEW_STRATEGIES = @(
    '--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^',
    '--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin" --new ^',
    '--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin"'
)

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Zapret Cloudflare Setup (Фикс рабочей папки)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Корневая папка: $ROOT_DIR" -ForegroundColor DarkGray
Write-Host ""

# ── Шаг 1: Получение версии ──────────────────────────────────
Write-Host "[1/6] Проверяем версию zapret на GitHub..." -ForegroundColor Green
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
$EXTRACT_PATH = Join-Path $ROOT_DIR "zapret-discord-youtube-$RELEASE_VERSION"

# ── Шаг 2: Скачивание ────────────────────────────────────────
if (Test-Path $EXTRACT_PATH) {
    Write-Host "[2/6] Папка уже существует, скачивание пропущено." -ForegroundColor Yellow
} else {
    Write-Host "[2/6] Скачиваем $ARCHIVE_NAME..." -ForegroundColor Green
    try {
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ARCHIVE_PATH -UseBasicParsing
    } catch {
        Write-Host "[ОШИБКА] Не удалось скачать архив: $_" -ForegroundColor Red
        pause; exit 1
    }
    Unblock-File -Path $ARCHIVE_PATH -ErrorAction SilentlyContinue

    # ── Шаг 3: Распаковка ────────────────────────────────────
    Write-Host "[3/6] Распаковываем архив..." -ForegroundColor Green
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

# ── Шаг 4: Получение IP ──────────────────────────────────────
$listsDir  = Join-Path $EXTRACT_PATH "lists"
$ipsetFile = Join-Path $listsDir "ipset-cloudflare.txt"

Write-Host "[4/6] Обновляем IP Cloudflare..." -ForegroundColor Green
if (-not (Test-Path $listsDir)) { New-Item -ItemType Directory -Path $listsDir | Out-Null }

try {
    $liveIPs = Invoke-RestMethod -Uri "https://www.cloudflare.com/ips-v4" -UseBasicParsing
    $ipLines = ($liveIPs.Trim() -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Select-Object -Unique
} catch {
    $fallbackIPs = "103.21.244.0/22`n103.22.200.0/22`n103.31.4.0/22`n104.16.0.0/13`n104.24.0.0/14`n108.162.192.0/18`n131.0.72.0/22`n141.101.64.0/18`n162.158.0.0/15`n172.64.0.0/13`n173.245.48.0/20`n188.114.96.0/20`n190.93.240.0/20`n197.234.240.0/20`n198.41.128.0/17"
    $ipLines = ($fallbackIPs -split "`n") | ForEach-Object { $_.Trim() }
}
$ipsContent = ($ipLines -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText($ipsetFile, $ipsContent, [System.Text.Encoding]::ASCII)

# ── Шаг 5: Обновление доменов ────────────────────────────────
$listGeneral = Join-Path $listsDir "list-general.txt"
Write-Host "[5/6] Добавляем домены в list-general.txt..." -ForegroundColor Green
if (-not (Test-Path $listGeneral)) { [System.IO.File]::WriteAllText($listGeneral, "", [System.Text.Encoding]::ASCII) }

$existingRaw = [System.IO.File]::ReadAllLines($listGeneral)
$existingSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($line in $existingRaw) { $trimmed = $line.Trim(); if ($trimmed -ne "") { [void]$existingSet.Add($trimmed) } }

$newDomains = ($CLOUDFLARE_DOMAINS.Trim() -split "`n") | ForEach-Object { $_.Trim() } | 
    Where-Object { $_ -ne "" -and $_ -notmatch '^https?://' -and -not $existingSet.Contains($_) } | Select-Object -Unique

if ($newDomains.Count -gt 0) {
    $appendText = "`r`n" + ($newDomains -join "`r`n") + "`r`n"
    [System.IO.File]::AppendAllText($listGeneral, $appendText, [System.Text.Encoding]::ASCII)
}

# ── Проверка процессов ───────────────────────────────────────
$winwsProc = Get-Process -Name "winws" -ErrorAction SilentlyContinue
if ($winwsProc) {
    Write-Host "`n  [!] Обнаружен запущенный winws.exe. Остановить автоматически? (Y/N): " -NoNewline -ForegroundColor Yellow
    $answer = Read-Host
    if ($answer -match '^[YyДд]') { Stop-Process -Name "winws" -Force; Start-Sleep -Seconds 1 }
}

# ── Шаг 6: Создание папки и копирование/патчинг батников ──────
Write-Host "[6/6] Создаем изолированные профили Cloudflare..." -ForegroundColor Green

$outputDir = Join-Path $EXTRACT_PATH "Cloudflare_Profiles"
if (-not (Test-Path $outputDir)) { 
    New-Item -ItemType Directory -Path $outputDir | Out-Null 
}

function Patch-AndMoveBatFile {
    param(
        [string]$OriginalPath, 
        [string]$DestinationPath, 
        [string[]]$Strategies
    )

    $enc      = [System.Text.Encoding]::GetEncoding(1251)
    $batBytes = [System.IO.File]::ReadAllBytes($OriginalPath)
    $batText  = $enc.GetString($batBytes)
    $batLines = $batText -split "`r`n"

    # Шаг А: Находим строку запуска winws.exe
    $winwsIdx = -1
    for ($i = 0; $i -lt $batLines.Length; $i++) {
        if ($batLines[$i] -match '"%BIN%winws\.exe"') { $winwsIdx = $i; break }
    }
    if ($winwsIdx -lt 0) { return "no_winws" }

    # Шаг Б: Корректируем инициализацию рабочей папки и переменные путей
    for ($i = 0; $i -lt $winwsIdx; $i++) {
        # Перенаправляем батник в корень zapret сразу при старте
        if ($batLines[$i] -match 'cd\s+/d\s+"%~dp0"') {
            $batLines[$i] = 'cd /d "%~dp0..\"'
        }
        # Переменные BIN и LISTS теперь объявляются относительно нового корня
        if ($batLines[$i] -match 'set\s+"BIN=%~dp0bin\\"') {
            $batLines[$i] = 'set "BIN=%cd%\bin\\"'
        }
        if ($batLines[$i] -match 'set\s+"LISTS=%~dp0lists\\"') {
            $batLines[$i] = 'set "LISTS=%cd%\lists\\"'
        }
    }

    # Шаг В: Проверяем и форматируем строку вызова winws.exe
    $winwsLine = $batLines[$winwsIdx].TrimEnd()
    if (-not $winwsLine.EndsWith('^')) {
        $winwsLine = $winwsLine + " ^"
    }

    # Собираем новую «голову» файла
    $cleanLines = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $winwsIdx; $i++) {
        $cleanLines.Add($batLines[$i])
    }
    $cleanLines.Add($winwsLine)

    # Шаг Г: Ищем хвост файла (goto, pause, exit)
    $tailLines = New-Object System.Collections.Generic.List[string]
    $foundTail = $false
    for ($i = $winwsIdx + 1; $i -lt $batLines.Length; $i++) {
        $trimmed = $batLines[$i].Trim()
        if ($foundTail -or $trimmed -match '^goto' -or $trimmed -match '^pause' -or $trimmed -match '^exit') {
            $foundTail = $true
            $tailLines.Add($batLines[$i])
        }
    }

    # Шаг Д: Финальная сборка структуры
    $finalLines = @()
    $finalLines += $cleanLines.ToArray()
    $finalLines += $Strategies
    if ($tailLines.Count -gt 0) {
        $finalLines[-1] = $finalLines[-1].TrimEnd() + " ^"
        $finalLines += $tailLines.ToArray()
    }

    if ($finalLines[0] -match '^@echo off') {
        $marker = ":: [Cloudflare Profiles] Запуск из корня zapret через перенаправление папки"
        $finalLines = @($finalLines[0], $marker) + $finalLines[1..($finalLines.Length-1)]
    }

    # Запись файла
    $newBytes = $enc.GetBytes(($finalLines -join "`r`n"))
    [System.IO.File]::WriteAllBytes($DestinationPath, $newBytes)
    return "patched"
}

# Список батников
$targetNames = @(
    "general (ALT).bat", "general (ALT2).bat", "general (ALT3).bat", "general (ALT4).bat",
    "general (ALT5).bat", "general (ALT6).bat", "general (ALT7).bat", "general (ALT8).bat",
    "general (ALT9).bat", "general (ALT10).bat", "general (ALT11).bat", "general (ALT12).bat",
    "general (FAKE TLS AUTO ALT).bat", "general (FAKE TLS AUTO ALT2).bat", "general (FAKE TLS AUTO ALT3).bat",
    "general (FAKE TLS AUTO).bat", "general (SIMPLE FAKE ALT).bat", "general (SIMPLE FAKE ALT2).bat",
    "general (SIMPLE FAKE).bat", "general.bat"
)

$patchedCount = 0

foreach ($name in $targetNames) {
    $originalBatPath = Join-Path $EXTRACT_PATH $name
    if (-not (Test-Path $originalBatPath)) { continue }

    $newName = $name -replace '\.bat$', ' Cloudflare.bat'
    $destinationBatPath = Join-Path $outputDir $newName

    $result = Patch-AndMoveBatFile -OriginalPath $originalBatPath -DestinationPath $destinationBatPath -Strategies $NEW_STRATEGIES
    if ($result -eq "patched") {
        Write-Host "      [+] Создан стабильный профиль: Cloudflare_Profiles\$newName" -ForegroundColor Green
        $patchedCount++
    }
}

Write-Host "`n  Успешно изолировано: $patchedCount файлов в папку Cloudflare_Profiles." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Готово! Ошибки путей устранены полностью." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan