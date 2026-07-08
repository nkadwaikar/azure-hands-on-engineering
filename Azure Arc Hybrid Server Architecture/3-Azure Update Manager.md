
# Azure Update Manager — Monthly Patching Operational Guide

> **Why this matters:** Without a structured patching workflow, large hybrid fleets drift out of compliance silently — CVEs accumulate, failed deployments go unnoticed, and audit evidence is absent. Azure Update Manager, combined with Azure Arc and Defender for Servers, turns patching into a measurable, auditable, and automatable operation that scales from 10 to 10,000 servers with the same process.

Last validated on: July 2026
Portal experience note: Steps validated against Azure Portal (Azure Update Manager, Defender for Cloud) as of July 2026. Applies to both Azure VMs and Azure Arc-enabled Windows servers.

> **Companion guides:**
>
> - [Azure Arc Hybrid Server Architecture](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) — the architecture and onboarding reference this guide builds on.
> - [On-Prem Hyper-V Lab Setup for Azure Arc](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) — set up a disposable lab to validate the full patching pipeline end-to-end before production rollout.

---

## Quick Navigation

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Pipeline Setup](#pipeline-setup-azure-arc--defender-for-servers--azure-update-manager)
  - [Step 1 — Onboard Servers to Azure Arc](#step-1--onboard-servers-to-azure-arc)
  - [Step 2 — Enable Defender for Servers](#step-2--enable-defender-for-servers)
  - [Step 3 — Verify Defender for Servers Activation](#step-3--verify-defender-for-servers-activation)
  - [Step 4 — Configure Azure Update Manager](#step-4--configure-azure-update-manager)
- [Monthly Patch Review Workflow](#monthly-patch-review-workflow)
  - [1 — Review Update Compliance](#1--review-update-compliance)
  - [2 — Review Security & CVE Exposure](#2--review-security--cve-exposure)
  - [3 — Validate Patch Groups](#3--validate-patch-groups)
  - [4 — Remediate Failed Servers](#4--remediate-failed-servers)
  - [5 — Export Monthly Reports](#5--export-monthly-reports)
- [Patch Group Tagging Strategy](#patch-group-tagging-strategy)
- [Maintenance Window Design](#maintenance-window-design)
- [KQL Queries for Compliance Reporting](#kql-queries-for-compliance-reporting)
- [Check List](#check-list)

---

## Architecture Overview

This document provides a complete, step-by-step operational workflow for reviewing and deploying monthly patches in environments using Azure Arc, Defender for Servers, and Azure Update Manager. It is designed for large-scale server fleets (300+ servers) and ensures consistent patch compliance, CVE visibility, and security posture.

### Data Flow

```text
On-Prem / Multi-Cloud Servers
  └─ Azure Arc (Connected Machine Agent)
        └─ Azure Resource Manager
              ├─ Azure Update Manager
              │     ├─ Patch Assessment
              │     ├─ Scheduled Deployments
              │     └─ Compliance Reporting
              └─ Defender for Servers (Plan 2)
                    ├─ CVE / Vulnerability Exposure
                    ├─ Missing KB mapping
                    └─ Secure Score (patch-related)
```

### Component Responsibilities

| Component | Role in Patching |
| --- | --- |
| **Azure Arc** | Onboards hybrid/on-prem servers into Azure; enables tagging, policy, extensions, and centralized management |
| **Defender for Servers** | Provides CVE exposure, missing KB visibility, exploitable vulnerability prioritization, and Secure Score impact |
| **Azure Update Manager** | Deploys patches across Azure VMs and Arc-enabled servers; manages compliance dashboards, maintenance windows, and orchestration |

This pipeline ensures full automation and full visibility for monthly patching across hybrid environments.

---

## Prerequisites

### Permissions Required

| Role | Scope | Purpose |
| --- | --- | --- |
| `Azure Connected Machine Onboarding` | Subscription / RG | Register Arc machines |
| `Azure Connected Machine Resource Administrator` | Subscription / RG | Manage Arc machine resources |
| `Log Analytics Contributor` | Log Analytics Workspace | Configure monitoring |
| `Security Admin` | Subscription | Enable Defender for Cloud |
| `Contributor` | Subscription / RG | Create and manage Update Manager schedules |

### Azure Resources Required

- Azure Arc-enabled servers (see [Arc Architecture guide](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md))
- Log Analytics Workspace (e.g. `law-hybrid-ops`)
- Defender for Cloud with **Servers Plan 2** enabled
- Azure Update Manager (no separate resource to create — accessed via portal or subscription)

### Supported Operating Systems

| Platform | Supported Versions |
| --- | --- |
| Windows Server | 2008 R2 SP1, 2012, 2016, 2019, 2022 |

> **Note:** Servers must be Arc-onboarded and show **Status: Connected** before Update Manager can assess or deploy patches.

---

## Pipeline Setup: Azure Arc → Defender for Servers → Azure Update Manager

### Step 1 — Onboard Servers to Azure Arc

1. Follow the full onboarding flow in the [Azure Arc Hybrid Server Architecture guide](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) (Sections 3.5 and 3.6).
2. Confirm each server appears under **Azure Arc → Machines** with **Status: Connected**.
3. Apply mandatory tags at onboarding time (see [Patch Group Tagging Strategy](#patch-group-tagging-strategy) below).
4. Validate Arc extensions are healthy: **Azure Arc → Machines → [server] → Extensions**.

### Step 2 — Enable Defender for Servers

1. In the Azure Portal, go to **Microsoft Defender for Cloud → Environment settings**.
2. Select your subscription.
3. Set **Defender for Servers** to **Plan 2** (required for vulnerability assessment and FIM).
4. Under **Settings**, turn **ON** auto-provisioning for:
   - **Defender for Endpoint (MDE)** — EDR sensor
   - **Vulnerability assessment extension** — Qualys or Defender MDVM
   - **Azure Monitor Agent (AMA)** and associated DCR
5. Click **Save**. Plan activation propagates to Arc machines within ~15 minutes.

> **Plan 2 vs Plan 1:** Use Plan 2 for Tier 1/Tier 2 production servers (full EDR + vulnerability assessment + JIT + FIM). Plan 1 is sufficient for Tier 3 / dev-test servers. Apply per resource group using Defender for Cloud's granular plan controls to manage cost.

### Step 3 — Verify Defender for Servers Activation

1. Open [security.microsoft.com](https://security.microsoft.com) → **Assets → Devices**.
2. Confirm Arc-onboarded servers appear in the device inventory.
3. For each server verify the following are populated:
   - **Exposure level** (Low / Medium / High / Critical)
   - **CVE count** and individual CVE listings
   - **Security recommendations** (linked to missing patches)
   - **Active alerts** (if any)
4. In the Azure Portal, go to **Defender for Cloud → Recommendations** and filter by **Vulnerabilities** — missing KBs and CVE-linked recommendations should appear here within 24 hours of plan activation.

### Step 4 — Configure Azure Update Manager

#### Create a Maintenance Configuration (Scheduled Patching)

1. In the Azure Portal, search for **Azure Update Manager** and open it.
2. Go to **Maintenance configurations** → **+ Create**.
3. On the **Basics** tab:
   - Set **Subscription**, **Resource Group**, and **Maintenance configuration name** (e.g. `mc-prod-monthly-patch`).
   - Set **Region** to match your server locations.
   - Set **Schedule** to **Monthly** — choose a specific day/time (e.g. second Tuesday, 2:00 AM UTC) aligned with your change management window.
4. On the **Updates** tab, configure:
   - **Update classifications:** Critical, Security (always include these); add Definition updates and Update Rollups as needed.
   - **KB IDs to include / exclude:** leave blank unless specific KBs need to be blocked (e.g. a known bad update).
   - **Reboot setting:** choose one of:
     - `Always reboot if required` (recommended for most servers)
     - `Never reboot` (for servers requiring manual reboot approval)
     - `Reboot if required, otherwise skip`
   - **Maintenance window:** set duration (e.g. 3–4 hours for large fleets; Update Manager stops deploying to new machines if the window closes mid-run but completes in-progress machines).
5. On the **Pre/Post scripts** tab (optional): configure Azure Automation runbooks to run before or after patching (e.g. drain load balancer, take snapshot).
6. Review + **Create**.

#### Assign Machines to a Maintenance Configuration

1. Open the newly created **Maintenance configuration** → **Machines** → **+ Add machines**.
2. Filter by **Resource type** (Arc machines, VMs) and **Tag** (e.g. `PatchGroup = Prod`).
3. Select all applicable machines → **Add**.
4. Repeat for each tag group / environment, creating a separate maintenance configuration per group (see [Maintenance Window Design](#maintenance-window-design)).

---

## Monthly Patch Review Workflow

### 1 — Review Update Compliance

1. In the Azure Portal, open **Azure Update Manager → Update compliance** (or **Overview**).
2. Review the **overall compliance percentage** across all managed machines.
3. Click into **Missing updates** to see which KBs are not yet installed across the fleet.
4. Open **Failed updates** to identify machines requiring remediation — expand each entry to see the specific error code.
5. Check the **Pending reboot** list — machines awaiting restart are not yet fully patched.
6. For any server showing anomalies, open **Azure Update Manager → History** and filter by machine name to review individual deployment run logs.

### 2 — Review Security & CVE Exposure

1. In the Azure Portal, go to **Microsoft Defender for Cloud → Recommendations**.
2. Filter by **Vulnerabilities** or search for "System updates should be installed".
3. Review **CVE exposure per server** — click into a recommendation to see affected resources and CVE details.
4. Check **Missing KBs mapped to CVEs** — cross-reference with the Update Manager missing updates list from Step 1.
5. Prioritize **Exploitable vulnerabilities** (flagged as actively exploited in the wild by Microsoft threat intelligence).
6. Review the **Secure Score** impact — patch-related findings typically contribute significantly to overall score.

### 3 — Validate Patch Groups

After each monthly patching cycle, validate results per tag group:

| PatchGroup Tag | Validation Check |
| --- | --- |
| `Prod` | Fully patched, no pending reboots, services confirmed healthy |
| `UAT` | Patches applied; confirm no regressions before promoting to Prod |
| `Dev` | Patches applied; lower priority but should not remain unpatched >60 days |
| `DC` | Domain Controllers patched one at a time — confirm FSMO roles, AD replication, and DNS are healthy after each reboot |

**Steps in Azure Update Manager:**

1. Open **Azure Update Manager → Update compliance**.
2. Use the **Resource group**, **Subscription**, or **Tag** filter to scope the view to one patch group at a time.
3. Confirm Prod servers show 100% compliance (or document exceptions with approved exemptions).
4. Verify Domain Controllers were patched in a staggered sequence — never simultaneously.
5. Confirm non-prod issues are isolated and do not indicate a patch quality issue that would affect Prod.

### 4 — Remediate Failed Servers

1. Open **Azure Update Manager → Failed updates** and note affected machines.
2. For each failed machine:
   - Check the **error code** in the deployment log (common codes: `0x8024200D` = download failure, `0x80070005` = permissions, `WU_E_NO_SERVICE` = Windows Update service stopped).
   - Re-run deployment: select the machine → **One-time update** → select the missing/failed KBs → **Install now**.
3. If reboot is required but was blocked: coordinate with the server owner and perform a manual reboot, then re-check compliance.
4. Validate the **Azure Arc agent health**:
   - Portal: **Azure Arc → Machines → [server] → Overview** — confirm **Status: Connected** and recent heartbeat.
   - If disconnected, re-run the onboarding script or restart the `himds` service on the server.
5. Validate the **Azure Update Manager extension** is installed: **Azure Arc → Machines → [server] → Extensions** — look for `WindowsAgent.AzureUpdateManager`.
6. Review OS-level update logs for additional diagnostics:
   - **Windows:** `C:\Windows\WindowsUpdate.log` or `Get-WindowsUpdateLog` (PowerShell)
7. If patches consistently exceed the maintenance window, extend the window duration in the maintenance configuration settings.

### 5 — Export Monthly Reports

#### Generate Reports in Azure Update Manager

1. Open **Azure Update Manager → Update compliance**.
2. Use the **Download** or **Export** option to save a CSV of the current compliance state.
3. Apply tag filters to export per-environment reports (Prod, UAT, Dev).

#### Generate CVE Reports in Defender for Cloud

1. Open **Defender for Cloud → Recommendations** → filter to vulnerability findings.
2. Export the recommendations to CSV (Download button, top of the list).
3. Filter by **Severity: High / Critical** to produce the high-risk server list.

#### Archive and Distribute

| Report | Audience |
| --- | --- |
| Update compliance report | Infrastructure team, Change Management |
| CVE exposure report | Security team |
| High-risk server list | Security team, Leadership |
| Failed patching list | Infrastructure team (remediation owners) |
| Pending reboot list | Infrastructure team + server owners |
| Monthly executive summary | Leadership |

Store archived reports in a shared location (e.g. SharePoint, Azure Blob Storage) with at minimum 12 months retention for audit purposes.

---

## Patch Group Tagging Strategy

Tag servers at Arc onboarding time to enable automated patch group targeting in Update Manager maintenance configurations. Enforced via Azure Policy (deny or modify effect) so servers are compliant from the moment they register.

| Tag Key | Example Values | Purpose |
| --- | --- | --- |
| `PatchGroup` | Prod, UAT, Dev, DC | Update Manager schedule targeting |
| `Environment` | Prod, Dev, Test | RBAC, policy, and cost reporting scope |
| `Criticality` | Tier1, Tier2, Tier3 | Defender for Servers plan selection (Plan 2 vs Plan 1) |
| `BusinessUnit` | Finance, Retail, SharedServices | Charge-back and compliance reporting |

Apply all tags when generating the Arc onboarding script (portal → **Tags** tab during onboarding) so no post-onboarding fix-up is required.

---

## Maintenance Window Design

Separate maintenance configurations prevent a single schedule from patching all environments simultaneously, which would eliminate the safety net of catching patch regressions in non-prod before they reach production.

| Maintenance Configuration | Tag Filter | Schedule | Reboot Setting |
| --- | --- | --- | --- |
| `mc-dev-monthly` | `PatchGroup = Dev` | Week 1, Saturday 1:00 AM | Always reboot if required |
| `mc-uat-monthly` | `PatchGroup = UAT` | Week 2, Saturday 1:00 AM | Always reboot if required |
| `mc-prod-monthly` | `PatchGroup = Prod` | Week 3, Tuesday 2:00 AM | Always reboot if required |
| `mc-dc-monthly` | `PatchGroup = DC` | Week 3, Sunday 3:00 AM | Never reboot (manual reboot, staggered) |

**Domain Controller guidance:** DC maintenance configurations should use `Never reboot` (or a dedicated runbook with staggered reboot logic). After patching, manually reboot DCs one at a time and validate between each:

- Run `repadmin /showrepl` to confirm AD replication is healthy.
- Run `dcdiag /test:dns` to confirm DNS is operational.
- Confirm FSMO roles remain on the expected holder with `netdom query fsmo`.

---

## KQL Queries for Compliance Reporting

Run these in **Log Analytics workspace → Logs** to support the monthly review workflow.

**Overall update compliance by machine:**

```kql
UpdateSummary
| where TimeGenerated > ago(7d)
| summarize arg_max(TimeGenerated, *) by Computer
| project Computer, TotalUpdatesMissing, CriticalUpdatesMissing, SecurityUpdatesMissing, LastAssessedTime
| order by CriticalUpdatesMissing desc
```

**Machines with pending reboots:**

```kql
UpdateSummary
| where TimeGenerated > ago(7d)
| where RebootRequired == true
| summarize arg_max(TimeGenerated, *) by Computer
| project Computer, RebootRequired, TotalUpdatesMissing, LastAssessedTime
```

**Failed update deployments in the last 30 days:**

```kql
UpdateRunProgress
| where TimeGenerated > ago(30d)
| where InstallationStatus == "Failed"
| project Computer, UpdateRunName, Title, InstallationStatus, TimeGenerated
| order by TimeGenerated desc
```

**Arc agent heartbeat (detect disconnected servers):**

```kql
Heartbeat
| where TimeGenerated > ago(1h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer, OSType, ResourceGroup
| where LastHeartbeat < ago(15m)
| order by LastHeartbeat asc
```

---

## Check List

1. **Arc onboarding complete** — all target servers show **Status: Connected** in **Azure Arc → Machines** with correct tags applied ([Step 1](#step-1--onboard-servers-to-azure-arc)).
2. **Tagging validated** — `PatchGroup`, `Environment`, `Criticality`, and `OS` tags present and accurate on all Arc machines ([Patch Group Tagging Strategy](#patch-group-tagging-strategy)).
3. **Defender for Servers Plan 2 enabled** — subscription-level plan active; MDE and vulnerability assessment auto-provisioned ([Step 2](#step-2--enable-defender-for-servers)).
4. **Defender inventory confirmed** — servers visible in [security.microsoft.com](https://security.microsoft.com) with exposure levels and CVE data populated ([Step 3](#step-3--verify-defender-for-servers-activation)).
5. **Maintenance configurations created** — separate schedules per patch group; window durations, reboot settings, and update classifications configured ([Step 4](#step-4--configure-azure-update-manager)).
6. **Machines assigned to schedules** — all Arc machines and VMs assigned to the correct maintenance configuration via tag-based selection.
7. **First compliance baseline captured** — Update Manager assessment run completed; export and archive initial compliance state.
8. **Monthly review process documented** — team knows which portal views to check, which KQL queries to run, and who receives which reports ([Monthly Patch Review Workflow](#monthly-patch-review-workflow)).
9. **DC patching procedure confirmed** — staggered reboot runbook or manual procedure documented and tested ([Maintenance Window Design](#maintenance-window-design)).
10. **Report archive location established** — compliance and CVE reports stored with 12-month retention for audit evidence ([Step 5 — Export Monthly Reports](#5--export-monthly-reports))
