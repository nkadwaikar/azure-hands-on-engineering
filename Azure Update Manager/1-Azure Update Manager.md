# Azure Update Manager — Patch Orchestration & Operational Guide

> **Why this matters:** Unpatched systems are the most exploited attack surface in enterprise environments. Azure Update Manager provides a single, agent-free control plane for assessing and deploying OS updates across Azure VMs, Arc-enabled on-premises servers, and multi-cloud machines. Combined with Azure Arc and Defender for Servers, it turns patching into a measurable, auditable, and automatable operation that scales from 10 to 10,000 servers — without routing telemetry through Log Analytics as a dependency.

Last validated on: 2026-07-10
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
  - [Step 2 — Enable Periodic Assessment and Run an On-Demand Assessment](#step-2--enable-periodic-assessment-and-run-an-on-demand-assessment)
  - [Step 3 — Configure a Maintenance Window](#step-3--configure-a-maintenance-window)
  - [Step 4 — Schedule and Execute an Update Deployment](#step-4--schedule-and-execute-an-update-deployment)
  - [Step 5 — Review Compliance and Patch History](#step-5--review-compliance-and-patch-history)
  - [Step 6 — KQL Queries for Patch State](#step-6--kql-queries-for-patch-state)
- [Part 2: Operational Workflow for Hybrid Fleets](#part-2-operational-workflow-for-hybrid-fleets)
  - [Pipeline Setup: Azure Arc → Defender for Servers → Azure Update Manager](#pipeline-setup-azure-arc--defender-for-servers--azure-update-manager)
  - [Patch Group Tagging Strategy](#patch-group-tagging-strategy)
  - [Maintenance Window Design](#maintenance-window-design)
  - [Hotpatching on Arc-Enabled Servers](#hotpatching-on-arc-enabled-servers)
  - [Pricing & Licensing](#pricing--licensing)
  - [Staged / Ring-Based Patching (Known Limitation)](#staged--ring-based-patching-known-limitation)
  - [Monthly Patch Review Workflow](#monthly-patch-review-workflow)
- [Troubleshooting](#troubleshooting)
- [Why Update Manager Matters](#why-update-manager-matters-engineering-justification)
- [Part 3: Operational Runbooks](#part-3-operational-runbooks)
  - [1. Monitor Patch Run (22:00 PT)](#1-monitor-tonights-patch-run-2200-pt)
  - [2. Validate Logs After the Run](#2-validate-logs-after-the-run)
  - [3. Prod vs Non-Prod Patching Strategy](#3-prod-vs-non-prod-patching-strategy)
  - [4. Alerting for Arc Agent Disconnects](#4-alerting-for-arc-agent-disconnects)
  - [Standardized Maintenance Configuration (Recommended)](#standardized-maintenance-configuration-recommended)
  - [Maintenance Configuration — Option by Option Explained](#maintenance-configuration--option-by-option-explained)
- [Checklist](#checklist)
- [Cleanup](#cleanup)
- [Update Log](#update-log)

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

Naming reference: use your organization's internal naming convention document for resource group, maintenance configuration, and tag naming.

### Assumptions and Scope Boundaries

- Lab uses the Azure Portal Update Manager blade; PowerShell and REST API paths exist but are out of scope.
- Automatic VM Guest Patching (cloud-init / Windows Automatic Updates) on Azure VMs is separate from Update Manager scheduling — if already enabled, Update Manager coexists but scheduled deployments take precedence during the defined window.
- Arc-enabled servers must have outbound HTTPS (port 443) connectivity to Azure endpoints — connectivity validated in the Arc track.

---

## 2. Learning Objectives

By the end of this guide, you will have:

- Explored the **Azure Update Manager** blade and understood fleet-level patch posture at a glance
- Enabled **periodic assessment** on Arc-enabled servers and Azure VMs to keep compliance data current
- Run an **on-demand patch assessment** to surface available updates without installing anything
- Created a **maintenance window** and understood how it gates when updates are permitted
- Scheduled and executed an **update deployment** with classification and exclusion filters
- Reviewed **compliance reporting** and identified machines overdue for patching
- Written KQL queries to pull patch state from **Azure Resource Graph** using the `patchassessmentresources` table (and understood why the legacy `UpdateSummary` table does not apply to Update Manager)
- Set up the full **Arc → Defender for Servers → Update Manager** pipeline for hybrid fleets
- Applied a **patch group tagging strategy** for large-scale scheduled patching
- Understood current pricing for Arc-enabled servers and where hotpatching now applies at no additional cost

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
              │     ├─ Patch Assessment (on-demand or periodic/24h)
              │     ├─ Scheduled Deployments
              │     ├─ Hotpatching (Arc-enabled Windows Server 2025)
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
4. Note the **Patch orchestration** column (applies to Azure VMs; Arc-enabled servers have no patch orchestration prerequisite). Current options are:
   - **Customer Managed Schedules** — update deployments are controlled by your defined maintenance configurations; **required** for Azure VMs before scheduled patching
   - **Azure Managed – Safe Deployment** — Azure controls patching automatically and rolls updates out in waves across regions
   - **Windows automatic updates** — Windows Update handles patching automatically on the guest OS; Update Manager scheduled deployments do not apply
   - **Image Default** — Linux-only; the distro's own package-manager defaults control patch behavior
   - **Manual updates** — no schedule defined; updates must be triggered on-demand
   - For Arc-enabled servers, patch orchestration is not enforced — there is no prerequisite mode required to use scheduled patching

---

### Step 2 — Enable Periodic Assessment and Run an On-Demand Assessment

Periodic assessment runs automatic update scans every 24 hours, keeping compliance data fresh and the **Pending updates** view accurate — instead of relying solely on manually triggered checks.

### 2.1 Enable Periodic Assessment

1. In **Azure Update Manager → Machines**, look for the periodic assessment status column, or open a specific machine → **Updates** → **Change periodic assessment**.
2. Select the machine(s) that are not yet enabled and set periodic assessment to **On**.
3. At scale: apply the built-in **Azure Policy** initiative for periodic assessment across a subscription or management group so new machines are enrolled automatically as they're created or onboarded.
4. Confirm each machine shows **Periodic assessment: Enabled** in the **Machines** list.

> Periodic assessment is a prerequisite for the Defender for Cloud recommendation *"Periodic assessment should be enabled on your machines"* to show healthy.
> **Arc-enabled servers:** periodic assessment and on-demand/scheduled patch installation are handled by **two separate extensions** that are both expected to be present and healthy — this is normal, not a misconfiguration:
> - `Microsoft.CPlat.Core.WindowsPatchExtension` — handles assessment and compliance-state reporting.
> - `Microsoft.SoftwareUpdateManagement.WindowsOsUpdateExtension` — handles update installation for one-time and scheduled deployments.
>
> Confirm both extensions are present and healthy under **Azure Arc → Machines → [server] → Extensions** before enabling periodic assessment at scale.

### 2.2 Run an On-Demand Patch Assessment

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
- **Periodic assessment: Enabled** is visible for machines you enrolled in Step 2.1
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
   - **Compliant machines**: assessed and no critical/security updates pending
   - **Non-compliant machines**: have pending critical/security updates past the defined SLA
   - **Not assessed**: never had an Update Manager assessment
   - Use the **Compliance by resource group** chart to identify which environment (prod, dev, non-prod) has the most exposure.
2. In Azure Update Manager → **Machines**, the list also shows per-machine compliance at a glance:
   - **Pending updates** count (e.g. *6*)
   - **Pending reboot** count (should be *0* after a completed patch run)
   - **Arc status** (should be *Connected* for all managed servers)
   - **Associated schedules** (e.g. *1 — mc-windows-weekly-standard*)
   - **Periodic assessment** (should be *Enabled* for all machines)
3. Use the **Tag** filter on the Machines view to scope by environment:
   - Filter `Environment = Prod` → confirm **0 pending updates** (or documented exceptions).
   - Filter `Environment = NonProd` → pending updates are expected between patch cycles.
4. Click a non-compliant machine → **Updates** tab → note the specific pending KBs and their severity.

> The Update Manager reporting experience provides dedicated views for overall compliance, recommendations, pending updates, update history, schedules, and operation history — use these instead of building custom workbooks for routine reviews.

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

### Patch Group Tagging Strategy

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

### Hotpatching on Arc-Enabled Servers

Hotpatching installs security updates without requiring a reboot, reducing scheduled restarts on eligible Windows Server workloads from roughly monthly (12/year) to quarterly baseline reboots (4/year).

- **Eligibility:** Windows Server 2025 Standard or Datacenter, Arc-enabled, with Virtualization Based Security (VBS) enabled. (Windows Server Datacenter: Azure Edition has supported hotpatching for years and is unaffected by the licensing changes below.)
- **Cost:** Hotpatching on Arc-enabled Windows Server 2025 machines was a paid preview at $1.50 per CPU core per month; as of **May 19, 2026**, it is available at **no additional cost** — no per-core meter, no hourly charge, and no separate line item on the invoice. Servers previously enrolled in the paid preview stop being billed automatically; no action is required to keep receiving hotpatches.
- **Enabling it:** Azure Update Manager → **Machines** → select the Arc-enabled server → **Recommended updates** → **Hotpatch** → **Change** → **Receive monthly Hotpatch updates** → **Confirm**. To enable at scale, use **Machines** → **Update settings** → **+Add machine** → set the **Hotpatch** dropdown to **Enable** → **Save**.
- **Monitoring:** add the **Hotpatch status** column to the Machines grid (**Edit columns** → **Hotpatch status**) to see enrollment and patch state across Azure and Arc-enabled machines in one view.
- Hotpatches only carry security fixes (not feature or reliability fixes), so a baseline Latest Cumulative Update is still applied quarterly to deliver the rest of the payload — this is what drives the 4/year reboot cadence rather than zero reboots.

---

### Pricing & Licensing

- **Azure VMs:** Update Manager is included at no additional charge.
- **Arc-enabled servers:** billed per server, prorated daily (based on a 31-day month), for any day the server is both Connected and has an update operation triggered on it or is associated with an active schedule.
- **No-charge scenarios for Arc-enabled servers:** the server is Arc-enabled Azure Local, has Extended Security Updates (ESUs) enabled by Azure Arc, or the hosting subscription has **Defender for Servers Plan 2** enabled (in that case Update Manager and Azure Policy guest configuration are bundled in).
- Servers already using Automation Update Management for free as of September 1, 2023 keep that free status in the same subscription until the legacy Log Analytics agent is retired; any new Arc onboarding is billed under current pricing.
- Confirm current per-server pricing and any regional variance directly on the Azure Update Manager pricing page before budgeting, since rates are subject to change.

---

### Staged / Ring-Based Patching (Known Limitation)

Update Manager does **not** include a built-in feature for staged (ring-based) rollout — there's no native way to guarantee that only the exact patch versions validated in a test ring are the ones applied in pre-production and production. Where that guarantee matters (e.g. regulated environments), the current workaround is to drive Update Manager through an **Azure Automation runbook** (PowerShell + Azure Resource Graph) that stages machines into resource groups or tags per ring and gates promotion between rings on the previous ring's results. Treat the "staged rollout" language in [Prod vs Non-Prod Patching Strategy](#3-prod-vs-non-prod-patching-strategy) as a deliberate addition you build on top of the maintenance-configuration model in this guide, not as something Update Manager enforces for you.

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
5. Validate the **Azure Update Manager extensions** are installed: **Azure Arc → Machines → [server] → Extensions** — look for both `WindowsPatchExtension` (assessment) and `WindowsOsUpdateExtension` (installation); both should show **Succeeded**.
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

## Part 3: Operational Runbooks

### 1. Monitor Tonight's Patch Run (22:00 PT)

To properly monitor the run, these steps must happen:

#### Track the Maintenance Configuration Execution

1. In the Azure Portal, open **Azure Update Manager → History** at 22:00 PT.
2. Confirm a new deployment run record appears for the maintenance configuration scheduled for 22:00 PT.
3. Click the run record to open the per-machine execution detail view.

#### Watch the WindowsOsUpdateExtension Activity ID

1. In **Azure Arc → Machines → [server] → Extensions**, note the `WindowsOsUpdateExtension` version and status — this is the extension that executes the install; `WindowsPatchExtension` runs alongside it for assessment. Confirm status is **Succeeded** (or **Transitioning** while a run is in progress).
2. In the deployment run record, copy the **Activity ID** for the extension invocation — use this to correlate portal events with on-machine logs.

#### Capture Key Milestones

| Milestone | Where to Observe |
| --- | --- |
| Assessment start time | Deployment run record → **Start time** field |
| Patch download start | Extension log: `C:\Packages\Plugins\Microsoft.SoftwareUpdateManagement.WindowsOsUpdateExtension\Logs` |
| Patch installation progress | Azure Update Manager → History → run record → per-machine status updates |
| Reboot trigger | Extension log entries containing `Reboot` or `RestartRequired` |
| Reboot completion | Machine heartbeat resumes in Arc portal; extension status returns to **Succeeded** |
| Extension finalization | Extension status changes from **Transitioning** → **Succeeded** or **Failed** |

#### Detect Issues During the Run

| Issue | Detection Method |
| --- | --- |
| **Timeouts** | Run record duration exceeds the configured window; machines show **Timed out** status |
| **Failures** | Per-machine status shows **Failed**; expand to see the error code |
| **Maintenance window overruns** | Run start + duration > window end time; remaining machines are skipped |
| **Arc agent disconnects during patching** | Arc portal shows **Status: Disconnected**; heartbeat gap in Log Analytics |

#### Confirm Run Completion

- Verify the deployment run record shows a completed status before **01:55 AM PT**.
- Confirm no machines remain in **In progress** state after 01:55 AM PT.
- If the window closes with machines still in progress, those machines will not be retried until the next scheduled window — remediate manually using **One-time update**.

> **Goal:** Know exactly what happened during the patch window — no surprises discovered in the morning.

---

### 2. Validate Logs After the Run

After the patch window ends, collect and analyze the following log sources to build a complete post-patching health report.

#### Arc Agent Logs

**Path:** `C:\ProgramData\AzureConnectedMachineAgent\Log\himds.log`

Check for:

- Heartbeat drops (gaps > 5 minutes indicate connectivity loss)
- Service restarts (`himds` service stop/start entries)
- Connectivity failures (failed connections to `management.azure.com`)
- TLS handshake issues (certificate validation errors)

```powershell
# Scan himds.log for errors during the patch window
Get-Content 'C:\ProgramData\AzureConnectedMachineAgent\Log\himds.log' |
  Where-Object { $_ -match 'error|fail|disconnect|restart' } |
  Select-Object -Last 100
```

#### Update Extension Logs

**Path:** `C:\Packages\Plugins\Microsoft.SoftwareUpdateManagement.WindowsOsUpdateExtension\Logs`

Check for:

- Patch installation success/failure per KB
- Reboot status (`RebootRequired`, `RebootCompleted`)
- Maintenance window exceeded warnings
- Error codes (cross-reference with [Troubleshooting](#troubleshooting))
- Activity ID results matching the run record from the portal

```powershell
# List log files sorted by last write time
Get-ChildItem 'C:\Packages\Plugins\Microsoft.SoftwareUpdateManagement.WindowsOsUpdateExtension\Logs' |
  Sort-Object LastWriteTime -Descending |
  Select-Object Name, LastWriteTime, Length
```

#### Windows Update Logs

**Path:** `C:\Windows\WindowsUpdate.log`

> On Windows Server 2016+, this file is encoded. Generate a readable version with:

```powershell
Get-WindowsUpdateLog -LogPath 'C:\Temp\WindowsUpdate-readable.log'
```

Check for:

- Download failures (search for `FAILED` or `error`)
- Install failures (search for `Installation Failure`)
- Pending reboot flags (search for `reboot required`)

#### Compliance Results

Azure Portal → **Azure Update Manager → Update compliance**

| View | What to Confirm |
| --- | --- |
| **Installed patches** | Count matches expected KBs from the deployment run |
| **Failed patches** | Zero failed patches, or documented and remediated |
| **Pending patches** | Only approved exclusions remain pending |
| **Reboot required** | All machines have completed reboot; none stuck in pending reboot state |

---

### 3. Prod vs Non-Prod Patching Strategy

A proper enterprise patching strategy separates production and non-production environments to catch patch regressions before they reach production systems.

#### Production

| Setting | Value |
| --- | --- |
| **Cadence** | Weekly (or monthly for stable environments) |
| **Day/Time** | Sunday night or Friday night |
| **Window Duration** | 3–4 hours |
| **Reboot** | Allowed (reboot if required) |
| **Update Classifications** | Security, Critical, Update Rollup |
| **Pre/Post Scripts** | Azure Automation runbooks: drain load balancer before patching, validate services after |
| **Staged rollout** | Non-prod → UAT → Prod; Domain Controllers patched last, one at a time (built via the Automation-runbook approach in [Staged / Ring-Based Patching](#staged--ring-based-patching-known-limitation) — not natively enforced by Update Manager) |

#### Non-Production

| Setting | Value |
| --- | --- |
| **Cadence** | Weekly or twice-weekly |
| **Day/Time** | Earlier windows (e.g. weeknight) |
| **Window Duration** | 2–3 hours |
| **Reboot** | Always allowed |
| **Update Classifications** | Security, Critical, Update Rollup, Definition, and optionally Optional updates |
| **Purpose** | Validate patch stability before promoting to Prod; catch regressions early |

#### Tagging Model

Maintenance configurations auto-assign machines based on tags — no manual membership management required.

| Tag | Prod Value | Non-Prod Value |
| --- | --- | --- |
| `Environment` | `Prod` | `NonProd` |
| `PatchGroup` | `Prod` | `Dev` / `UAT` |

**Dynamic scope filter example (Prod):**

- Tag key: `Environment`
- Tag value: `Prod`

**Dynamic scope filter example (Non-Prod):**

- Tag key: `Environment`
- Tag value: `NonProd`

> Machines automatically enter or exit the correct maintenance configuration as their tags are updated — no manual reassignment needed.

---

### 4. Alerting for Arc Agent Disconnects

Arc agent disconnects block Update Manager from delivering patches. Detect them proactively with Azure Monitor alerts.

#### Azure Monitor Alert Rules

Create the following alert rules in **Azure Monitor → Alerts → + Create → Alert rule**:

| Alert | Signal Type | Condition | Severity |
| --- | --- | --- | --- |
| **Arc Agent Heartbeat Missing** | Log (Heartbeat table) | No heartbeat in last 15 min | Sev 1 |
| **Arc Machine Disconnected** | Resource health | Arc machine status = Disconnected | Sev 1 |
| **Guest Configuration Non-compliant** | Azure Policy compliance | Non-compliant assignment | Sev 2 |
| **Extension Failure** | Activity Log | Extension provisioning state = Failed | Sev 2 |

#### Log Analytics KQL Alerts

##### Heartbeat Missing (>15 Minutes)

```kql
Heartbeat
| summarize LastHeartbeat = max(TimeGenerated) by Computer, ResourceGroup
| where LastHeartbeat < ago(15m)
| project Computer, ResourceGroup, LastHeartbeat, MinutesSilent = datetime_diff('minute', now(), LastHeartbeat)
| order by MinutesSilent desc
```

##### Arc Agent Disconnect for Specific Machine

```kql
Heartbeat
| where Computer == "WIN-CE1COEMM5PE"
| where TimeGenerated > ago(5m)
```

> If this query returns zero rows, the agent is disconnected or not sending heartbeats.

##### Extension Failures (Last 24 Hours)

```kql
AzureActivity
| where OperationNameValue has "extensions/write"
| where ActivityStatusValue == "Failure"
| where TimeGenerated > ago(24h)
| project TimeGenerated, ResourceGroup, Resource, Properties
| order by TimeGenerated desc
```

#### Notification Channels

1. In **Azure Monitor → Alerts → Action groups**, create an action group with:
   - **Email** notifications to the infrastructure on-call distribution list
   - **Microsoft Teams** webhook for the patching operations channel (via Logic App or Teams incoming webhook)
2. Assign the action group to each alert rule created above.
3. Test alerts by running the KQL queries manually in Log Analytics and confirming they return expected results before relying on them for production.

---

### Standardized Maintenance Configuration (Recommended)

Use this configuration as the baseline template for all new maintenance configurations.

| Setting | Value |
| --- | --- |
| **Frequency** | Monthly |
| **Day** | Sunday (adjust per team schedule) |
| **Start Time** | 23:00 PT (11:00 PM) (adjust per team schedule) |
| **Duration** | 3 hours 55 minutes (adjust per team schedule) |
| **Reboot** | Allowed inside window |
| **Patch Source** | Windows Update |
| **Classifications** | Security, Critical, Update Rollup, Definition |
| **Assignments** | All Arc-enabled Windows Servers — Prod and Non-Prod separated by `Environment` tag via dynamic scope |

#### Configuration Notes

- **Duration:** 3 hours 55 minutes keeps the window under 4 hours, which is the recommended ceiling for most fleets. Machines still in progress when the window closes will complete their current patch but no new patches will be started.
- **Reboot inside window:** Ensures reboots happen during the approved change window, not after business hours the next day.
- **Tag-based assignment:** Use the `PatchGroup` tag with dynamic scoping — manually assigning machines does not scale and leads to coverage gaps as the fleet changes.
- **Definition updates:** Including Definition (antimalware signature) updates ensures Defender signatures stay current on every patching cycle without a separate schedule.
- **Hotpatch-eligible machines:** for Arc-enabled Windows Server 2025 machines enrolled in hotpatching, most monthly security fixes install without a reboot inside this same window — see [Hotpatching on Arc-Enabled Servers](#hotpatching-on-arc-enabled-servers).

---

### Maintenance Configuration — Option by Option Explained

Every setting inside an Azure Update Manager Maintenance Configuration is explained below. Each entry covers what the option does and how it affects patching on Arc-enabled Windows Servers.

#### 1. Schedule Enabled

Activates or deactivates the maintenance configuration.

- **Enabled** — patching runs according to the defined schedule.
- **Disabled** — no patching occurs; the configuration is preserved for future use.

#### 2. Start Time

The exact clock time at which Azure Update Manager begins the patching workflow. At this moment Azure will:

1. Start the patch assessment
2. Begin downloading updates
3. Start installing updates
4. Trigger a reboot if required

Example: `22:00 PT` — patching begins at 10:00 PM Pacific Time.

#### 3. Repeats

Defines how often the schedule fires.

| Option | Behavior |
| --- | --- |
| Every day | Runs daily at the configured start time |
| Every week | Runs once per week |
| On [day] every week | Runs on a specific weekday each week (e.g. every Friday) |
| Monthly | Runs once per month on the configured day |

Example: **On Friday every week** → patching runs every Friday at 22:00 PT.

#### 4. Ends On

Defines when the recurring schedule stops.

| Option | Behavior |
| --- | --- |
| No end date | Schedule runs indefinitely |
| Specific date | Schedule stops after the configured date; no further deployments are triggered |

#### 5. Maintenance Window

The **maximum allowed duration** for the entire patching operation. The window covers:

- Assessment
- Update download
- Update installation
- Reboot (if required)
- Post-reboot patching
- Extension finalization

If patching does not finish within this window, Azure stops starting new patch operations. Machines already mid-install complete their current update, but no new packages are started.

> **Why this matters:** Exceeding the maintenance window produces `maintenanceWindowExceeded: true` and `InstallationOfAnUpdateWasInterruptedDueToTimeExpired` errors in the extension logs. A window of **3 hours 55 minutes** provides sufficient headroom for most Windows Server workloads.

#### 6. Next Maintenance Times

Azure pre-calculates and displays the next upcoming patch run timestamps based on the configured schedule. Use this to confirm the schedule is active and correctly set before the window opens.

Example output:

```
Fri Jul 17 2026 22:00
Fri Jul 24 2026 22:00
Fri Jul 31 2026 22:00
```

#### 7. Reboot Options

Controls when (or whether) Azure is permitted to reboot the machine after installing updates.

| Option | Behavior | Recommendation |
| --- | --- | --- |
| **Reboot if required** | Reboots only when an update requires it | Recommended for most servers |
| **Always reboot** | Reboots after every patching run regardless of need | Use when you want a guaranteed clean state |
| **Never reboot** | No reboot is triggered by Update Manager | For Domain Controllers with staggered manual reboots only |
| **Reboot inside maintenance window** | Reboot must complete before the window closes | Required to avoid out-of-window reboots |

> If extension logs show `rebootNeeded: true` and `rebootStatus: Required`, reboot must be permitted inside the window or patching will report as incomplete.

#### 8. Patch Classifications

Defines which categories of updates are installed during the patching run.

| Classification | Include? | Reason |
| --- | --- | --- |
| **Security** | ✔ Yes | Closes CVEs and exploitable vulnerabilities |
| **Critical** | ✔ Yes | Stability and reliability fixes |
| **Update Rollup** | ✔ Yes | Cumulative bundles; required for full KB coverage |
| **Definition** | ✔ Yes | Keeps Defender antimalware signatures current |
| Feature Packs | ✗ No | Adds new OS features; high reboot risk, requires testing |
| Service Packs | ✗ No | Major OS-level changes; deploy intentionally, not automatically |
| Tools | ✗ No | Utility updates; rarely security-relevant |
| Optional | ✗ No | Not validated for automated deployment |

#### 9. Patch Source

Defines where the machine retrieves update packages.

| Option | When to Use |
| --- | --- |
| **Windows Update (WU)** | Direct internet access to Microsoft endpoints — correct for most Arc-enabled servers |
| **Windows Server Update Services (WSUS)** | On-premises WSUS server manages update approvals and distribution |
| **Microsoft Update** | Includes updates for Microsoft products (SQL, Office, etc.) in addition to OS updates |

Arc-enabled server extension logs confirm the active source:

```
patchServiceUsed: WU
```

#### 10. Assignments

Defines which machines receive this maintenance configuration.

| Assignment Method | How It Works | Recommendation |
| --- | --- | --- |
| **Individual machines** | Machines selected by name | Use only for one-off exceptions |
| **Resource group** | All machines in the specified RG | Suitable for small, static environments |
| **Tags (dynamic scope)** | Machines with matching tag key/value are auto-included | Recommended for all production fleets |

Recommended tag-based assignment:

| Tag Key | Tag Value | Scope |
| --- | --- | --- |
| `Environment` | `Prod` | Production maintenance configuration |
| `Environment` | `NonProd` | Non-production maintenance configuration |
| `PatchGroup` | `DC` | Domain Controller maintenance configuration |

> Dynamic scope membership updates automatically as machines are added or retired — no manual reassignment required.

#### Quick Reference Summary

| Option | What It Controls |
| --- | --- |
| Schedule Enabled | Patching is active or paused |
| Start Time | When patching begins |
| Repeats | How often patching runs |
| Ends On | When the schedule stops |
| Maintenance Window | Maximum allowed patching duration |
| Next Maintenance Times | Upcoming scheduled run timestamps |
| Reboot Options | Controls reboot behavior and timing |
| Patch Classifications | Which update types are installed |
| Patch Source | Where update packages are retrieved from |
| Assignments | Which servers receive this schedule |

---

## Checklist

1. **Arc onboarding complete** — all target servers show **Status: Connected** in **Azure Arc → Machines** with correct tags applied ([Pipeline Setup](#pipeline-setup-azure-arc--defender-for-servers--azure-update-manager)).
2. **Periodic assessment enabled** — all machines show **Periodic assessment: Enabled** in Azure Update Manager → Machines ([Step 2 — Enable Periodic Assessment](#step-2--enable-periodic-assessment-and-run-an-on-demand-assessment)).
3. **Tagging validated** — `PatchGroup`, `Environment`, `Criticality` tags present and accurate on all Arc machines ([Patch Group Tagging Strategy](#patch-group-tagging-strategy)).
4. **Defender for Servers Plan 2 enabled** — subscription-level plan active; MDE and vulnerability assessment auto-provisioned ([Step 2 — Enable Defender for Servers](#step-2--enable-defender-for-servers)).
5. **Defender inventory confirmed** — servers visible in [security.microsoft.com](https://security.microsoft.com) with exposure levels and CVE data populated ([Step 3 — Verify Defender for Servers Activation](#step-3--verify-defender-for-servers-activation)).
6. **Maintenance configurations created** — separate schedules per patch group; window durations, reboot settings, and update classifications configured ([Maintenance Window Design](#maintenance-window-design)).
7. **Machines assigned to schedules** — all Arc machines and VMs assigned to the correct maintenance configuration via tag-based selection.
8. **Hotpatch eligibility reviewed** — eligible Windows Server 2025 Arc machines enrolled where reboot reduction is a priority ([Hotpatching on Arc-Enabled Servers](#hotpatching-on-arc-enabled-servers)).
9. **First compliance baseline captured** — Update Manager assessment run completed; export and archive initial compliance state.
10. **Monthly review process documented** — team knows which portal views to check, which KQL queries to run, and who receives which reports ([Monthly Patch Review Workflow](#monthly-patch-review-workflow)).
11. **DC patching procedure confirmed** — staggered reboot runbook or manual procedure documented and tested ([Maintenance Window Design](#maintenance-window-design)).
12. **Report archive location established** — compliance and CVE reports stored with 12-month retention for audit evidence ([5 — Export Monthly Reports](#5--export-monthly-reports)).

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

[← Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) | [→ Advanced Topics](2-Azure%20Update%20Advance%20Topics.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
