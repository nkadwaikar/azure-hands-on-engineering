<#
.SYNOPSIS
    Removes the Identity-First lab resource group and all resources inside it.

.DESCRIPTION
    The Resource Lock deployed by main.bicep (locks.bicep — CanNotDelete) must be
    removed before the resource group can be deleted. This script handles both steps
    in the correct order so manual portal cleanup is not required.

    Run this script when you have finished the lab and want to avoid ongoing charges.

.PARAMETER ResourceGroupName
    Name of the resource group to delete. Defaults to 'rg-identity-lab'.

.PARAMETER Force
    Skip the confirmation prompt and delete immediately.

.EXAMPLE
    # Interactive — prompts before deleting
    .\teardown.ps1

.EXAMPLE
    # Non-interactive — use in automation or CI
    .\teardown.ps1 -ResourceGroupName rg-identity-lab -Force

.NOTES
    Requires: Azure CLI (az) authenticated with Contributor rights on the resource group.
    Run 'az login' and 'az account set --subscription <id>' before executing.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ResourceGroupName = 'rg-identity-lab',
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Verify the resource group exists
# ---------------------------------------------------------------------------
Write-Host "Checking resource group '$ResourceGroupName'..." -ForegroundColor Cyan

$rgExists = az group exists --name $ResourceGroupName | ConvertFrom-Json
if (-not $rgExists) {
    Write-Host "Resource group '$ResourceGroupName' does not exist — nothing to remove." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# 2. Confirm before deleting (unless -Force)
# ---------------------------------------------------------------------------
if (-not $Force) {
    $answer = Read-Host "This will permanently delete '$ResourceGroupName' and ALL resources inside it. Continue? [y/N]"
    if ($answer -notmatch '^[Yy]$') {
        Write-Host "Cancelled — no changes made." -ForegroundColor Yellow
        exit 0
    }
}

# ---------------------------------------------------------------------------
# 3. Remove the CanNotDelete resource lock (if present)
#    The lock is applied at resource group scope by locks.bicep.
# ---------------------------------------------------------------------------
Write-Host "Removing resource locks on '$ResourceGroupName'..." -ForegroundColor Cyan

$locks = az lock list --resource-group $ResourceGroupName --query "[].name" --output tsv 2>$null
if ($locks) {
    foreach ($lockName in $locks) {
        Write-Host "  Deleting lock: $lockName"
        az lock delete --name $lockName --resource-group $ResourceGroupName | Out-Null
    }
    Write-Host "  All locks removed." -ForegroundColor Green
} else {
    Write-Host "  No locks found." -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# 4. Delete the resource group (and everything inside it)
# ---------------------------------------------------------------------------
Write-Host "Deleting resource group '$ResourceGroupName'..." -ForegroundColor Cyan

az group delete --name $ResourceGroupName --yes --no-wait

Write-Host ""
Write-Host "Delete request submitted. Azure will remove the resource group in the background." -ForegroundColor Green
Write-Host "Track progress: az group show --name '$ResourceGroupName' --query properties.provisioningState"
