# wginst - OOBE automation
# Repo: https://github.com/samocvetov/wginst
# File: oo.ps1
# Purpose: Safe OOBE automation

Start-Transcript -Path "$env:TEMP\oobe_automation.log" -Force

# --- Проверка, что мы в OOBE ---
$TypeDef = @"
using System;
using System.Runtime.InteropServices;

namespace Api {
    public class Kernel32 {
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int OOBEComplete(ref bool bIsOOBEComplete);
    }
}
"@

try {
    Add-Type -TypeDefinition $TypeDef -Language CSharp -ErrorAction Stop
} catch {
    Write-Error "Не удалось добавить тип для проверки OOBE: $_"
    Stop-Transcript
    exit 1
}

$IsOOBEComplete = $false
[Api.Kernel32]::OOBEComplete([ref] $IsOOBEComplete) | Out-Null

if ($IsOOBEComplete) {
    Write-Host "OOBE уже завершён, выходим."
    Stop-Transcript
    exit 0
}

# --- Генерация безопасного пароля ---
Add-Type -AssemblyName System.Web
$PasswordPlain = [System.Web.Security.Membership]::GeneratePassword(16,3)
$Username = "LocalAdmin"

Write-Host "Будет создан локальный администратор: $Username" -ForegroundColor Green
Write-Host "Сохраните пароль: $PasswordPlain" -ForegroundColor Yellow

# --- Формирование unattend.xml ---
$AnswerFile = "$env:TEMP\UnattendOOBE.xml"

$UnattendXml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>$Username</Name>
                        <Group>Administrators</Group>
                        <Password>
                            <Value>$PasswordPlain</Value>
                            <PlainText>true</PlainText>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
        </component>
    </settings>
</unattend>
"@

try {
    $UnattendXml | Out-File -FilePath $AnswerFile -Encoding utf8 -Force
} catch {
    Write-Error "Не удалось записать unattend.xml: $_"
    Stop-Transcript
    exit 1
}

# --- Запуск Sysprep ---
$SysprepPath = "$env:SystemRoot\System32\Sysprep\sysprep.exe"

if (-not (Test-Path $SysprepPath)) {
    Write-Error "Sysprep не найден по пути: $SysprepPath"
    Stop-Transcript
    exit 1
}

Write-Host "Запуск Sysprep с unattend.xml..." -ForegroundColor Cyan

try {
    Start-Process -FilePath $SysprepPath -ArgumentList "/reboot /oobe /unattend:$AnswerFile" -Wait
} catch {
    Write-Error "Ошибка запуска Sysprep: $_"
    Stop-Transcript
    exit 1
}

Stop-Transcript
