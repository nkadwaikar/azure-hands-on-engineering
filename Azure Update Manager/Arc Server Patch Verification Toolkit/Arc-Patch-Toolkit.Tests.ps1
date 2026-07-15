#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

<#
.SYNOPSIS
    Pester v5 unit tests for the Arc Server Patch Verification Toolkit scripts.

.DESCRIPTION
    Covers Azure_Only_Patching_Mode.ps1 and Verifying_Azure-only_patching_mode.ps1.
    All tests mock external commands and cmdlets so no registry writes or service
    changes occur — safe to run on any machine without Administrator privileges.

.NOTES
    Run with:  Invoke-Pester ./Arc-Patch-Toolkit.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $modeScript   = Join-Path $PSScriptRoot 'Azure_Only_Patching_Mode.ps1'
    $verifyScript = Join-Path $PSScriptRoot 'Verifying_Azure-only_patching_mode.ps1'

    # Guard — fail fast if the scripts under test are missing
    foreach ($script in $modeScript, $verifyScript) {
        if (-not (Test-Path $script)) {
            throw "Script not found: $script"
        }
    }
}

# ---------------------------------------------------------------------------
# Azure_Only_Patching_Mode.ps1
# ---------------------------------------------------------------------------
Describe 'Azure_Only_Patching_Mode.ps1' {

    Context 'when executed — applies all enforcement settings' {
        BeforeAll {
            # Mock external reg.exe and service cmdlets before dot-sourcing.
            # The mock intercepts every call to 'reg' regardless of arguments.
            Mock reg            { }
            Mock Set-Service    { }
            Mock Start-Service  { }
            Mock Restart-Service { }
            Mock Write-Host     { }

            . $modeScript
        }

        It 'sets NoAutoUpdate = 1 to block automatic update installs' {
            Should -Invoke reg -ParameterFilter {
                ($args -join ' ') -match 'NoAutoUpdate' -and ($args -join ' ') -match '/d 1'
            }
        }

        It 'sets AUOptions = 2 (notify-only — no silent installs)' {
            Should -Invoke reg -ParameterFilter {
                ($args -join ' ') -match 'AUOptions' -and ($args -join ' ') -match '/d 2'
            }
        }

        It 'disables Automatic Maintenance to stop the silent 2 AM WU install path' {
            Should -Invoke reg -ParameterFilter {
                ($args -join ' ') -match 'MaintenanceDisabled'
            }
        }

        It 'sets Windows Update UX to notify mode' {
            Should -Invoke reg -ParameterFilter {
                ($args -join ' ') -match 'UxOption'
            }
        }

        It 'configures wuauserv for Automatic start (Update Manager needs the service running)' {
            Should -Invoke Set-Service -ParameterFilter {
                $Name -eq 'wuauserv' -and $StartupType -eq 'Automatic'
            }
        }

        It 'starts wuauserv so the service is available immediately' {
            Should -Invoke Start-Service -ParameterFilter { $Name -eq 'wuauserv' }
        }

        It 'restarts the himds Arc agent service' {
            Should -Invoke Restart-Service -ParameterFilter { $Name -eq 'himds' }
        }

        It 'restarts the ExtensionService' {
            Should -Invoke Restart-Service -ParameterFilter { $Name -eq 'ExtensionService' }
        }

        It 'restarts the GCArcService' {
            Should -Invoke Restart-Service -ParameterFilter { $Name -eq 'GCArcService' }
        }

        It 'writes a success confirmation to the host' {
            Should -Invoke Write-Host -ParameterFilter {
                $Object -like '*configured successfully*'
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Verifying_Azure-only_patching_mode.ps1
# ---------------------------------------------------------------------------
Describe 'Verifying_Azure-only_patching_mode.ps1' {

    Context 'all settings correctly applied — expects all PASS' {
        BeforeAll {
            # Registry mocks — return correctly configured values
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*WindowsUpdate\AU' } {
                [PSCustomObject]@{ NoAutoUpdate = 1; AUOptions = 2 }
            }
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*Schedule\Maintenance' } {
                [PSCustomObject]@{ MaintenanceDisabled = 1 }
            }
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*WindowsUpdate\UX*' } {
                [PSCustomObject]@{ UxOption = 1 }
            }

            # Service mocks — all services running and correctly configured
            Mock Get-Service -ParameterFilter { $Name -eq 'wuauserv' } {
                [PSCustomObject]@{ Status = 'Running'; StartType = 'Automatic'; Name = 'wuauserv' }
            }
            Mock Get-Service -ParameterFilter { $Name -in 'himds', 'GCArcService', 'ExtensionService' } {
                [PSCustomObject]@{ Status = 'Running'; Name = $Name }
            }

            Mock Write-Host { }
            . $verifyScript
        }

        It 'reports PASS for NoAutoUpdate' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*NoAutoUpdate*' }
        }

        It 'reports PASS for AUOptions' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*AUOptions*' }
        }

        It 'reports PASS for MaintenanceDisabled' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*MaintenanceDisabled*' }
        }

        It 'reports PASS for wuauserv running' {
            Should -Invoke Write-Host -ParameterFilter {
                $Object -like '*PASS*Windows Update service is running*'
            }
        }

        It 'reports PASS for wuauserv Automatic start' {
            Should -Invoke Write-Host -ParameterFilter {
                $Object -like '*PASS*Windows Update service startup*Automatic*'
            }
        }

        It 'reports PASS for himds agent running' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*himds*' }
        }

        It 'reports PASS for GCArcService running' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*GCArcService*' }
        }

        It 'reports PASS for ExtensionService running' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*ExtensionService*' }
        }

        It 'does not produce any FAIL results' {
            Should -Not -Invoke Write-Host -ParameterFilter { $Object -like 'FAIL*' }
        }
    }

    Context 'Windows Update policy registry keys absent — expects FAIL on policy checks' {
        BeforeAll {
            # Registry throws — simulates keys not present (policy never applied)
            Mock Get-ItemProperty {
                throw [System.Management.Automation.ItemNotFoundException]::new(
                    'Cannot find path because it does not exist.'
                )
            }
            Mock Get-Service {
                [PSCustomObject]@{ Status = 'Running'; StartType = 'Automatic'; Name = $Name }
            }
            Mock Write-Host { }

            . $verifyScript
        }

        It 'reports FAIL for NoAutoUpdate' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*FAIL*NoAutoUpdate*' }
        }

        It 'reports FAIL for AUOptions' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*FAIL*AUOptions*' }
        }

        It 'reports FAIL for MaintenanceDisabled' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*FAIL*MaintenanceDisabled*' }
        }

        It 'still reports PASS for running services' {
            Should -Invoke Write-Host -ParameterFilter {
                $Object -like '*PASS*Windows Update service is running*'
            }
        }
    }

    Context 'Arc agent services stopped — expects FAIL on service checks' {
        BeforeAll {
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*WindowsUpdate\AU' } {
                [PSCustomObject]@{ NoAutoUpdate = 1; AUOptions = 2 }
            }
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*Schedule\Maintenance' } {
                [PSCustomObject]@{ MaintenanceDisabled = 1 }
            }
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*WindowsUpdate\UX*' } {
                [PSCustomObject]@{ UxOption = 1 }
            }
            Mock Get-Service -ParameterFilter { $Name -eq 'wuauserv' } {
                [PSCustomObject]@{ Status = 'Running'; StartType = 'Automatic'; Name = 'wuauserv' }
            }
            # Arc services are stopped
            Mock Get-Service -ParameterFilter { $Name -in 'himds', 'GCArcService', 'ExtensionService' } {
                [PSCustomObject]@{ Status = 'Stopped'; Name = $Name }
            }
            Mock Write-Host { }

            . $verifyScript
        }

        It 'reports FAIL for himds stopped' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*FAIL*himds*' }
        }

        It 'reports FAIL for GCArcService stopped' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*FAIL*GCArcService*' }
        }

        It 'reports FAIL for ExtensionService stopped' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*FAIL*ExtensionService*' }
        }

        It 'still reports PASS for all registry policy checks' {
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*NoAutoUpdate*' }
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*AUOptions*' }
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*PASS*MaintenanceDisabled*' }
        }
    }

    Context 'wrong registry values set — expects FAIL for incorrect values' {
        BeforeAll {
            # NoAutoUpdate = 0 (auto-updates enabled — wrong setting)
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*WindowsUpdate\AU' } {
                [PSCustomObject]@{ NoAutoUpdate = 0; AUOptions = 4 }
            }
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*Schedule\Maintenance' } {
                [PSCustomObject]@{ MaintenanceDisabled = 0 }
            }
            Mock Get-ItemProperty -ParameterFilter { $Path -like '*WindowsUpdate\UX*' } {
                [PSCustomObject]@{ UxOption = 4 }
            }
            Mock Get-Service {
                [PSCustomObject]@{ Status = 'Running'; StartType = 'Automatic'; Name = $Name }
            }
            Mock Write-Host { }

            . $verifyScript
        }

        It 'reports FAIL when NoAutoUpdate is 0 instead of 1' {
            Should -Invoke Write-Host -ParameterFilter {
                $Object -like '*FAIL*NoAutoUpdate*' -and $Object -like '*expected 1*'
            }
        }

        It 'reports FAIL when AUOptions is not 2' {
            Should -Invoke Write-Host -ParameterFilter {
                $Object -like '*FAIL*AUOptions*' -and $Object -like '*expected 2*'
            }
        }
    }
}
