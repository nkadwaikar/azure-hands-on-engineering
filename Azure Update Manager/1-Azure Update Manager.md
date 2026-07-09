# Azure Update Manager — Patch Orchestration & Operational Guide

> **Why this matters:** Unpatched systems are the most exploited attack surface in enterprise environments. Azure Update Manager provides a single, agent-free control plane for assessing and deploying OS updates across Azure VMs, Arc-enabled on-premises servers, and multi-cloud machines. Combined with Azure Arc and Defender for Servers, it turns patching into a measurable, auditable, and automatable operation that scales from 10 to 10,000 servers — without routing telemetry through Log Analytics as a dependency.

Last validated on: 2026-07-07
Portal experience note: Steps validated against Azure Portal (Update Manager blade) as of July 2026. The Update Manager blade is accessed via **Search → Azure Update Manager** or via the **Operations** section of individual VM resources. Applies to both Azure VMs and Azure Arc-enabled Windows/Linux servers.

> **Note:** This guide targets the standalone Azure Update Manager service (generally available). If your subscription still uses the legacy Update Management solution embedded in Azure Automation accounts, you will need to migrate to Update Manager before proceeding — the two solutions conflict when managing the same machine.

---

## Module / Track Structure

```text
Azure Update Manager/
├── README.md                          ← Track entry point
└── 1-Azure Update Manager.md          ← Lab + Operational Guide (you are here)
```

> **Companion guides:**
>
> - [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) — architecture and onboarding reference; complete this before targeting Arc servers with Update Manager.
> - [On-Prem Hyper-V Lab Setup for Azure Arc](../Azure%20Arc%20Hybrid%20Server%20Architecture/2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) — set up a disposable lab to validate the full patching pipeline end-to-end before production rollout.

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Architecture Overview](#architecture-overview)
- [Part 1: Lab Walkthrough](#part-1-lab-walkthrough)
  - [Step 1 — Enable and Scope Update Manager](#step-1--enable-and-scope-update-manager)
  - [Step 2 — Run an On-Demand Patch Assessment](#step-2--run-an-on-demand-patch-assessment)
  - [Step 3 — Configure a Maintenance Window](#step-3--configure-a-maintenance-window)
  - [Step 4 — Schedule and Execute an Update Deployment](#step-4--schedule-and-execute-an-update-deployment)
  - [Step 5 — Review Compliance and Patch History](#step-5--review-compliance-and-patch-history)
  - [Step 6 — KQL Queries for Patch State](#step-6--kql-queries-for-patch-state)
- [Part 2: Operational Workflow for Hybrid Fleets](#part-2-operational-workflow-for-hybrid-fleets)
  - [Pipeline Setup: Azure Arc → Defender for Servers → Azure Update Manager](#pipeline-setup-azure-arc--defender-for-servers--azure-update-manager)
  - [Monthly Patch Review Workflow](#monthly-patch-review-workflow)
  - [Patch Group Tagging Strategy](#patch-group-tagging-strategy)
  - [Maintenance Window Design](#maintenance-window-design)
- [Troubleshooting](#troubleshooting)
- [Why Update Manager Matters](#why-update-manager-matters-engineering-justification)
- [Checklist](#checklist)
- [Cleanup](#cleanup)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Contributor** on the target resource group (or **Azure Update Manager Contributor** built-in role) |
| Target machines | At least one running Azure VM or Arc-enabled server in a supported OS |
| Arc requirement | If targeting Arc servers: Azure Connected Machine Agent installed and status **Connected** — complete [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) first |
| Supported OS | **Azure VMs:** Windows Server 2012 R2+, Windows Server 2016/2019/2022/2025; RHEL 7/8/9, SLES 12/15, Ubuntu 16.04–24.04 LTS, Debian 10/11/12, Amazon Linux 2/2023, Rocky Linux 8/9, Alma Linux 8/9 **Arc servers:** Windows Server 2012 R2+; same Linux distros above |
| No conflicting solution | Legacy Update Management (Log Analytics-based) must not be active on the same machines |
| Estimated Time | 45–60 minutes (lab); additional time for operational workflow setup |
| Tools | Azure Portal only — no CLI required |

### Additional Permissions for Hybrid Fleets (Part 2)

| Role | Scope | Purpose |
| --- | --- | --- |
| `Azure Connected Machine Onboarding` | Subscription / RG | Register Arc machines |
| `Azure Connected Machine Resource Administrator` | Subscription / RG | Manage Arc machine resources |
| `Log Analytics Contributor` | Log Analytics Workspace | Configure monitoring |
| `Security Admin` | Subscription | Enable Defender for Cloud |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- Lab uses the Azure Portal Update Manager blade; PowerShell and REST API paths exist but are out of scope.
- Automatic VM Guest Patching (cloud-init / Windows Automatic Updates) on Azure VMs is separate from Update Manager scheduling — if already enabled, Update Manager coexists but scheduled deployments take precedence during the defined window.
- Arc-enabled servers must have outbound HTTPS (port 443) connectivity to Azure endpoints — connectivity validated in the Arc track.

---

## 2. Learning Objectives

By the end of this guide, you will have:

- Explored the **Azure Update Manager** blade and understood fleet-level patch posture at a glance
- Run an **on-demand patch assessment** to surface available updates without installing anything
- Created a **maintenance window** and understood how it gates when updates are permitted
- Scheduled and executed an **update deployment** with classification and exclusion filters
- Reviewed **compliance reporting** and identified machines overdue for patching
- Written KQL queries to pull patch state from **Azure Resource Graph** using the `patchassessmentresources` table (and understood why the legacy `UpdateSummary` table does not apply to Update Manager)
- Set up the full **Arc → Defender for Servers → Update Manager** pipeline for hybrid fleets
- Applied a **patch group tagging strategy** for large-scale scheduled patching

---

## 3. Scenario

**One unpatched server is all it takes.**

Your fleet spans Azure VMs in production and Arc-enabled on-premises servers. Security and compliance teams need a single dashboard that answers: *which machines are missing critical patches, which have a defined patching schedule, and which have never been assessed?* Update Manager provides that dashboard — and the scheduling engine to close the gap.

---

## Architecture Overview

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

---

## Part 1: Lab Walkthrough

### Step 1 — Enable and Scope Update Manager

Azure Update Manager requires no agent installation on Azure VMs (it uses the VM Agent) and no additional agent on Arc servers (it uses the Connected Machine Agent). The service is enabled at the resource level when you run an assessment or create a schedule.

### 1.1 Open Update Manager

1. In the Azure Portal, search **Azure Update Manager** → open the service.
2. The **Overview** blade shows a fleet summary: total machines, assessment status, and pending update counts grouped by severity.
3. Select your **Subscription** and **Resource Group** using the filters at the top to scope the view to your target machines.

### 1.2 Add Machines to the Scope

1. Go to **Resources** > **Machines** (left nav) — this lists all Azure VMs and Arc-enabled servers in the selected scope.
2. Confirm your target machine(s) appear in the list.
3. If a machine shows **Not assessed**, it has never had an Update Manager assessment run. That's fine — you'll fix that in Step 2.
4. Note the **Patch orchestration** column (applies to Azure VMs; Arc-enabled servers have no patch orchestration prerequisite):
   - **Azure-managed** — Azure controls patching automatically via AutomaticByPlatform (not our scope in this lab)
   - **OS-managed** — Windows Update or the Linux package manager handles patches automatically (AutomaticByOS); Update Manager scheduled deployments do not apply
   - **Customer managed schedules** — update deployments are controlled by your defined maintenance configurations; **required** for Azure VMs before scheduled patching
   - **Manual updates** — no schedule defined; updates must be triggered on-demand
   - For Arc-enabled servers, patch orchestration is not enforced — there is no prerequisite mode required to use scheduled patching

---

### Step 2 — Run an On-Demand Patch Assessment

An assessment scans the machine and surfaces available updates **without installing anything**. Always run an assessment before scheduling a deployment so you know what's pending.

1. In the **Machines** list, select one or more target machines (checkbox).
2. Click **Check for updates** at the top of the list.
3. Confirm the dialog — the assessment is submitted as an asynchronous job.
4. Refresh after 2–5 minutes. The machine's **Last assessment time** and **Pending updates** count should update.
5. Click on a machine name → go to the **Updates** tab to see the full list of pending updates, grouped by:
   - **Classification** (Critical, Security, UpdateRollup, ServicePack, etc.)
   - **KB / Package name**
   - **Severity**

### Assessment — What to Verify

- At least one machine shows a **Last assessment time** within the last few minutes
- The **Updates** tab shows a breakdown by classification — confirm Critical and Security updates are surfaced if any exist
- If a machine shows `Assessment failed`, check agent connectivity (Arc) or VM Agent status (Azure VM) — see [Troubleshooting](#troubleshooting)

---

### Step 3 — Configure a Maintenance Window

A **maintenance configuration** (maintenance window) defines **when** updates are permitted to deploy. Machines assigned to a configuration only receive scheduled deployments inside that window.

### 3.1 Create a Maintenance Configuration

1. In Azure Update Manager, go to **Maintenance configurations** (left nav) → **+ Create**.
2. Fill in:

   | Field | Example Value |
   | --- | --- |
   | Subscription | Your subscription |
   | Resource group | `rg-compute-prod` |
   | Configuration name | `mc-windows-prod-weekly` |
   | Region | Same region as target machines |
   | Maintenance scope | **Guest (Azure VM, Azure Arc-enabled VMs/servers)** — a single configuration covers both OS types |

3. On the **Schedule** tab:
   - **Start date/time:** pick a time in the near future (e.g. next Saturday 02:00 AM local)
   - **Maintenance window:** 2 hours (minimum recommended for update install + reboot)
   - **Recurrence:** Weekly on Saturday
4. On the **Updates** tab, set the **Update classifications** to include:
   - Critical Updates
   - Security Updates
   - (optional) UpdateRollup, ServicePack — add based on policy
5. Optionally set **KB/package exclusions** for any updates you need to hold back.
6. Review + **Create**.

### 3.2 Assign Machines to the Maintenance Configuration

1. Open the newly created maintenance configuration → go to **Resources** (left nav).
2. Click **+ Add a machine** → select your target Azure VMs or Arc-enabled servers.
3. Click **Add**.
4. Alternatively, use **Dynamic scope** (available on the **Dynamic scopes** tab) to assign all machines matching a subscription/resource group/tag filter — the membership auto-updates as machines are added or removed.

---

### Step 4 — Schedule and Execute an Update Deployment

With a maintenance window in place, trigger a deployment — either wait for the scheduled window or use **One-time update** for an immediate run.

### 4.1 One-Time Update (Immediate Deployment)

Use this path in the lab to validate the end-to-end flow without waiting for the weekly schedule.

1. In the **Machines** list, select target machines → click **One-time update** at the top.
2. On the **Machines** tab, confirm the selected machines.
3. On the **Updates** tab:
   - Select classifications: **Critical Updates**, **Security Updates**
   - Optionally include specific KB numbers if you only want to test with a narrow set
4. On the **Properties** tab:
   - **Reboot option:** `Reboot if required` (recommended) — Update Manager will only reboot if an update requires it; set to `Never reboot` for non-disruptive lab testing on production-adjacent machines
   - **Maximum duration:** 120 minutes (2 hours) — the portal maximum is 235 minutes; keep at 120 for lab use
5. Review + **Install** — the deployment is submitted.
6. Go to **Manage** > **History** (left nav in Update Manager) to monitor the deployment run. Refresh every 2–3 minutes.
7. When the run completes, click on the run record to see per-machine results: **Succeeded**, **Failed**, or **Not applicable**.

### 4.2 Validate Scheduled Deployment (Optional — Observe Pattern)

1. In **Maintenance configurations**, open your `mc-windows-prod-weekly` configuration.
2. Go to **History** — after the configured window passes, deployment records will appear here.
3. This confirms the scheduled flow without requiring an immediate manual trigger.

---

### Step 5 — Review Compliance and Patch History

#### 5.1 Compliance Dashboard

1. In Azure Update Manager → **Overview** — review the **Summary** panel:
   - **Compliant** machines: assessed and no critical/security updates pending
   - **Non-compliant** machines: have pending critical/security updates past the defined SLA
   - **Not assessed**: never had an Update Manager assessment
2. Use the **Compliance by resource group** chart to identify which environment (prod, dev, non-prod) has the most exposure.
3. Click a non-compliant machine → **Updates** tab → note the specific pending KBs and their severity.

#### 5.2 Patch History per Machine

1. Select a machine that had a deployment run → **Update history** tab.
2. Review:
   - Updates installed (KB/package, severity, classification)
   - Installation status (Succeeded / Failed)
   - Reboot performed (Yes/No)
3. For failed updates, note the error code — see [Troubleshooting](#troubleshooting) for common failures.

---

### Step 6 — KQL Queries for Patch State

Run these queries in **Log Analytics** (if machines send data to a workspace) or **Azure Resource Graph** (for resource-level patch metadata).

#### 6.1 Azure Resource Graph — Pending Updates by Machine

```kql
patchassessmentresources
| where type == "microsoft.compute/virtualmachines/patchassessmentresults"
    or type == "microsoft.hybridcompute/machines/patchassessmentresults"
| extend machineId = split(id, '/patchassessmentresults/')[0]
| extend assessmentTime = properties.lastModifiedDateTime
| extend pendingCritical = properties.criticalAndSecurityPatchCount
| extend pendingOther = properties.otherPatchCount
| project machineId, assessmentTime, pendingCritical, pendingOther
| order by pendingCritical desc
```

#### 6.2 Azure Resource Graph — Machines Not Assessed in 30 Days

```kql
patchassessmentresources
| where type == "microsoft.compute/virtualmachines/patchassessmentresults"
    or type == "microsoft.hybridcompute/machines/patchassessmentresults"
| extend lastAssessed = todatetime(properties.lastModifiedDateTime)
| where lastAssessed < ago(30d) or isnull(lastAssessed)
| project id, lastAssessed
```

#### 6.3 Log Analytics — UpdateSummary (Legacy Agent Path — Deprecated)

> **Note:** The `UpdateSummary` table is populated only by the legacy Microsoft Monitoring Agent (MMA/OMS). Azure Update Manager is agent-free and does **not** write to this table. Use the Resource Graph queries above (6.1, 6.2) for Update Manager data. This query applies only if the legacy MMA agent is still deployed alongside Update Manager.

```kql
UpdateSummary
| summarize arg_max(TimeGenerated, *) by Computer
| project Computer, OSType, TotalUpdatesMissing, CriticalUpdatesMissing, SecurityUpdatesMissing, LastAssessedTime
| order by CriticalUpdatesMissing desc
```

#### 6.4 Log Analytics — Arc Agent Heartbeat (Detect Disconnected Servers)

```kql
Heartbeat
| where TimeGenerated > ago(1h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer, OSType, ResourceGroup
| where LastHeartbeat < ago(15m)
| order by LastHeartbeat asc
```

---

## Part 2: Operational Workflow for Hybrid Fleets

This section extends the lab walkthrough into a production-grade monthly patching workflow for large hybrid environments (Arc-onboarded servers + Azure VMs).

### Pipeline Setup: Azure Arc → Defender for Servers → Azure Update Manager

#### Step 1 — Onboard Servers to Azure Arc

1. Follow the full onboarding flow in the [Azure Arc Hybrid Server Architecture guide](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) (Sections 3.5 and 3.6).
2. Confirm each server appears under **Azure Arc → Machines** with **Status: Connected**.
3. Apply mandatory tags at onboarding time (see [Patch Group Tagging Strategy](#patch-group-tagging-strategy) below).
4. Validate Arc extensions are healthy: **Azure Arc → Machines → [server] → Extensions**.

#### Step 2 — Enable Defender for Servers

1. In the Azure Portal, go to **Microsoft Defender for Cloud → Environment settings**.
2. Select your subscription.
3. Set **Defender for Servers** to **Plan 2** (required for vulnerability assessment and FIM).
4. Under **Settings**, turn **ON** auto-provisioning for:
   - **Defender for Endpoint (MDE)** — EDR sensor
   - **Vulnerability assessment extension** — Qualys or Defender MDVM
   - **Azure Monitor Agent (AMA)** and associated DCR
5. Click **Save**. Plan activation propagates to Arc machines within ~15 minutes.

> **Plan 2 vs Plan 1:** Use Plan 2 for Tier 1/Tier 2 production servers (full EDR + vulnerability assessment + JIT + FIM). Plan 1 is sufficient for Tier 3 / dev-test servers. Apply per resource group using Defender for Cloud’s granular plan controls to manage cost.

#### Step 3 — Verify Defender for Servers Activation

1. Open [security.microsoft.com](https://security.microsoft.com) → **Assets → Devices**.
2. Confirm Arc-onboarded servers appear in the device inventory.
3. For each server verify the following are populated:
   - **Exposure level** (Low / Medium / High / Critical)
   - **CVE count** and individual CVE listings
   - **Security recommendations** (linked to missing patches)
   - **Active alerts** (if any)
4. In the Azure Portal, go to **Defender for Cloud → Recommendations** and filter by **Vulnerabilities** — missing KBs and CVE-linked recommendations should appear here within 24 hours of plan activation.

#### Step 4 — Configure Azure Update Manager for Production Scale

For production maintenance configurations targeting patch groups, refer to [Maintenance Window Design](#maintenance-window-design) for the recommended schedule structure. The creation steps follow the same flow as [Step 3 — Configure a Maintenance Window](#step-3--configure-a-maintenance-window) in Part 1, with these additional considerations:

- **Naming convention:** use `mc-<env>-<cadence>` (e.g. `mc-prod-monthly`, `mc-dc-monthly`).
- **Tag-based machine assignment:** filter by `PatchGroup` tag rather than selecting machines individually — this keeps assignments accurate as the fleet scales.
- **Pre/Post scripts** (optional): configure Azure Automation runbooks to run before or after patching (e.g. drain load balancer, take snapshot).
- **Maintenance window duration:** set 3–4 hours for large fleets; Update Manager stops deploying to new machines if the window closes mid-run but completes in-progress machines.

---

### Monthly Patch Review Workflow

#### 1 — Review Update Compliance

1. In the Azure Portal, open **Azure Update Manager → Update compliance** (or **Overview**).
2. Review the **overall compliance percentage** across all managed machines.
3. Click into **Missing updates** to see which KBs are not yet installed across the fleet.
4. Open **Failed updates** to identify machines requiring remediation — expand each entry to see the specific error code.
5. Check the **Pending reboot** list — machines awaiting restart are not yet fully patched.
6. For any server showing anomalies, open **Azure Update Manager → History** and filter by machine name to review individual deployment run logs.

#### 2 — Review Security & CVE Exposure

1. In the Azure Portal, go to **Microsoft Defender for Cloud → Recommendations**.
2. Filter by **Vulnerabilities** or search for “System updates should be installed”.
3. Review **CVE exposure per server** — click into a recommendation to see affected resources and CVE details.
4. Check **Missing KBs mapped to CVEs** — cross-reference with the Update Manager missing updates list from Step 1.
5. Prioritize **Exploitable vulnerabilities** (flagged as actively exploited in the wild by Microsoft threat intelligence).
6. Review the **Secure Score** impact — patch-related findings typically contribute significantly to overall score.

#### 3 — Validate Patch Groups

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

#### 4 — Remediate Failed Servers

1. Open **Azure Update Manager → Failed updates** and note affected machines.
2. For each failed machine:
   - Check the **error code** in the deployment log — see [Troubleshooting](#troubleshooting) for common error codes and causes.
   - Re-run deployment: select the machine → **One-time update** → select the missing/failed KBs → **Install now**.
3. If reboot is required but was blocked: coordinate with the server owner and perform a manual reboot, then re-check compliance.
4. Validate the **Azure Arc agent health**:
   - Portal: **Azure Arc → Machines → [server] → Overview** — confirm **Status: Connected** and recent heartbeat.
   - If disconnected, re-run the onboarding script or restart the `himds` service on the server.
5. Validate the **Azure Update Manager extension** is installed: **Azure Arc → Machines → [server] → Extensions** — look for `WindowsAgent.AzureUpdateManager`.
6. Review OS-level update logs for additional diagnostics:
   - **Windows:** `C:\Windows\WindowsUpdate.log` or `Get-WindowsUpdateLog` (PowerShell)
7. If patches consistently exceed the maintenance window, extend the window duration in the maintenance configuration settings.

#### 5 — Export Monthly Reports

##### Generate Reports in Azure Update Manager

1. Open **Azure Update Manager → Update compliance**.
2. Use the **Download** or **Export** option to save a CSV of the current compliance state.
3. Apply tag filters to export per-environment reports (Prod, UAT, Dev).

##### Generate CVE Reports in Defender for Cloud

Using the **Defender for Cloud → Recommendations** view from [Section 2](#2--review-security--cve-exposure) above:

1. Click **Download** at the top of the recommendations list to export to CSV.
2. Filter by **Severity: High / Critical** to produce the high-risk server list.

##### Archive and Distribute

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

### Maintenance Window Design

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

## Troubleshooting

### Issue: Machine not appearing in Update Manager

- For **Azure VMs**: confirm the **Azure VM Agent** is installed and status is **Ready** — go to VM → **Overview** → check Agent status.
- For **Arc-enabled servers**: confirm **Status: Connected** in **Azure Arc → Machines** — disconnected agents cannot receive Update Manager instructions.
- Confirm the machine's OS is in the [supported list](#1-prerequisites).

### Issue: Assessment fails or returns stale results

- For Arc servers: verify outbound connectivity to `management.azure.com` and `*.guestconfiguration.azure.com` on port 443 from the machine.
- For Azure VMs: check that the VM Agent is not in a degraded state — restart the agent service (`WindowsAzureGuestAgent` on Windows, `waagent` on Linux).
- Assessments can take up to 15 minutes after submitting — wait before concluding failure.

### Issue: Update deployment shows "Failed" for a machine

- Click the failed run record → expand the machine → note the **Error code**.
- Common error codes: `0x8024200D` = download failure, `0x80070005` = permissions error, `WU_E_NO_SERVICE` = Windows Update service stopped.
- Common causes:
  - **Reboot pending from a previous update** — a prior update required a reboot that hasn't happened; reboot the machine and re-trigger.
  - **Windows Update service disabled** — re-enable `wuauserv` on the machine.
  - **Insufficient disk space** — update packages require temporary disk space during extraction; free up at least 2 GB.
  - **Windows Update catalog endpoint blocked** — confirm `download.microsoft.com` and `windowsupdate.microsoft.com` are reachable on port 443.

### Issue: Dynamic scope not picking up new machines

- Dynamic scopes are evaluated at deployment time, not real-time — a machine added to a resource group after a deployment was scheduled may not be included in that run. It will be included in the next scheduled window.
- Confirm the resource group / subscription / tag filters in the dynamic scope match the machine's actual values.

### Issue: Arc machine shows "No updates available" immediately after onboarding

- The first assessment after onboarding may return zero results if the machine's local update cache hasn't been refreshed. Run `usoclient StartScan` (Windows Server 2016+ / Windows 10+) or `wuauclt /detectnow` (Windows Server 2012 R2 only), or `apt-get update` / `yum check-update` (Linux) inside the machine, then re-run the assessment from Update Manager.

---

## Why Update Manager Matters (Engineering Justification)

- **Single pane of glass** — Azure VMs and Arc-enabled on-premises/multi-cloud servers are visible in one dashboard; no separate patching toolchain per environment
- **Agent-free for Azure VMs** — uses the VM Agent already present; no extra agent to deploy or maintain
- **Change-controlled patching** — maintenance windows integrate with change management; updates cannot be deployed outside the defined window
- **Compliance auditability** — every assessment and deployment is logged; compliance reports are available for audit without manual aggregation
- **Dynamic scoping** — target by subscription, resource group, or tag; the fleet membership stays accurate automatically as machines are added or retired
- **Replaces legacy solution** — the Log Analytics Update Management solution was retired; Update Manager is the current supported path

---

## Checklist

1. **Arc onboarding complete** — all target servers show **Status: Connected** in **Azure Arc → Machines** with correct tags applied ([Pipeline Setup](#pipeline-setup-azure-arc--defender-for-servers--azure-update-manager)).
2. **Tagging validated** — `PatchGroup`, `Environment`, `Criticality` tags present and accurate on all Arc machines ([Patch Group Tagging Strategy](#patch-group-tagging-strategy)).
3. **Defender for Servers Plan 2 enabled** — subscription-level plan active; MDE and vulnerability assessment auto-provisioned ([Step 2 — Enable Defender for Servers](#step-2--enable-defender-for-servers)).
4. **Defender inventory confirmed** — servers visible in [security.microsoft.com](https://security.microsoft.com) with exposure levels and CVE data populated ([Step 3 — Verify Defender for Servers Activation](#step-3--verify-defender-for-servers-activation)).
5. **Maintenance configurations created** — separate schedules per patch group; window durations, reboot settings, and update classifications configured ([Maintenance Window Design](#maintenance-window-design)).
6. **Machines assigned to schedules** — all Arc machines and VMs assigned to the correct maintenance configuration via tag-based selection.
7. **First compliance baseline captured** — Update Manager assessment run completed; export and archive initial compliance state.
8. **Monthly review process documented** — team knows which portal views to check, which KQL queries to run, and who receives which reports ([Monthly Patch Review Workflow](#monthly-patch-review-workflow)).
9. **DC patching procedure confirmed** — staggered reboot runbook or manual procedure documented and tested ([Maintenance Window Design](#maintenance-window-design)).
10. **Report archive location established** — compliance and CVE reports stored with 12-month retention for audit evidence ([5 — Export Monthly Reports](#5--export-monthly-reports)).

---

## Cleanup

### Remove Machine from Maintenance Configuration

1. In **Maintenance configurations**, open your configuration → **Resources** tab.
2. Select the machine(s) → **Remove from scope**.
3. The machine will no longer receive scheduled deployments from this configuration.

### Delete the Maintenance Configuration

1. In **Maintenance configurations**, select the configuration → **Delete**.
2. Confirm deletion. This does not uninstall any updates or affect machine state — it only removes the scheduling definition.

### Verify No Scheduled Deployments Remain

1. Return to the **Machines** list → confirm **Patch orchestration** column shows **Manual updates** (or your baseline state) for the decommissioned machines.
2. Check **History** to confirm no pending deployments are queued.

---

[← Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
