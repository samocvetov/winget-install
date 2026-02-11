if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs;exit}

Clear-Host;Write-Host "=== WINGET AUTO-INSTALLER ==="

winget source update --accept-source-agreements|Out-Null
winget list --accept-source-agreements --accept-package-agreements|Out-Null
winget upgrade --all --silent --include-unknown --accept-source-agreements --accept-package-agreements

$apps="7zip.7zip","Google.Chrome","Yandex.Browser","Microsoft.VisualStudioCode","DominikReichl.KeePass","Notepad++.Notepad++","Telegram.TelegramDesktop","9NKSQGP7F2NH","Yandex.Messenger","Zoom.Zoom","RustDesk.RustDesk","AnyDesk.AnyDesk","WireGuard.WireGuard","Termius.Termius","Mikrotik.Winbox","angryziber.AngryIPScanner","alexx2000.DoubleCommander","QL-Win.QuickLook","PDFgear.PDFgear","VideoLAN.VLC","AdrienAllard.FileConverter","XPDDT99J9GKB5C","WinDirStat.WinDirStat","Piriform.Recuva","ventoy.ventoy"
$f=@{"9NKSQGP7F2NH"="WhatsApp";"XPDDT99J9GKB5C"="Samsung Magician"}

foreach($a in $apps){
$name=if($f.ContainsKey($a)){$f[$a]}else{$a}
winget list --id $a -e --accept-source-agreements|Out-Null
if($LASTEXITCODE -eq 0){Write-Host "[skip] $name";continue}
if((Read-Host("Install $name? [y/n]"))-eq"y"){
Write-Host "Installing $name..." -NoNewline
$p=Start-Process winget -ArgumentList "install --id $a -e --silent --force --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
if($p.ExitCode -eq 0){Write-Host " [ok]"}else{Write-Host " [fail]"}}}

Write-Host "Done";Start-Sleep 3
