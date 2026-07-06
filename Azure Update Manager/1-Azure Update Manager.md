# Azure Update Manager — Patch Orchestration for Azure and Arc Servers

> **Why this matters:** Unpatched systems are the most exploited attack surface in enterprise environments. Azure Update Manager replaces the legacy Log Analytics-based Update Management solution and provides a single, agent-free control plane for assessing and deploying OS updates across Azure VMs, Arc-enabled on-premises servers, and multi-cloud machines — without routing telemetry through Log Analytics as a dependency.

Last validated on: July 2026
Portal experience note: Steps validated against Azure Portal (Update Manager blade) as of July 2026. The Update Manager blade is accessed via **Search → Azure Update Manager** or via the **Operations** section of individual VM resources.

> **Note:** This lab targets the standalone Azure Update Manager service (generally available). If your subscription still uses the legacy Update Management solution embedded in Azure Automation accounts, you will need to migrate to Update Manager before proceeding — the two solutions conflict when managing the same machine.

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Enable and Scope Update Manager](#step-1--enable-and-scope-update-manager)
- [Step 2 — Run an On-Demand Patch Assessment](#step-2--run-an-on-demand-patch-assessment)
- [Step 3 — Configure a Maintenance Window](#step-3--configure-a-maintenance-window)
- [Step 4 — Schedule and Execute an Update Deployment](#step-4--schedule-and-execute-an-update-deployment)
- [Step 5 — Review Compliance and Patch History](#step-5--review-compliance-and-patch-history)
- [Step 6 — KQL Queries for Patch State](#step-6--kql-queries-for-patch-state)
- [Troubleshooting](#troubleshooting)
- [Why Update Manager Matters](#why-update-manager-matters-engineering-justification)
- [Cleanup](#cleanup)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Contributor** on the target resource group (or **Azure Update Manager Contributor** built-in role) |
| Target machines | At least one running Azure VM or Arc-enabled server in a supported OS |
| Arc requirement | If targeting Arc servers: Azure Connected Machine Agent installed and status **Connected** — complete [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) first |
| Supported OS | Windows Server 2008 R2+, Windows 10/11; RHEL 7+, SLES 12+, Ubuntu 16.04+, Debian 9+, Amazon Linux 2 |
| No conflicting solution | Legacy Update Management (Log Analytics-based) must not be active on the same machines |
| Estimated Time | 45–60 minutes |
| Tools | Azure Portal only — no CLI required |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- Lab uses the Azure Portal Update Manager blade; PowerShell and REST API paths exist but are out of scope.
- Automatic VM Guest Patching (cloud-init / Windows Automatic Updates) on Azure VMs is separate from Update Manager scheduling — if already enabled, Update Manager coexists but scheduled deployments take precedence during the defined window.
- Arc-enabled servers must have outbound HTTPS (port 443) connectivity to Azure endpoints — connectivity validated in the Arc track.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Explored the **Azure Update Manager** blade and understood fleet-level patch posture at a glance
- Run an **on-demand patch assessment** to surface available updates without installing anything
- Created a **maintenance window** and understood how it gates when updates are permitted
- Scheduled and executed an **update deployment** with classification and exclusion filters
- Reviewed **compliance reporting** and identified machines overdue for patching
- Written KQL queries to pull patch state from **Azure Resource Graph** and the `UpdateSummary` table

---

## 3. Scenario

**One unpatched server is all it takes.**

Your fleet spans Azure VMs in production and Arc-enabled on-premises servers. Security and compliance teams need a single dashboard that answers: *which machines are missing critical patches, which have a defined patching schedule, and which have never been assessed?* Update Manager provides that dashboard — and the scheduling engine to close the gap.

---

## Step 1 — Enable and Scope Update Manager

Azure Update Manager requires no agent installation on Azure VMs (it uses the VM Agent) and no additional agent on Arc servers (it uses the Connected Machine Agent). The service is enabled at the resource level when you run an assessment or create a schedule.

### 1.1 Open Update Manager

1. In the Azure Portal, search **Azure Update Manager** → open the service.
2. The **Overview** blade shows a fleet summary: total machines, assessment status, and pending update counts grouped by severity.
3. Select your **Subscription** and **Resource Group** using the filters at the top to scope the view to your target machines.

### 1.2 Add Machines to the Scope

1. Go to **Machines** (left nav) — this lists all Azure VMs and Arc-enabled servers in the selected scope.
2. Confirm your target machine(s) appear in the list.
3. If a machine shows **Not assessed**, it has never had an Update Manager assessment run. That's fine — you'll fix that in Step 2.
4. Note the **Patch orchestration** column:
   - **Azure-managed** — Azure controls patching automatically (not our scope in this lab)
   - **Customer managed schedules** — update deployments are controlled by your defined schedules
   - **Manual updates** — no schedule defined; updates must be triggered on-demand
   - For Arc-enabled servers, this shows **Customer managed schedules** once a maintenance configuration is assigned

---

## Step 2 — Run an On-Demand Patch Assessment

An assessment scans the machine and surfaces available updates **without installing anything**. Always run an assessment before scheduling a deployment so you know what's pending.

1. In the **Machines** list, select one or more target machines (checkbox).
2. Click **Assess now** at the top of the list.
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

## Step 3 — Configure a Maintenance Window

A **maintenance configuration** (maintenance window) defines **when** updates are permitted to deploy. Machines assigned to a configuration only receive scheduled deployments inside that window.

### 3.1 Create a Maintenance Configuration

1. In Azure Update Manager, go to **Maintenance configurations** (left nav) → **+ Create**.
2. Fill in:

   |Field  |Example Value|
   | ---   |---           |
   | Subscription | Your subscription |
   | Resource group | `rg-compute-prod` |
   | Configuration name | `mc-windows-prod-weekly` |
   | Region | Same region as target machines |
   | OS type | Windows (or Linux — create one per OS type) |

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

## Step 4 — Schedule and Execute an Update Deployment

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
   - **Maintenance window duration:** 2 hours
5. Review + **Install** — the deployment is submitted.
6. Go to **History** (left nav in Update Manager) to monitor the deployment run. Refresh every 2–3 minutes.
7. When the run completes, click on the run record to see per-machine results: **Succeeded**, **Failed**, or **Not applicable**.

### 4.2 Validate Scheduled Deployment (Optional — Observe Pattern)

1. In **Maintenance configurations**, open your `mc-windows-prod-weekly` configuration.
2. Go to **History** — after the configured window passes, deployment records will appear here.
3. This confirms the scheduled flow without requiring an immediate manual trigger.

---

## Step 5 — Review Compliance and Patch History

### 5.1 Compliance Dashboard

1. In Azure Update Manager → **Overview** — review the **Summary** panel:
   - **Compliant** machines: assessed and no critical/security updates pending
   - **Non-compliant** machines: have pending critical/security updates past the defined SLA
   - **Not assessed**: never had an Update Manager assessment
2. Use the **Compliance by resource group** chart to identify which environment (prod, dev, non-prod) has the most exposure.
3. Click a non-compliant machine → **Updates** tab → note the specific pending KBs and their severity.

### 5.2 Patch History per Machine

1. Select a machine that had a deployment run → **Update history** tab.
2. Review:
   - Updates installed (KB/package, severity, classification)
   - Installation status (Succeeded / Failed)
   - Reboot performed (Yes/No)
3. For failed updates, note the error code — see [Troubleshooting](#troubleshooting) for common failures.

---

## Step 6 — KQL Queries for Patch State

Run these queries in **Log Analytics** (if machines send data to a workspace) or **Azure Resource Graph** (for resource-level patch metadata).

### 6.1 Azure Resource Graph — Pending Updates by Machine

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

### 6.2 Log Analytics — UpdateSummary (Legacy Agent Path)

```kql
UpdateSummary
| summarize arg_max(TimeGenerated, *) by Computer
| project Computer, OSType, TotalUpdatesMissing, CriticalUpdatesMissing, SecurityUpdatesMissing, LastAssessedTime
| order by CriticalUpdatesMissing desc
```

### 6.3 Machines Not Assessed in 30 Days

```kql
patchassessmentresources
| where type == "microsoft.compute/virtualmachines/patchassessmentresults"
    or type == "microsoft.hybridcompute/machines/patchassessmentresults"
| extend lastAssessed = todatetime(properties.lastModifiedDateTime)
| where lastAssessed < ago(30d) or isnull(lastAssessed)
| project id, lastAssessed
```

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
- Common causes:
  - **Reboot pending from a previous update** — a prior update required a reboot that hasn't happened; reboot the machine and re-trigger.
  - **Windows Update service disabled** — re-enable `wuauserv` on the machine.
  - **Insufficient disk space** — update packages require temporary disk space during extraction; free up at least 2 GB.
  - **Windows Update catalog endpoint blocked** — confirm `download.microsoft.com` and `windowsupdate.microsoft.com` are reachable on port 443.

### Issue: Dynamic scope not picking up new machines

- Dynamic scopes are evaluated at deployment time, not real-time — a machine added to a resource group after a deployment was scheduled may not be included in that run. It will be included in the next scheduled window.
- Confirm the resource group / subscription / tag filters in the dynamic scope match the machine's actual values.

### Issue: Arc machine shows "No updates available" immediately after onboarding

- The first assessment after onboarding may return zero results if the machine's local update cache hasn't been refreshed. Run `wuauclt /detectnow` (Windows) or `apt-get update` (Debian/Ubuntu) inside the machine, then re-run the assessment from Update Manager.

---

## Why Update Manager Matters (Engineering Justification)

- **Single pane of glass** — Azure VMs and Arc-enabled on-premises/multi-cloud servers are visible in one dashboard; no separate patching toolchain per environment
- **Agent-free for Azure VMs** — uses the VM Agent already present; no extra agent to deploy or maintain
- **Change-controlled patching** — maintenance windows integrate with change management; updates cannot be deployed outside the defined window
- **Compliance auditability** — every assessment and deployment is logged; compliance reports are available for audit without manual aggregation
- **Dynamic scoping** — target by subscription, resource group, or tag; the fleet membership stays accurate automatically as machines are added or retired
- **Replaces legacy solution** — the Log Analytics Update Management solution was retired; Update Manager is the current supported path

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
