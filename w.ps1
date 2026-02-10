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

Write-Host "`n--- Checking for updates ---" -ForegroundColor Cyan
$updates = winget upgrade | Select-String -Pattern '^\S+' | Select-Object -Skip 2

foreach ($line in $updates) {
    $fields = $line.ToString() -split '\s{2,}'
    if ($fields.Count -gt 1) {
        $name = $fields[0].Trim()
        $id = $fields[1].Trim()
        if ($id -and $id -ne "ID") {
            $confirmUpdate = Read-Host "Update $name ($id)? [y/n]"
            if ($confirmUpdate -eq 'y') {
                Write-Host "Updating $id..." -ForegroundColor Yellow
                winget upgrade --id $id --silent --accept-source-agreements --accept-package-agreements
            }
        }
    }
}

Write-Host "`n--- Installing packages ---" -ForegroundColor Cyan
foreach ($app in $appsToInstall) {
    $confirmation = Read-Host "Install $app? [y/n]"
    if ($confirmation -eq 'y') {
        Write-Host "Installing $app..." -NoNewline -ForegroundColor White
        $process = Start-Process winget -ArgumentList "install --id $app --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Host "`r[ OK ] $app                          " -ForegroundColor Green
        } elseif ($process.ExitCode -eq -1978335189) {
            Write-Host "`r[SKIP] $app (Already installed)      " -ForegroundColor Gray
        } else {
            Write-Host "`r[FAIL] $app (Error: $($process.ExitCode))" -ForegroundColor Red
        }
    }
}

Write-Host "`nDone!" -ForegroundColor Cyan
if (Test-Path $PSCommandPath) { Remove-Item $PSCommandPath -Force }
