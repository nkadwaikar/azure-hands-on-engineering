# ================================
# Azure‑Only Patching Mode
# Disable Windows Update Automatic Installation
# ================================

Write-Host "Configuring Azure-only patching mode..." -ForegroundColor Cyan

# 1. Disable Automatic Updates (NoAutoUpdate = 1)
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f

# 2. Set AUOptions = 2 (Notify for download + notify for install)
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f

# 3. Disable Automatic Maintenance (prevents silent 2 AM installs)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /t REG_DWORD /d 1 /f

# 4. Force Windows Update UX to "Notify" mode
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v UxOption /t REG_DWORD /d 1 /f

# 5. Ensure Windows Update service is running (Azure Update Manager needs it)
Set-Service -Name wuauserv -StartupType Automatic
Start-Service -Name wuauserv

# 6. Restart Azure Arc agent + extension host (best practice)
Restart-Service himds -ErrorAction SilentlyContinue
Restart-Service ExtensionService -ErrorAction SilentlyContinue
Restart-Service GCArcService -ErrorAction SilentlyContinue

Write-Host "Azure-only patching mode configured successfully." -ForegroundColor Green
Write-Host "Windows Update will no longer install patches automatically." -ForegroundColor Yellow
Write-Host "Azure Update Manager will now install ALL patches during your daily schedule." -ForegroundColor Yellow
