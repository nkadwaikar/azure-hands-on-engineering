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
├── 1-Azure Update Manager.md          ← Lab Guide: overview, architecture, lab walkthrough (you are here)
├── 2-Azure Update Advance Topics.md   ← Advanced: pre/post scripts, rollback, workbooks, Bicep
├── 3-operational-workflow.md          ← Hybrid fleet pipeline, tagging, maintenance windows, monthly review
└── 4-operational-runbooks.md          ← Runbooks: monitor runs, log validation, alerting, config reference
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
- [Checklist](#checklist)
- [Cleanup](#cleanup)
- [Update Log](#update-log)

**Continue to:**
- [Operational Workflow for Hybrid Fleets →](3-operational-workflow.md)
- [Operational Runbooks →](4-operational-runbooks.md)
- [Advanced Topics →](2-Azure%20Update%20Advance%20Topics.md)

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

### Additional Permissions for Hybrid Fleets (Required for 3-operational-workflow.md)

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
- If a machine shows `Assessment failed`, check agent connectivity (Arc) or VM Agent status (Azure VM) — see [Troubleshooting](3-operational-workflow.md#troubleshooting)

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
3. For failed updates, note the error code — see [Troubleshooting](3-operational-workflow.md#troubleshooting) for common failures.

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

> **Next:** [Operational Workflow for Hybrid Fleets →](3-operational-workflow.md) — continue to the production pipeline setup, tagging strategy, maintenance window design, and monthly review workflow.

---

## Checklist

Use this to confirm the Part 1 lab is complete before moving on to [Operational Workflow for Hybrid Fleets](3-operational-workflow.md). A comprehensive fleet-readiness checklist (Arc onboarding, tagging, Defender Plan 2, hotpatch enrollment, monthly review process, DC procedure, report archiving) lives in that document instead, since those steps span the pipeline covered there.

1. **Patch orchestration reviewed** — target machines show the correct **Patch orchestration** mode in the Machines list, or Arc-enabled servers confirmed to have no orchestration prerequisite ([Step 1](#step-1--enable-and-scope-update-manager)).
2. **Periodic assessment enabled** — target machine(s) show **Periodic assessment: Enabled** ([Step 2 — Enable Periodic Assessment](#step-2--enable-periodic-assessment-and-run-an-on-demand-assessment)).
3. **On-demand assessment completed** — at least one machine shows a recent **Last assessment time** and a populated **Updates** tab ([Step 2.2](#22-run-an-on-demand-patch-assessment)).
4. **Maintenance configuration created** — schedule, window duration, and update classifications configured ([Step 3](#step-3--configure-a-maintenance-window)).
5. **Machines assigned** — target machine(s) linked to the maintenance configuration, via direct assignment or dynamic scope ([Step 3.2](#32-assign-machines-to-the-maintenance-configuration)).
6. **Deployment executed and reviewed** — a one-time or scheduled update deployment ran to completion, and per-machine results (Succeeded/Failed/Not applicable) were reviewed in **History** ([Step 4](#step-4--schedule-and-execute-an-update-deployment)).
7. **Compliance dashboard reviewed** — Overview and Machines views checked for compliant/non-compliant/not-assessed counts ([Step 5](#step-5--review-compliance-and-patch-history)).
8. **KQL queries validated** — Resource Graph queries against `patchassessmentresources` return expected results for your subscription ([Step 6](#step-6--kql-queries-for-patch-state)).

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

## Update Log

### 2026-07-10 revision (this file)

- **Reorganized this document to match the 4-file track split.** The Table of Contents and "Continue to" links had already been updated to point to `3-operational-workflow.md` and `4-operational-runbooks.md`, but the underlying body content had not actually been removed — roughly 640 lines of Pipeline Setup, Patch Group Tagging, Maintenance Window Design, Hotpatching, Pricing & Licensing, Staged Patching, Monthly Patch Review, Troubleshooting, "Why Update Manager Matters," and all of Part 3 (Operational Runbooks, Standardized Maintenance Configuration, Maintenance Configuration Option-by-Option) were duplicated here as orphaned content below the "Next" callout. Verified this content already exists correctly in `3-operational-workflow.md` and `4-operational-runbooks.md`, then removed the duplicate from this file — no content was lost, only de-duplicated.
- Renamed the "Additional Permissions for Hybrid Fleets (Part 2)" heading, since "Part 2" no longer exists as a concept — retitled to reference `3-operational-workflow.md` directly.
- Fixed two `[Troubleshooting](#troubleshooting)` links (Step 2.2 and Step 5.2) that pointed to a local anchor which no longer exists in this file now that Troubleshooting lives in `3-operational-workflow.md`; repointed both to `3-operational-workflow.md#troubleshooting`.
- Replaced the old fleet-wide Checklist (which mixed Part 1 lab steps with Arc onboarding, tagging, Defender Plan 2, hotpatch enrollment, monthly review, DC procedure, and report-archiving items that belong to the operational workflow) with a **Part 1-scoped checklist** covering only what this document teaches. The fleet-readiness items were preserved, not deleted — see the corresponding update in `3-operational-workflow.md`.
- Added this Update Log section — the Table of Contents referenced `#update-log` before this revision, but no such section existed in the file.
- Cleanup section left unchanged — it's generic lab teardown guidance and still belongs here.

---

[← Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) | [→ Operational Workflow](3-operational-workflow.md) | [→ Operational Runbooks](4-operational-runbooks.md) | [→ Advanced Topics](2-Azure%20Update%20Advance%20Topics.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
