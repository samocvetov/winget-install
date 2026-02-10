# Установка кодировки UTF-8 для корректного вывода кириллицы
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$appsToInstall = @(
    "7zip.7zip", "Notepad++.Notepad++", "RustDesk.RustDesk", "AnyDesk.AnyDesk", 
    "VideoLAN.VLC", "PDFgear.PDFgear", "Google.Chrome", "Telegram.TelegramDesktop", 
    "Zoom.Zoom", "Yandex.Browser", "Yandex.Messenger", "AdrienAllard.FileConverter", 
    "alexx2000.DoubleCommander", "WinDirStat.WinDirStat", "Piriform.Recuva", 
    "PowerSoftware.AnyBurn", "qBittorrent.qBittorrent", 
    "9NKSQGP7F2NH", "XPDDT99J9GKB5C"
)

Write-Host "`n--- Проверка доступных обновлений ---" -ForegroundColor Cyan
$updates = winget upgrade | Select-String -Pattern '^\S+' | Select-Object -Skip 2

if ($updates) {
    foreach ($line in $updates) {
        $fields = $line.ToString() -split '\s{2,}'
        $name = $fields[0].Trim()
        $id = $fields[1].Trim()

        if ($id -and $id -ne "ID") {
            $confirmUpdate = Read-Host "Обновить $name ($id)? [y/n]"
            if ($confirmUpdate -eq 'y') {
                Write-Host "Обновление $id..." -ForegroundColor Yellow
                winget upgrade --id $id --silent --accept-source-agreements --accept-package-agreements
            }
        }
    }
}

Write-Host "`n--- Установка новых пакетов ---" -ForegroundColor Cyan
foreach ($app in $appsToInstall) {
    $confirmation = Read-Host "Установить $app? [y/n]"
    if ($confirmation -eq 'y') {
        Write-Host "Установка $app..." -NoNewline -ForegroundColor White
        $process = Start-Process winget -ArgumentList "install --id $app --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0) { Write-Host "`r[ OK ] $app " -ForegroundColor Green }
        elseif ($process.ExitCode -eq -1978335189) { Write-Host "`r[SKIP] $app (Уже есть) " -ForegroundColor Gray }
        else { Write-Host "`r[FAIL] $app (Код: $($process.ExitCode)) " -ForegroundColor Red }
    }
}

if (Test-Path $PSCommandPath) { Remove-Item $PSCommandPath -Force }
