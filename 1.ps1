Write-Host "=== WINGET AUTO-INSTALLER ==="

Write-Host "Checking updates..."
$upg = winget upgrade --accept-source-agreements --source winget | Out-String

if ($upg -match "---") {
    Write-Host $upg
    if ((Read-Host "Update all? [y/n]") -eq 'y') { 
        winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --include-unknown --source winget
    }
} else {
    Write-Host "System is up to date."
}

$apps = @("7zip.7zip","Google.Chrome.EXE","Yandex.Browser","RustDesk.RustDesk","AnyDesk.AnyDesk","QL-Win.QuickLook","PDFgear.PDFgear","VideoLAN.VLC","AdrienAllard.FileConverter")

$inst = winget list --accept-source-agreements --source winget | Out-String
foreach ($a in $apps) {
    if ($inst -notlike "*$a*") {
        Write-Host "Installing $a..." -NoNewline
        $p = Start-Process winget -Args "install --id $a -e --silent --accept-source-agreements --accept-package-agreements --force --source winget" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -eq 0) { Write-Host " [OK]" } else { Write-Host " [FAIL]" }
    }
}

Write-Host "Done"; Start-Sleep 3
