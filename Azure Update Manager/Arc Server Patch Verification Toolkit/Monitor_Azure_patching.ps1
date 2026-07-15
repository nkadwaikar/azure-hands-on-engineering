
Write-Host "Azure Update Manager - Real-Time Patching Monitor" -ForegroundColor Cyan
Write-Host "Watching GCArcService state and new extension log activity (Ctrl+C to stop)..." -ForegroundColor Yellow
Write-Host ""

$logPath = "C:\ProgramData\GuestConfig\extension_logs\Microsoft.CPlat.Core.WindowsPatchExtension\WindowsUpdateExtension.log"

# --- State tracking so we only report CHANGES, not the same steady-state facts every loop ---
$lastServiceStatus  = $null
$lastLineCount      = 0
$lastRebootState    = $null
$seenCompletedSinceStart = $false

# Prime the line counter so we only react to NEW lines written after the monitor starts,
# not the entire historical log (otherwise "Completed" from a job an hour ago fires immediately).
if (Test-Path $logPath) {
    $lastLineCount = (Get-Content $logPath -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    Write-Host "Log found. Starting from line $lastLineCount (ignoring prior history)." -ForegroundColor DarkGray
} else {
    Write-Host "Log not found yet at: $logPath" -ForegroundColor DarkGray
}
Write-Host ""

while ($true) {

    # 1. GCArcService - only print when status CHANGES
    $gcArc = Get-Service GCArcService -ErrorAction SilentlyContinue
    $currentServiceStatus = if ($gcArc) { $gcArc.Status.ToString() } else { "NotFound" }

    if ($currentServiceStatus -ne $lastServiceStatus) {
        if ($currentServiceStatus -eq "Running") {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] GCArcService is now Running - extension host active." -ForegroundColor Green
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] GCArcService state changed to: $currentServiceStatus" -ForegroundColor Red
        }
        $lastServiceStatus = $currentServiceStatus
    }

    # 2. Extension log - only report genuinely NEW lines since the monitor started/last loop
    if (Test-Path $logPath) {
        $allLines = Get-Content $logPath -ErrorAction SilentlyContinue
        $currentLineCount = ($allLines | Measure-Object -Line).Lines

        if ($currentLineCount -gt $lastLineCount) {
            $newLines = $allLines[$lastLineCount..($currentLineCount - 1)]

            foreach ($line in $newLines) {
                if ($line -match "Completed" -or $line -match "Succeeded") {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Patching completed: $line" -ForegroundColor Cyan
                    $seenCompletedSinceStart = $true
                }
                elseif ($line -match "Fail" -or $line -match "Error") {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Patching issue detected: $line" -ForegroundColor Red
                }
                elseif ($line -match "Patching" -or $line -match "Install") {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Activity: $line" -ForegroundColor Green
                }
            }

            $lastLineCount = $currentLineCount
        }
    }

    # 3. Reboot pending - only print when the state CHANGES
    $rebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

    if ($rebootPending -ne $lastRebootState) {
        if ($rebootPending) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Reboot is now PENDING - Update Manager will reboot during its window." -ForegroundColor Yellow
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Reboot pending flag cleared." -ForegroundColor DarkGray
        }
        $lastRebootState = $rebootPending
    }

    Start-Sleep -Seconds 5
}
