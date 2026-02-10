$apps = @("7zip.7zip","Notepad++.Notepad++","RustDesk.RustDesk","AnyDesk.AnyDesk","VideoLAN.VLC","PDFgear.PDFgear","Google.Chrome","Telegram.TelegramDesktop","Zoom.Zoom","Yandex.Browser","Yandex.Messenger","AdrienAllard.FileConverter","alexx2000.DoubleCommander","WinDirStat.WinDirStat","Piriform.Recuva","PowerSoftware.AnyBurn","qBittorrent.qBittorrent","9NKSQGP7F2NH","XPDDT99J9GKB5C","Paddington.QuickLook","DominikReichl.KeePass","ventoy.ventoy","Termius.Termius","TimKosse.FileZilla.Client","WireGuard.WireGuard","REALiX.HWiNFO","CPUID.CPU-Z","TechPowerUp.GPU-Z","angryziber.AngryIPScanner")
$friendlyNames = @{"9NKSQGP7F2NH"="WhatsApp";"XPDDT99J9GKB5C"="Netflix"}

Write-Host "`n--- Checking for available updates ---" -F Cyan
$updateRaw = winget upgrade --accept-source-agreements
$lines = $updateRaw | Select-String -Pattern '^\S+' | Select-Object -Skip 2
$foundUpdates = $false

foreach ($line in $lines) {
    $columns = $line.ToString() -split '\s{2,}'
    if ($columns.Count -ge 2) {
        $name = $columns[0].Trim(); $id = $columns[1].Trim()
        if ($id -and $id -ne "ID" -and $id -notlike "---*") {
            $foundUpdates = $true
            if ($id -match "\s") { $id = ($id -split "\s")[0] }
            if ((Read-Host "Update available for $name ($id). Apply? [y/n]") -eq 'y') {
                Write-Host "Updating $id..." -F Yellow
                winget upgrade --id "$id" --silent --force --accept-source-agreements --accept-package-agreements
            }
        }
    }
}
if (!$foundUpdates) { Write-Host "No updates required." -F Green }

Write-Host "`n--- Installing new packages ---" -F Cyan
$installedList = (winget list --accept-source-agreements | Out-String)

foreach ($app in $apps) {
    if ($installedList -like "*$app*") {
        Write-Host "[SKIP] $app (Already installed)" -F Gray
        continue
    }
    $displayName = if ($friendlyNames.ContainsKey($app)) { $friendlyNames[$app] } else { $app }
    
    # Прямая проверка на пустую строку
    if ([string]::IsNullOrWhiteSpace($displayName)) { $displayName = $app }

    $confirmation = Read-Host "Install $displayName? [y/n]"
    if ($confirmation -eq 'y') {
        Write-Host "Processing $displayName..." -NoNewline -F White
        $process = Start-Process winget -ArgumentList "install --id $app --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Host "`r[ OK ] $displayName                          " -F Green
        } else {
            Write-Host "`r[FAIL] $displayName (Error: $($process.ExitCode))" -F Red
        }
    }
}

Write-Host "`nDone!" -F Cyan
if (Test-Path $PSCommandPath) { Remove-Item $PSCommandPath -Force }
