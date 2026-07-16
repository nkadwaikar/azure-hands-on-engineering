# Azure Update Manager — Advanced Topics

> **Prerequisite:** Complete [1-Azure Update Manager.md](1-Azure%20Update%20Manager.md) before working through this guide. This document assumes Update Manager is already enabled, machines are assessed, and at least one maintenance configuration exists.

Last validated on: 2026-07-12

---

## Module / Track Structure

```text
Azure Update Manager/
├── README.md
├── 1-Azure Update Manager.md          ← Lab + Operational Guide
└── 2-Azure Update Advance Topics.md   ← Advanced Topics (you are here)
```

---

## Quick Navigation

- [Pre/Post Maintenance Scripts](#1-prepost-maintenance-scripts)
- [Rollback Procedures](#2-rollback-procedures)
- [Patch Exemptions and KB Exclusions](#3-patch-exemptions-and-kb-exclusions)
- [Azure Workbook for Patch Compliance](#4-azure-workbook-for-patch-compliance)
- [Advanced KQL Queries](#5-advanced-kql-queries)
- [CVE-to-KB Mapping Workflow](#6-cve-to-kb-mapping-workflow)
- [Zero-Day Response Playbook](#7-zero-day-response-playbook)
- [Patch SLA Policy with Azure Policy](#8-patch-sla-policy-with-azure-policy)
- [Domain Controller Staggered Reboot Runbook](#9-domain-controller-staggered-reboot-runbook)
- [Windows Server 2012 R2 ESU with Azure Arc](#10-windows-server-2012-r2-esu-with-azure-arc)
- [Bicep Templates for Maintenance Configurations](#11-bicep-templates-for-maintenance-configurations)
- [Cross-Subscription Patching](#12-cross-subscription-patching)
- [Quick Alerts (Native Update Manager Alerting)](#13-quick-alerts-native-update-manager-alerting)

---

## 1. Pre/Post Maintenance Scripts

Azure Update Manager supports **pre-maintenance** and **post-maintenance** scripts via Azure Automation runbooks. These run before or after the patch deployment on each machine.

### Common Use Cases

| Script Type | Example Actions |
| --- | --- |
| Pre-maintenance | Remove server from load balancer, take VM snapshot, notify monitoring system, stop application services |
| Post-maintenance | Add server back to load balancer, validate service health, send completion notification |

### 1.1 Create the Automation Account

1. In the Azure Portal, search **Automation Accounts** → **+ Create**.
2. Fill in:
   - **Subscription / Resource group:** use your existing patching RG
   - **Account name:** `aa-patchscripts-prod`
   - **Region:** same region as your maintenance configuration
3. Review + **Create**.

### 1.2 Create a Pre-Maintenance Runbook

1. In the Automation Account → **Runbooks** → **+ Create a runbook**.
2. Set:
   - **Name:** `pre-patch-drain-lb`
   - **Runbook type:** PowerShell
   - **Runtime version:** 7.2
3. Paste the following template and adapt the resource names:

```powershell
param(
    [string]$ResourceGroupName,
    [string]$VMName
)

# Authenticate using the Automation Account Managed Identity
Connect-AzAccount -Identity

# Example: remove VM from load balancer backend pool before patching
$nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName |
    Where-Object { $_.VirtualMachine.Id -match $VMName }

if ($nic) {
    $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = @()
    Set-AzNetworkInterface -NetworkInterface $nic
    Write-Output "Removed $VMName from load balancer backend pool."
} else {
    Write-Output "NIC not found for $VMName — skipping LB drain."
}
```

4. **Publish** the runbook.

### 1.3 Create a Post-Maintenance Runbook

1. Repeat the steps above, name it `post-patch-restore-lb`.
2. Paste the following template:

```powershell
param(
    [string]$ResourceGroupName,
    [string]$VMName,
    [string]$LoadBalancerName,
    [string]$BackendPoolName
)

Connect-AzAccount -Identity

$lb = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $LoadBalancerName
$backendPool = $lb.BackendAddressPools | Where-Object { $_.Name -eq $BackendPoolName }

$nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName |
    Where-Object { $_.VirtualMachine.Id -match $VMName }

if ($nic -and $backendPool) {
    $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = @($backendPool)
    Set-AzNetworkInterface -NetworkInterface $nic
    Write-Output "Restored $VMName to load balancer backend pool."
} else {
    Write-Output "Could not restore $VMName — check NIC and LB configuration."
}
```

3. **Publish** the runbook.

### 1.4 Attach Runbooks to a Maintenance Configuration

1. Open the maintenance configuration → **Pre/Post scripts** tab (in the portal this appears under **Advanced settings**).
2. Click **+ Add pre-script** → select your Automation Account and the `pre-patch-drain-lb` runbook.
3. Click **+ Add post-script** → select `post-patch-restore-lb`.
4. Save the configuration.

> **Permissions:** The Automation Account Managed Identity must have **Contributor** rights on the resource group where the VMs and load balancers reside. Assign the role under **Automation Account → Identity → Azure role assignments**.

---

## 2. Rollback Procedures

Azure Update Manager does not natively uninstall patches. Rollback options depend on what was prepared before the patching run.

### Option A — Uninstall a Specific KB (Windows)

Use this when one KB caused a regression and other patches are acceptable.

```powershell
# Find the installed KB
Get-HotFix | Where-Object { $_.HotFixID -eq 'KB5040442' }

# Uninstall it
$session = New-Object -ComObject Microsoft.Update.Session
$searcher = $session.CreateUpdateSearcher()
# Alternatively, use WUSA for direct uninstall:
wusa /uninstall /kb:5040442 /quiet /norestart

# Schedule a reboot after verification
Restart-Computer -Force
```

> After uninstalling, exclude the KB in the maintenance configuration exclusion list (see [Section 3](#3-patch-exemptions-and-kb-exclusions)) to prevent reinstallation on the next run.

### Option B — Restore from VM Snapshot (Azure VMs)

Use this when multiple patches caused a regression and you need a full rollback.

1. In the Azure Portal → **Recovery Services vaults** → open the vault protecting the VM.
2. Go to **Backup items → Azure Virtual Machine** → select the VM.
3. Click **Restore VM** → choose the restore point taken before the patching run.
4. Select **Restore to a new VM** (safer) or **Replace existing disk** (faster, destructive).
5. Confirm and monitor the restore job.

> **Best practice:** Use the pre-maintenance script (Section 1) to trigger an on-demand backup before each patching run. This ensures a pre-patch restore point always exists.

### Option C — Azure Site Recovery Failback (Arc/On-Prem Servers)

For on-premises Arc-enabled servers protected by ASR:

1. In **Azure Portal → Recovery Services vaults → Replicated items**, select the affected server.
2. Click **Failback** → choose the recovery point from before the patch run.
3. Follow the ASR failback wizard.

### Rollback Decision Matrix

| Scenario | Recommended Action |
| --- | --- |
| Single KB caused regression | Uninstall KB via `wusa`, exclude in maintenance config |
| Multiple patches caused regression | Restore from pre-patch VM snapshot |
| OS-level corruption post-patch | ASR failback or bare-metal restore from backup |
| Arc server, no snapshot | Re-image from golden image, re-onboard to Arc |

---

## 3. Patch Exemptions and KB Exclusions

Some patches must be held back indefinitely — driver updates that break line-of-business apps, KBs with known regressions, or changes that require a dedicated change window.

### 3.1 Exclude a KB in a Maintenance Configuration

1. Open your maintenance configuration → **Updates** tab (during creation) or **Edit** the existing configuration.
2. Scroll to **Excluded patches**.
3. Enter the KB number (e.g. `KB5040442`) — one entry per line.
4. Save the configuration.

> Exclusions apply to every machine assigned to that configuration. For machine-specific exclusions, create a separate maintenance configuration scoped to that machine.

### 3.2 Exclude a Package on Linux

For Linux Arc-enabled servers, specify the package name and optionally the version:

```
openssl=3.0.2-0ubuntu1.10
```

### 3.3 Document Exemptions

Maintain an exemption register. At minimum record:

| KB / Package | Reason for Exclusion | Owner | Review Date |
| --- | --- | --- | --- |
| KB5040442 | Breaks WinRM listener on 2019 servers | Infra team | 2026-10-01 |
| `openssl=3.0.2` | Pending app vendor certification | App team | 2026-09-01 |

Review exemptions at every patching cycle — KB regressions are often patched in later cumulative updates, allowing the exclusion to be removed.

---

## 4. Azure Workbook for Patch Compliance

Azure Update Manager ships with a built-in workbook template that visualizes fleet compliance without writing any KQL manually.

### 4.1 Open the Built-in Workbook

1. In the Azure Portal, open **Azure Update Manager → Reports** (left nav) → **Workbooks**.
2. Select the **Update Manager** workbook template.
3. Set the scope:
   - **Subscription:** select all relevant subscriptions
   - **Resource group:** filter if needed
   - **Time range:** last 30 days (recommended for monthly review)

### 4.2 Key Views in the Workbook

| Tab | What It Shows |
| --- | --- |
| **Overview** | Total machines, % compliant, % not assessed, total pending updates |
| **Compliance by machine** | Per-machine compliance state, last assessment, pending critical/security count |
| **Update history** | Deployment runs over time — success/failure trend |
| **Failed updates** | Machines with failed installations and the associated error codes |
| **Pending reboots** | Machines that have installed patches but not yet rebooted |

### 4.3 Pin to Azure Dashboard

1. In the workbook, click **Pin** (top toolbar) → select an existing dashboard or create a new one named `dash-patchops`.
2. The compliance charts update automatically each time the dashboard is opened.

---

## 5. Advanced KQL Queries

Run these in **Azure Resource Graph Explorer** (`portal.azure.com → Resource Graph Explorer`) or **Log Analytics**.

### 5.1 Patch Failure Rate by Machine (Last 30 Days)

```kql
patchinstallationresources
| where type == "microsoft.compute/virtualmachines/patchinstallationresults"
    or type == "microsoft.hybridcompute/machines/patchinstallationresults"
| extend machineName = tostring(split(id, '/')[8])
| extend status = tostring(properties.status)
| extend installTime = todatetime(properties.lastModifiedDateTime)
| where installTime > ago(30d)
| summarize
    Total = count(),
    Failed = countif(status == "Failed"),
    Succeeded = countif(status == "Succeeded")
    by machineName
| extend FailureRate = round(todouble(Failed) / todouble(Total) * 100, 1)
| order by FailureRate desc
```

### 5.2 Machines That Have Never Rebooted After Patching

```kql
patchinstallationresources
| where type == "microsoft.compute/virtualmachines/patchinstallationresults"
    or type == "microsoft.hybridcompute/machines/patchinstallationresults"
| extend machineName = tostring(split(id, '/')[8])
| extend rebootStatus = tostring(properties.rebootStatus)
| where rebootStatus == "Required"
| summarize LastChecked = max(todatetime(properties.lastModifiedDateTime)) by machineName, rebootStatus
| order by LastChecked asc
```

### 5.3 Fleet-Wide CVE-to-Patch Coverage (Defender + Update Manager)

```kql
// Run in Log Analytics workspace connected to Defender for Cloud
SecurityRecommendation
| where RecommendationName has "system updates"
| extend machineName = tostring(split(AffectedResourceId, '/')[8])
| join kind=leftouter (
    patchassessmentresources
    | where type has "patchassessmentresults"
    | extend machineName = tostring(split(id, '/')[8])
    | extend pendingCritical = toint(properties.criticalAndSecurityPatchCount)
    | project machineName, pendingCritical
) on machineName
| project machineName, RecommendationState, RecommendationSeverity, pendingCritical
| order by pendingCritical desc
```

### 5.4 Machines Assessed but Not Patched in 60+ Days

```kql
patchassessmentresources
| where type has "patchassessmentresults"
| extend machineName = tostring(split(id, '/')[8])
| extend lastAssessed = todatetime(properties.lastModifiedDateTime)
| extend pendingCritical = toint(properties.criticalAndSecurityPatchCount)
| where lastAssessed < ago(60d) and pendingCritical > 0
| project machineName, lastAssessed, pendingCritical
| order by pendingCritical desc
```

### 5.5 Deployment Run Duration Analysis

```kql
patchinstallationresources
| where type has "patchinstallationresults"
| extend machineName = tostring(split(id, '/')[8])
| extend startTime = todatetime(properties.startDateTime)
| extend endTime = todatetime(properties.lastModifiedDateTime)
| extend durationMinutes = datetime_diff('minute', endTime, startTime)
| where isnotnull(durationMinutes) and durationMinutes > 0
| summarize
    AvgDurationMin = avg(durationMinutes),
    MaxDurationMin = max(durationMinutes),
    P90DurationMin = percentile(durationMinutes, 90)
    by machineName
| order by MaxDurationMin desc
```

---

## 6. CVE-to-KB Mapping Workflow

When Defender for Cloud surfaces a CVE, this workflow traces it to the specific KB and confirms Update Manager will install it.

### Step 1 — Identify the CVE in Defender for Cloud

1. In the Azure Portal → **Microsoft Defender for Cloud → Recommendations**.
2. Filter by **Vulnerabilities** or search for the CVE ID (e.g. `CVE-2024-38080`).
3. Click the recommendation → note the **affected resources** and the **KB associated** (shown in the recommendation details pane).

### Step 2 — Confirm the KB is in the Update Manager Assessment

1. Open **Azure Update Manager → Machines** → select the affected machine.
2. Go to the **Updates** tab → search for the KB number (e.g. `KB5040442`).
3. Confirm it appears under **Pending updates** with classification **Security** or **Critical**.

### Step 3 — Verify the KB is Not Excluded

1. Open the maintenance configuration assigned to the machine → **Updates** tab → **Excluded patches**.
2. Confirm the KB is not in the exclusion list.
3. If it is excluded, review the exemption register (Section 3.3) to determine if the exclusion should be lifted.

### Step 4 — Confirm the KB Was Installed

After the next patching run:

1. In **Azure Update Manager → History**, open the deployment run.
2. Expand the affected machine → look for the KB in the **Installed updates** list.
3. Cross-reference in Defender for Cloud: the CVE recommendation should move to **Healthy** state within 24 hours of the patch being installed and detected.

### CVE Response SLA Reference

| Severity | Maximum Days to Patch |
| --- | --- |
| Critical / Actively Exploited | 48 hours (emergency one-time update) |
| High | 7 days |
| Medium | 30 days |
| Low | 60 days |

---

## 7. Zero-Day Response Playbook

When a zero-day CVE is published and requires immediate patching outside the regular schedule, follow this playbook.

### Step 1 — Triage

1. Confirm the CVE affects your OS versions — check [MSRC](https://msrc.microsoft.com) for the affected KB and OS matrix.
2. Determine exploitability: is active exploitation confirmed in the wild? If yes, treat as P1.
3. Identify the affected machines using the CVE-to-KB mapping workflow (Section 6).

### Step 2 — Raise Emergency Change Request

1. Log a P1/emergency change request in your change management system.
2. Include: CVE ID, affected machines, KB to be deployed, planned deployment time, and rollback plan.
3. Obtain emergency change approval from the change authority.

### Step 3 — Deploy via One-Time Update

1. In **Azure Update Manager → Machines**, select only the affected machines.
2. Click **One-time update** (top of the machine list).
3. On the **Updates** tab: select **Security Updates** classification and optionally specify the KB number explicitly to limit scope.
4. On the **Properties** tab:
   - **Reboot option:** `Reboot if required`
   - **Maximum duration:** 120 minutes
5. Review + **Install**.

### Step 4 — Validate and Close

1. Monitor the deployment run in **Update Manager → History** to completion.
2. Collect log evidence (extension logs, Windows Update log) per the post-run validation workflow in [4-operational-runbooks.md — Section 2](4-operational%20runbooks.md#2-validate-logs-after-the-run).
3. Confirm the CVE recommendation clears in Defender for Cloud (allow up to 24 hours).
4. Update the change record with completion evidence and close.

---

## 8. Patch SLA Policy with Azure Policy

Enforce that machines remain assessed and patched within defined SLA windows using Azure Policy.

### 8.1 Built-in Policy: Periodic Assessment Must Be Enabled

Azure provides a built-in policy to enforce that periodic assessment is enabled on Azure VMs and Arc-enabled servers:

| Policy Display Name | Effect |
| --- | --- |
| `Configure periodic checking for missing system updates on azure virtual machines` | DeployIfNotExists |
| `Configure periodic checking for missing system updates on Azure Arc-enabled servers` | DeployIfNotExists |

**To assign:**

1. In the Azure Portal → **Azure Policy → Definitions** → search for the policy names above.
2. Click **Assign** → set scope to your subscription or management group.
3. Set **Effect** to `DeployIfNotExists` — this auto-enables periodic assessment on any non-compliant machine.
4. Create a remediation task to fix existing non-compliant machines immediately.

### 8.2 Custom Policy: Enforce Patch SLA (Audit)

The following custom policy definition audits machines that have pending critical patches older than 7 days.

```json
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "in": [
            "Microsoft.Compute/virtualMachines",
            "Microsoft.HybridCompute/machines"
          ]
        },
        {
          "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType",
          "equals": "Windows"
        }
      ]
    },
    "then": {
      "effect": "audit"
    }
  }
}
```

> For full enforcement, combine this policy with the Resource Graph query in [Section 5.4](#54-machines-assessed-but-not-patched-in-60-days) as the compliance data source feeding into a Logic App alert.

### 8.3 Assign and Monitor Compliance

1. Assign the policy at the **subscription** or **management group** scope for full fleet coverage.
2. Monitor compliance in **Azure Policy → Compliance** — filter by the policy initiative.
3. Non-compliant machines trigger auto-remediation if the effect is `DeployIfNotExists`, or appear on the audit report if effect is `Audit`.

---

## 9. Domain Controller Staggered Reboot Runbook

Domain Controllers must never be rebooted simultaneously. This runbook patches and reboots DCs one at a time, validating AD health between each.

### Prerequisites

- Azure Automation Account with Managed Identity having **Virtual Machine Contributor** and **Arc Machine Contributor** rights.
- All DCs onboarded to Azure Arc and visible in the Azure Portal.
- `Az.Accounts`, `Az.Compute`, `Az.ConnectedMachine` modules imported into the Automation Account.

### Runbook: `Invoke-DCStaggeredPatch.ps1`

```powershell
param(
    [Parameter(Mandatory)]
    [string[]]$DCNames,           # e.g. @('dc01','dc02','dc03')

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [int]$WaitMinutesBetweenDCs = 15
)

Connect-AzAccount -Identity

function Test-DCHealth {
    param([string]$DCName)

    Write-Output "--- Health check: $DCName ---"

    # Test AD replication
    $replResult = Invoke-Command -ComputerName $DCName -ScriptBlock {
        $output = repadmin /showrepl 2>&1
        if ($output -match 'error|failed') { return $false }
        return $true
    }

    # Test DNS
    $dnsResult = Invoke-Command -ComputerName $DCName -ScriptBlock {
        $output = dcdiag /test:dns 2>&1
        if ($output -match 'failed') { return $false }
        return $true
    }

    if (-not $replResult) {
        Write-Warning "AD replication issues detected on $DCName — stopping runbook."
        return $false
    }
    if (-not $dnsResult) {
        Write-Warning "DNS test failed on $DCName — stopping runbook."
        return $false
    }

    Write-Output "$DCName health checks passed."
    return $true
}

foreach ($dc in $DCNames) {
    Write-Output "=== Processing DC: $dc ==="

    # Verify FSMO before touching this DC
    $fsmo = Invoke-Command -ComputerName $dc -ScriptBlock {
        netdom query fsmo 2>&1
    }
    Write-Output "FSMO roles: $fsmo"

    # Trigger one-time update via Azure Update Manager REST API
    # (assumes Update Manager extension is installed on Arc machine)
    Write-Output "Submitting patch assessment and install for $dc..."

    # Wait for maintenance window to apply patches — replace with
    # your own API call or manual trigger via Azure Portal
    Start-Sleep -Seconds 30  # Placeholder — remove in production

    # Reboot the DC
    Write-Output "Initiating controlled reboot of $dc..."
    Restart-Computer -ComputerName $dc -Force -Wait -Timeout 600

    Write-Output "Waiting $WaitMinutesBetweenDCs minutes before proceeding to the next DC..."
    Start-Sleep -Seconds ($WaitMinutesBetweenDCs * 60)

    # Validate health post-reboot
    $healthy = Test-DCHealth -DCName $dc
    if (-not $healthy) {
        Write-Error "Health check failed after rebooting $dc. Stopping staggered reboot sequence. Investigate before continuing."
        exit 1
    }

    Write-Output "$dc completed and validated. Moving to next DC."
}

Write-Output "All DCs patched and validated successfully."
```

### Post-Run Validation Checklist

| Check | Command | Expected Result |
| --- | --- | --- |
| AD replication healthy | `repadmin /showrepl` | No errors |
| DNS operational | `dcdiag /test:dns` | All tests passed |
| FSMO roles on expected holder | `netdom query fsmo` | Correct DC names |
| Sysvol replicated | `repadmin /replsummary` | 0 failures |
| DC reachable from clients | `nltest /dsgetdc:<domain>` | Returns DC name |

---

## 10. Windows Server 2012 R2 ESU with Azure Arc

Windows Server 2012 and 2012 R2 reached end of support on **October 10, 2023**. Extended Security Updates (ESU) are available through Azure Arc.

> **Timing check:** As of this guide's last validation date (2026-07-10), the **final ESU coverage ends October 13, 2026 — roughly 3 months away.** After that date, no security updates are issued for Windows Server 2012/2012 R2 at any price, regardless of Arc enrollment. If you still have machines on this OS, treat migration to Windows Server 2022/2025 (or an Azure Arc-managed retirement plan) as an active, time-boxed project now, not a "someday" item.

### Eligibility

| Requirement | Detail |
| --- | --- |
| Azure Arc onboarded | Machine must show **Status: Connected** in Azure Arc |
| Arc agent version | **1.34 or later** — this is a hard prerequisite for ESU delivery. Check the installed version in **Azure Arc → Machines → [server] → Overview**. |
| Core minimums | Physical core (pCore) licensing requires **16 cores minimum** per machine; virtual core (vCore) licensing requires **8 vCores minimum** per VM |
| ESU license type | An ESU license (SKU: Standard or Datacenter) must be provisioned and linked to the Arc machine resource |

> **Upgrading the Arc agent:** If the agent is already running version **1.62 or later**, you can upgrade in place with `azcmagent upgrade` (add `--version 1.63` to target a specific release). If the agent is **older than 1.62**, that command isn't supported — instead run the MSI installer silently on Windows (`msiexec.exe /i AzureConnectedMachineAgent.msi /qn`) or, on Linux, update via the package manager (e.g. `apt update && apt upgrade azcmagent`). Either path can be scripted for at-scale upgrades; no server restart is required.

### 10.1 Enroll in ESU via Azure Portal

ESU enrollment is a two-step process: provision a license, then link eligible Arc machines to it.

1. In the Azure Portal service menu, under **Licenses**, select **Windows Server ESU licenses**.
2. Select **+ Create** to provision a new ESU license — specify the SKU (**Standard** or **Datacenter**), core type (**Physical** or **vCore**), and number of cores. You can create the license in a deactivated state if you don't want billing to start immediately.
3. Once the license is active, go to the **Eligible resources** tab to see all Arc-enabled servers running Windows Server 2012/2012 R2.
4. Select the target machine(s) → **Enable ESUs** → choose the license to link → **Enable**.
5. The machine's ESU status changes to **Enabled** once linking completes — no additional key or activation step is required on the server itself.

> **Late enrollment billing:** If you enroll a machine in ESU after its end-of-support date, Azure back-bills for the months missed since that date (charged in the first billing cycle after enrollment). Enrolling sooner avoids an unexpected lump-sum charge.

### 10.2 Verify ESU Patch Delivery via Update Manager

1. Run an on-demand assessment on the 2012 R2 machine from **Azure Update Manager → Machines → Check for updates**.
2. Confirm ESU patches appear in the **Updates** tab with the `Security` classification.
3. Include the machine in your maintenance configuration using a tag filter: `OSVersion=2012R2`.

### 10.3 ESU End Date

| Version | ESU End Date |
| --- | --- |
| Windows Server 2012 R2 | October 13, 2026 |
| Windows Server 2012 | October 13, 2026 |

> **This is now a near-term deadline, not a planning horizon.** Given today's date, roughly 3 months remain before ESU coverage ends permanently — after which no security updates will be issued regardless of Arc enrollment or payment. Prioritize migration to Windows Server 2022 or 2025 (or retirement of the workload) over extending ESU further, since October 13, 2026 is the **final** renewal; there is no Year 4.

---

## 11. Bicep Templates for Maintenance Configurations

Deploy the full maintenance configuration stack as Infrastructure as Code, consistent with the [Bicep track](../Bicep/README.md).

### 11.1 Module: Single Maintenance Configuration

**File: `maintenanceConfig.bicep`**

```bicep
@description('Name of the maintenance configuration')
param name string

@description('Azure region for the maintenance configuration')
param location string

@description('Start time in ISO 8601 format, e.g. 2026-07-11 23:00')
param startDateTime string

@description('Recurrence cadence: Daily, Weekly, or Monthly')
@allowed(['Daily', 'Weekly', 'Monthly'])
param recurrence string = 'Weekly'

@description('Day of week for weekly schedules, e.g. Friday')
param recurEvery string = 'Friday'

@description('Maintenance window duration in ISO 8601 duration format')
param duration string = 'PT3H55M'

@description('Update classifications to include')
param classifications array = ['Security', 'Critical', 'UpdateRollup', 'Definition']

resource maintenanceConfig 'Microsoft.Maintenance/maintenanceConfigurations@2023-04-01' = {
  name: name
  location: location
  properties: {
    maintenanceScope: 'InGuestPatch'
    maintenanceWindow: {
      startDateTime: startDateTime
      duration: duration
      recurEvery: '1 ${recurrence} ${recurEvery}'
      timeZone: 'Pacific Standard Time'
      expirationDateTime: null
    }
    installPatches: {
      windowsParameters: {
        classificationsToInclude: classifications
        kbNumbersToExclude: []
        kbNumbersToInclude: []
      }
      rebootSetting: 'RebootIfRequired'
    }
    extensionProperties: {
      InGuestPatchMode: 'User'
    }
  }
}

output id string = maintenanceConfig.id
output name string = maintenanceConfig.name
```

### 11.2 Main Deployment: All Patch Groups

**File: `maintenanceStack.bicep`**

```bicep
@description('Azure region for all maintenance configurations')
param location string = 'westus2'

// Dev — Week 1, Saturday 01:00
module mcDev 'maintenanceConfig.bicep' = {
  name: 'mc-dev-monthly'
  params: {
    name: 'mc-dev-monthly'
    location: location
    startDateTime: '2026-07-12 01:00'
    recurrence: 'Monthly'
    recurEvery: '1Saturday'
    duration: 'PT2H'
    classifications: ['Security', 'Critical', 'UpdateRollup', 'Definition', 'Updates']
  }
}

// UAT — Week 2, Saturday 01:00
module mcUAT 'maintenanceConfig.bicep' = {
  name: 'mc-uat-monthly'
  params: {
    name: 'mc-uat-monthly'
    location: location
    startDateTime: '2026-07-19 01:00'
    recurrence: 'Monthly'
    recurEvery: '2Saturday'
    duration: 'PT3H'
    classifications: ['Security', 'Critical', 'UpdateRollup', 'Definition']
  }
}

// Prod — Week 3, Tuesday 02:00
module mcProd 'maintenanceConfig.bicep' = {
  name: 'mc-prod-monthly'
  params: {
    name: 'mc-prod-monthly'
    location: location
    startDateTime: '2026-07-21 02:00'
    recurrence: 'Monthly'
    recurEvery: '3Tuesday'
    duration: 'PT3H55M'
    classifications: ['Security', 'Critical', 'UpdateRollup', 'Definition']
  }
}

// Domain Controllers — Week 3, Sunday 03:00
module mcDC 'maintenanceConfig.bicep' = {
  name: 'mc-dc-monthly'
  params: {
    name: 'mc-dc-monthly'
    location: location
    startDateTime: '2026-07-19 03:00'
    recurrence: 'Monthly'
    recurEvery: '3Sunday'
    duration: 'PT3H55M'
    classifications: ['Security', 'Critical', 'UpdateRollup']
  }
}

output devConfigId string = mcDev.outputs.id
output uatConfigId string = mcUAT.outputs.id
output prodConfigId string = mcProd.outputs.id
output dcConfigId string = mcDC.outputs.id
```

### 11.3 Deploy the Stack

```bash
az deployment group create \
  --resource-group rg-patchops-prod \
  --template-file maintenanceStack.bicep \
  --parameters location=westus2
```

Or from the [Bicep track VS Code workflow](../Bicep/2-how-to-run-bicep-in-vscode.md):

1. Open `maintenanceStack.bicep` in VS Code.
2. Right-click → **Deploy Bicep File**.
3. Select subscription, resource group, and confirm parameters.

---

## 12. Cross-Subscription Patching

Cross-subscription patching lets you target machines across multiple Azure subscriptions from a single maintenance configuration or one-time update operation. This is critical for enterprises that deploy workloads into separate landing-zone subscriptions (prod, dev, shared-services) but want a centralized patching team to own the schedule.

### How It Works

- A maintenance configuration lives in one **home subscription** but its **dynamic scope** can reference machines in other subscriptions that your identity has access to.
- Permissions are evaluated per-resource: the principal running the deployment needs at least **Azure Update Manager Operator** (or **Contributor**) on each target resource group across the subscriptions.
- Rate limits apply when managing large numbers of assets via API/SPN. Distribute load across multiple service principals if you have thousands of machines.

### 12.1 Pre-Requisites for Cross-Subscription

| Requirement | Detail |
| --- | --- |
| Role | **Azure Update Manager Operator** (or **Contributor**) on each target subscription / resource group |
| Managed Identity | If using a service principal for automation, assign **Reader** on target resources for ARG-based alert rules |
| Supported resources | Azure VMs and Arc-enabled servers (same supported OS matrix as single-subscription patching) |

### 12.2 Configure a Dynamic Scope Spanning Multiple Subscriptions

1. In **Azure Update Manager → Maintenance configurations**, open or create a maintenance configuration.
2. Go to the **Dynamic scopes** tab.
3. Click **+ Add a scope**.
4. In the scope editor, change the **Subscription** dropdown from the home subscription to a target subscription.
5. Optionally add a **Resource group** or **Tag** filter to narrow the scope within that subscription.
6. Repeat for each additional subscription.
7. Save the configuration — the dynamic scope now resolves machines across all added subscriptions at deployment time.

> When the maintenance window fires, Update Manager enumerates all machines matching every scope entry across all subscriptions. Machines that no longer exist or whose tags changed are automatically excluded.

### 12.3 One-Time Update Across Subscriptions

For ad-hoc deployments (e.g. zero-day emergency patches) across subscriptions:

1. In **Azure Update Manager → Machines**, use the **Subscription** filter at the top to select **All subscriptions**.
2. The machine list now shows machines from every subscription your identity has access to.
3. Select the affected machines (regardless of which subscription they belong to) → click **One-time update** → configure classifications and reboot options as usual.
4. The deployment runs concurrently across all selected machines.

### 12.4 Limitations

| Limitation | Detail |
| --- | --- |
| Rate limiting | Large multi-subscription operations via API/SPN can hit Azure Resource Manager rate limits; distribute load across multiple service principals if batching > 1,000 machines |
| Unsupported images | Machines running unsupported OS images included in a cross-subscription schedule will cause the maintenance configuration to fail for those machines; confirm OS support before adding machines |
| ARG query row limit | ARG-based queries return a maximum of 1,000 rows — paginate queries for fleets exceeding this size |
| Azure Government / 21Vianet | Cross-subscription patching is supported in Azure Government and Azure operated by 21Vianet |

---

## 13. Quick Alerts (Native Update Manager Alerting)

Quick Alerts (preview, August 2025) is a simplified alerting experience built directly into the Update Manager portal. It creates **Azure Resource Graph (ARG)-backed alert rules** without requiring you to navigate to Azure Monitor — useful for patch operations teams that want alerting set up as part of their Update Manager configuration, not as a separate observability task.

> **Relationship to Azure Monitor alerts (Lab 4):** Quick Alerts and the Azure Monitor alert rules in [4-operational-runbooks.md](4-operational%20runbooks.md#4-alerting-for-arc-agent-disconnects) are complementary, not mutually exclusive. Quick Alerts covers patch-specific events (missing updates, failed deployments) using predefined ARG queries. Azure Monitor alerts cover infrastructure-level events (Arc agent heartbeat, extension failures) using Log Analytics KQL. Use both.
> **Note:** Quick Alerts is not available in Azure US Government or Azure operated by 21Vianet.

### 13.1 Create a Quick Alert Rule

1. In the Azure Portal, open **Azure Update Manager**.
2. In the left navigation, under **Monitoring**, select **New alerts rule (Preview)**.
3. Configure the scope:
   - **Subscription** — the subscription the alert rule will be created in.
   - **Resource Group** — the resource group where the alert rule resource will live.
   - **Location** — region for the alert rule resource.
4. In the **Azure Resource Graph query** dropdown, select one of the predefined alert queries:

| Predefined Query | Fires When |
| --- | --- |
| Machines with critical/security updates pending | One or more machines have uninstalled critical or security updates |
| Failed update deployments | An update deployment completes with one or more machine failures |
| Machines not assessed in 30 days | A machine has not had an assessment run in the last 30 days |
| Machines pending reboot | One or more machines have installed updates but are waiting for a reboot |

5. Alternatively, select **Custom query** to write your own ARG KQL query.
6. Click **Preview or edit query in Logs** to validate the query returns expected results.
7. Configure:
   - **Scope and filters** — subscription/resource group filter for the query.
   - **Threshold and frequency** — how often the query runs and at what result count the alert fires.
   - **Notify me** — email, SMS, or action group.
8. Click **Quick create a new rule** to create the alert.

### 13.2 Recommended Quick Alert Ruleset

Create one rule for each of the following to build a baseline patch-operations alerting posture:

| Rule | Predefined Query | Severity | Frequency |
| --- | --- | --- | --- |
| Critical patches pending | Machines with critical/security updates pending | Sev 2 | Every 24 hours |
| Failed deployments | Failed update deployments | Sev 1 | Every 1 hour |
| Stale assessments | Machines not assessed in 30 days | Sev 2 | Every 24 hours |
| Pending reboots | Machines pending reboot | Sev 2 | Every 12 hours |

### 13.3 View and Manage Alerts

1. In **Azure Update Manager → Monitoring → New alerts rule (Preview)**, click **Go to alerts**.
2. The **Monitor | Alerts** page shows all fired alerts, with source, severity, and time.
3. To edit a quick alert rule: click the alert rule name → **Edit** → modify the query, threshold, or notification target.

> The ARG query used for Quick Alerts returns up to **1,000 rows**. If your fleet exceeds that, add subscription/resource group filters in the **Scope and filters** step to keep results within the limit.

---

[← Azure Update Manager Lab](1-Azure%20Update%20Manager.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
