
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " Azure Update Manager - Patch Source Verification" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# The KB IDs to verify (edit this list to match what you're checking)
$kbList = @(
    "KB890830",
    "KB4052623",
    "KB2267602",
    "KB5007651",
    "KB5100998",
    "KB5099536"
)

$logPath = "C:\ProgramData\GuestConfig\extension_logs\Microsoft.CPlat.Core.WindowsPatchExtension\WindowsUpdateExtension.log"

# --- 1. Confirm orchestration mode: Windows Update auto-install must be OFF ---
Write-Host "=== Step 1: Confirm Windows Update auto-install is disabled ===" -ForegroundColor Yellow
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$noAutoUpdate = (Get-ItemProperty -Path $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue).NoAutoUpdate

if ($noAutoUpdate -eq 1) {
    Write-Host "PASS: NoAutoUpdate = 1 (native Windows Update cannot self-install)" -ForegroundColor Green
} else {
    Write-Host "FAIL: NoAutoUpdate is NOT set to 1 (value: $noAutoUpdate). Windows Update may be installing patches independently." -ForegroundColor Red
}
Write-Host ""

# --- 2. Check each KB's install record ---
Write-Host "=== Step 2: Cross-check each KB's install record ===" -ForegroundColor Yellow
$hotfixes = Get-HotFix -ErrorAction SilentlyContinue

foreach ($kb in $kbList) {
    $match = $hotfixes | Where-Object { $_.HotFixID -eq $kb }

    if ($match) {
        $installedBy = if ($match.InstalledBy) { $match.InstalledBy } else { "(blank)" }
        Write-Host "$kb : Installed on $($match.InstalledOn) by $installedBy" -ForegroundColor Green

        if ($installedBy -eq "NT AUTHORITY\SYSTEM") {
            Write-Host "    -> InstalledBy = SYSTEM, consistent with platform-driven install (Update Manager)" -ForegroundColor DarkGreen
        } elseif ($installedBy -eq "(blank)") {
            Write-Host "    -> InstalledBy is blank. Common for older/legacy entries - not conclusive on its own, check log correlation below." -ForegroundColor DarkYellow
        } else {
            Write-Host "    -> InstalledBy is a named user account, NOT SYSTEM. Worth investigating - may indicate manual/interactive install." -ForegroundColor Red
        }
    } else {
        Write-Host "$kb : NOT FOUND in Get-HotFix output on this machine." -ForegroundColor Red
    }
}
Write-Host ""

# --- 3. Correlate with the Update Manager JSON event files ---
# Note: WindowsUpdateExtension.log only contains lifecycle/plumbing messages
# (event queue processing, file writes) - it never contains KB numbers.
# The actual per-patch detail lives in the JSON event files it writes out.
Write-Host "=== Step 3: Correlate KBs against Update Manager JSON event files ===" -ForegroundColor Yellow

$eventsFolder = "C:\ProgramData\GuestConfig\extension_logs\Microsoft.CPlat.Core.WindowsPatchExtension\eventsFolder"

if (Test-Path $eventsFolder) {
    $jsonFiles = Get-ChildItem -Path $eventsFolder -Filter "*.json" -ErrorAction SilentlyContinue

    if ($jsonFiles) {
        $allJsonText = $jsonFiles | ForEach-Object { Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue }

        foreach ($kb in $kbList) {
            $kbNumber = $kb -replace "KB", ""
            $found = $allJsonText | Select-String -Pattern $kbNumber

            if ($found) {
                Write-Host "$kb : Found in Update Manager event data" -ForegroundColor Green
            } else {
                Write-Host "$kb : Not found in current event files - they may have rotated/cleared since this job ran." -ForegroundColor DarkYellow
            }
        }
    } else {
        Write-Host "No JSON event files currently present in: $eventsFolder" -ForegroundColor DarkYellow
        Write-Host "These are often cleaned up after being uploaded to Azure - absence here doesn't mean the install failed." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "Events folder not found at: $eventsFolder" -ForegroundColor Red
}
Write-Host ""
Write-Host "Note: the most authoritative source for which KBs a specific job installed is the" -ForegroundColor DarkGray
Write-Host "extension status/history in the Azure Portal (Update Manager > Machine > History)," -ForegroundColor DarkGray
Write-Host "since that reflects what was actually reported back to Azure, independent of local log retention." -ForegroundColor DarkGray
Write-Host ""

# --- 4. Pending reboot check (relevant since two of your KBs require reboot = True) ---
Write-Host "=== Step 4: Pending reboot check ===" -ForegroundColor Yellow
$rebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

if ($rebootPending) {
    Write-Host "Reboot is PENDING. Some installed patches (e.g. KB5100998, KB5099536) will not be fully active until reboot." -ForegroundColor Yellow
} else {
    Write-Host "No reboot pending. All installed patches should be fully active." -ForegroundColor Green
}
Write-Host ""

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " Verification complete." -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
