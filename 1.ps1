# Проверка на права администратора (авто-перезапуск)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

$Ver="1.0"; Clear-Host
Write-Host "=== WINGET AUTO-INSTALLER v$Ver ===" -F Cyan
# Список программ (Winbox, AngryIP, Ventoy — УБРАНЫ)
$apps = @(
    "7zip.7zip", 
    "Google.Chrome", 
    "Yandex.Browser", 
    "RustDesk.RustDesk", 
    "AnyDesk.AnyDesk", 
    "QL-Win.QuickLook", 
    "PDFgear.PDFgear", 
    "VideoLAN.VLC", 
    "AdrienAllard.FileConverter"
)

# --- 1. УСТАНОВКА ---
Write-Host "--- Checking Installed Apps ---" -F Cyan
# Получаем список установленного один раз, чтобы не дергать winget постоянно
$inst = winget list --accept-source-agreements | Out-String

foreach ($app in $apps) {
    # Простая проверка: если ID есть в списке установленного — пропускаем
    if ($inst -like "*$app*") { 
        Write-Host "[skip] $app" -F Gray
        continue 
    }

    Write-Host "Installing $app..." -NoNewline
    # -e (exact) используем для точности, --silent для тишины
    $p = Start-Process winget -Args "install --id $app -e --silent --accept-source-agreements --accept-package-agreements --force" -NoNewWindow -Wait -PassThru
    
    if ($p.ExitCode -eq 0) { 
        Write-Host "`r[OK] $app           " -F Green
    } else { 
        Write-Host "`r[FAIL] $app ($($p.ExitCode))" -F Red 
    }
}

# --- 2. ОБНОВЛЕНИЕ ---
Write-Host "`n--- Checking Updates ---" -F Cyan
# Показываем список того, что требует обновления
winget upgrade --accept-source-agreements

Write-Host ""
$ans = Read-Host "Update ALL packages? [y/n]"

if ($ans -eq 'y') {
    Write-Host "Updating everything..." -F Yellow
    # --include-unknown позволяет обновлять даже то, что не было установлено через winget, но есть в репозитории
    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --include-unknown
    Write-Host "All updates finished." -F Green
} else {
    Write-Host "Updates skipped." -F Gray
}

Write-Host "`nDone!" -F Cyan; Start-Sleep 3
