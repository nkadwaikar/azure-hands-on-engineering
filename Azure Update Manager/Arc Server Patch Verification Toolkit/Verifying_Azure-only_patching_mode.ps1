Write-Host "Verifying Azure-only patching mode..." -ForegroundColor Cyan

function Check-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Expected
    )

    try {
        $value = (Get-ItemProperty -Path $Path -ErrorAction Stop).$Name
        if ($value -eq $Expected) {
            Write-Host "PASS: $Name = $Expected" -ForegroundColor Green
        } else {
            Write-Host "FAIL: $Name = $value (expected $Expected)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "FAIL: $Name not found at $Path" -ForegroundColor Red
    }
}

Write-Host "`n=== Windows Update Policy Checks ==="

# 1. NoAutoUpdate = 1
Check-RegistryValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Expected 1

# 2. AUOptions = 2 (Notify for download + notify for install)
Check-RegistryValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Expected 2

Write-Host "`n=== Automatic Maintenance Check ==="

# 3. MaintenanceDisabled = 1
Check-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "MaintenanceDisabled" -Expected 1

Write-Host "`n=== Windows Update UX Mode Check ==="

# 4. UxOption = 1 (Notify mode)
Check-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Expected 1

Write-Host "`n=== Windows Update Service Check ==="

$wusvc = Get-Service wuauserv -ErrorAction SilentlyContinue
if ($wusvc -and $wusvc.Status -eq "Running") {
    Write-Host "PASS: Windows Update service is running" -ForegroundColor Green
} else {
    Write-Host "FAIL: Windows Update service is not running or not found" -ForegroundColor Red
}

if ($wusvc -and $wusvc.StartType -eq "Automatic") {
    Write-Host "PASS: Windows Update service startup = Automatic" -ForegroundColor Green
} else {
    Write-Host "FAIL: Windows Update service startup = $($wusvc.StartType) (expected Automatic)" -ForegroundColor Red
}

Write-Host "`n=== Azure Arc Agent Check ==="

$himds = Get-Service himds -ErrorAction SilentlyContinue
if ($himds -and $himds.Status -eq "Running") {
    Write-Host "PASS: himds agent is running" -ForegroundColor Green
} else {
    Write-Host "FAIL: himds agent is not running or not found" -ForegroundColor Red
}

$gcArc = Get-Service GCArcService -ErrorAction SilentlyContinue
if ($gcArc -and $gcArc.Status -eq "Running") {
    Write-Host "PASS: GCArcService (Guest Configuration Arc Service) is running" -ForegroundColor Green
} else {
    Write-Host "FAIL: GCArcService is not running or not found" -ForegroundColor Red
}

$extSvc = Get-Service ExtensionService -ErrorAction SilentlyContinue
if ($extSvc -and $extSvc.Status -eq "Running") {
    Write-Host "PASS: ExtensionService (Guest Configuration Extension Service) is running" -ForegroundColor Green
} else {
    Write-Host "FAIL: ExtensionService is not running or not found" -ForegroundColor Red
}

Write-Host "`nVerification complete." -ForegroundColor Cyan
Write-Host "If all PASS, Azure Update Manager is now the ONLY patching engine." -ForegroundColor Yellow
