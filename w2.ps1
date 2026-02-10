# --- НАСТРОЙКИ СКРИПТА ---
$ScriptVersion = "6.2.11"

# Очищаем экран и выводим заголовок
Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "    WINGET AUTO-INSTALLER  |  v$ScriptVersion    " -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$appsToInstall = @(
    "7zip.7zip", "Notepad++.Notepad++", "RustDesk.RustDesk", "AnyDesk.AnyDesk", "VideoLAN.VLC", 
    "PDFgear.PDFgear", "Google.Chrome", "Telegram.TelegramDesktop", "Zoom.Zoom",
    "Yandex.Browser", "Yandex.Messenger", "AdrienAllard.FileConverter", "alexx2000.DoubleCommander",
    "WinDirStat.WinDirStat", "Piriform.Recuva", "DominikReichl.KeePass",
    "ventoy.ventoy", "Termius.Termius", "WireGuard.WireGuard", "Mikrotik.Winbox",
    "REALiX.HWiNFO", "CPUID.CPU-Z", "TechPowerUp.GPU-Z", "angryziber.AngryIPScanner",
    "9NKSQGP7F2NH", "9NV4BS3L1H4S", "XPDDT99J9GKB5C"
)

$friendlyNames = @{
    "9NKSQGP7F2NH" = "WhatsApp"
    "9NV4BS3L1H4S" = "QuickLook"
    "XPDDT99J9GKB5C" = "Samsung Magician"
}

# --- ФУНКЦИЯ СОЗДАНИЯ ЯРЛЫКОВ С РЕЗОЛВИНГОМ СИМЛИНКОВ ---
function Add-WingetShortcut {
    param (
        [string]$AppId
    )
    
    $StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    $WingetLinksPath = "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
    
    if ($AppId -match "\.") {
        $searchName = $AppId.Split('.')[-1]
    } else {
        return 
    }
    
    # Ищем файл в папке Links
    $linkFile = Get-ChildItem -Path $WingetLinksPath -Filter "*$searchName*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($linkFile) {
        $shortcutName = $linkFile.BaseName 
        $shortcutPath = "$StartMenuPath\$shortcutName.lnk"

        # --- МАГИЯ: НАХОДИМ НАСТОЯЩИЙ ПУТЬ ---
        # Winget создает симлинки. Нам нужно узнать, где лежит РЕАЛЬНЫЙ exe, чтобы взять иконку.
        $realPath = $linkFile.FullName
        
        try {
            # Проверяем, является ли файл симлинком
            if ($linkFile.LinkType -eq 'SymbolicLink') {
                # Получаем цель ссылки
                $target = $linkFile.Target
                
                # Если путь относительный, превращаем в абсолютный
                if (-not [System.IO.Path]::IsPathRooted($target)) {
                    $target = Join-Path $linkFile.DirectoryName $target
                }
                # Нормализуем путь (убираем .. и прочее)
                $realPath = (Get-Item $target).FullName
            }
        } catch {
            # Если не вышло разрешить ссылку, оставляем как есть
            Write-Host "   [!] Could not resolve symlink, using default path" -ForegroundColor DarkGray
        }

        # Удаляем старый ярлык
        if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }

        try {
            $WScript = New-Object -ComObject WScript.Shell
            $Shortcut = $WScript.CreateShortcut($shortcutPath)
            
            # Цель ярлыка - указываем на ссылку (чтобы обновления winget работали корректно)
            $Shortcut.TargetPath = $linkFile.FullName
            $Shortcut.WorkingDirectory = $linkFile.DirectoryName
            
            # А вот иконку берем жестко из НАСТОЯЩЕГО файла
            $Shortcut.IconLocation = "$realPath,0"
            
            $Shortcut.Save()
            Write-Host "   [+] Shortcut created with fixed icon: $shortcutName" -ForegroundColor DarkGray
        } catch {
            Write-Host "   [!] Failed to create shortcut" -ForegroundColor DarkGray
        }
    }
}
# --------------------------------

Write-Host "--- Checking for available updates ---" -ForegroundColor Cyan
# Получаем сырой вывод и фильтруем его
$updateRaw = winget upgrade --accept-source-agreements
$lines = $updateRaw | Select-String -Pattern '^\S+' | Select-Object -Skip 2

$foundUpdates = $false
foreach ($line in $lines) {
    $columns = $line.ToString() -split '\s{2,}'
    if ($columns.Count -ge 2) {
        $name = $columns[0].Trim()
        $id = $columns[1].Trim()

        if ($id -and $id -ne "ID" -and $id -ne "Name" -and $id -notlike "---*") {
            $foundUpdates = $true
            if ($id -match "\s") { $id = ($id -split "\s")[0] }

            $confirmUpdate = Read-Host "Update available for $name ($id). Apply? [y/n]"
            if ($confirmUpdate -eq 'y') {
                Write-Host "Updating $id..." -ForegroundColor Yellow
                winget upgrade --id "$id" --silent --force --accept-source-agreements --accept-package-agreements
            }
        }
    }
}

if (-not $foundUpdates) {
    Write-Host "No updates required." -ForegroundColor Green
}

Write-Host "`n--- Installing new packages ---" -ForegroundColor Cyan
$installedList = winget list --accept-source-agreements | Out-String

foreach ($app in $appsToInstall) {
    # Даже если приложение уже стоит, пробуем обновить ярлык (чтобы починить иконку)
    $alreadyInstalled = $installedList -like "*$app*"
    
    if ($alreadyInstalled) {
        Write-Host "[SKIP] $app (Already installed, checking shortcut...)" -ForegroundColor Gray
        Add-WingetShortcut -AppId $app
        continue
    }

    $displayName = if ($friendlyNames.ContainsKey($app)) { $friendlyNames[$app] } else { $app }
    $prompt = "Install " + $displayName + "? [y/n]"
    $confirmation = Read-Host $prompt
    
    if ($confirmation -eq 'y') {
        Write-Host "Processing $displayName..." -NoNewline -ForegroundColor White
        $process = Start-Process winget -ArgumentList "install --id $app --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Host "`r[ OK ] $displayName                       " -ForegroundColor Green
            Add-WingetShortcut -AppId $app
        } else {
            Write-Host "`r[FAIL] $displayName (Error: $($process.ExitCode))" -ForegroundColor Red
        }
    }
}

Write-Host "`nDone!" -ForegroundColor Cyan
Start-Sleep -Seconds 3
