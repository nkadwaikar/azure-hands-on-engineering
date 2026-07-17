# Azure Update Manager — Operational Runbooks

> **Prerequisite:** Complete [1-Azure_Update_Manager.md](1-Azure_Update_Manager.md) and review [3-operational-workflow.md](3-operational-workflow.md) before using these runbooks. This document assumes maintenance configurations are created, machines are tagged, and the Arc → Defender → Update Manager pipeline is active.

Last validated on: 2026-07-12

---

## Quick Navigation

- [1. Monitor Tonight's Patch Run](#1-monitor-tonights-patch-run-2200-pt-1)
- [2. Validate Logs After the Run](#2-validate-logs-after-the-run)
- [3. Prod vs Non-Prod Patching Strategy](#3-prod-vs-non-prod-patching-strategy)
- [4. Alerting for Arc Agent Disconnects](#4-alerting-for-arc-agent-disconnects)
- [Standardized Maintenance Configuration (Recommended)](#standardized-maintenance-configuration-recommended)
- [Maintenance Configuration — Option by Option Explained](#maintenance-configuration--option-by-option-explained-1)

---

## 1. Monitor Tonight's Patch Run (22:00 PT)

To properly monitor the run, these steps must happen:

### Track the Maintenance Configuration Execution

1. In the Azure Portal, open **Azure Update Manager → History** at 22:00 PT.
2. Confirm a new deployment run record appears for the maintenance configuration scheduled for 22:00 PT.
3. Click the run record to open the per-machine execution detail view.

### Watch the WindowsOsUpdateExtension Activity ID

1. In **Azure Arc → Machines → [server] → Extensions**, note the `WindowsOsUpdateExtension` version and status — this is the extension that executes the install; `WindowsPatchExtension` runs alongside it for assessment. Confirm status is **Succeeded** (or **Transitioning** while a run is in progress).
2. In the deployment run record, copy the **Activity ID** for the extension invocation — use this to correlate portal events with on-machine logs.

### Capture Key Milestones

| Milestone | Where to Observe |
| --- | --- |
| Assessment start time | Deployment run record → **Start time** field |
| Patch download start | Extension log: `C:\Packages\Plugins\Microsoft.SoftwareUpdateManagement.WindowsOsUpdateExtension\Logs` |
| Patch installation progress | Azure Update Manager → History → run record → per-machine status updates |
| Reboot trigger | Extension log entries containing `Reboot` or `RestartRequired` |
| Reboot completion | Machine heartbeat resumes in Arc portal; extension status returns to **Succeeded** |
| Extension finalization | Extension status changes from **Transitioning** → **Succeeded** or **Failed** |

### Detect Issues During the Run

| Issue | Detection Method |
| --- | --- |
| **Timeouts** | Run record duration exceeds the configured window; machines show **Timed out** status |
| **Failures** | Per-machine status shows **Failed**; expand to see the error code |
| **Maintenance window overruns** | Run start + duration > window end time; remaining machines are skipped |
| **Arc agent disconnects during patching** | Arc portal shows **Status: Disconnected**; heartbeat gap in Log Analytics |

### Confirm Run Completion

- Verify the deployment run record shows a completed status before **01:55 AM PT**.
- Confirm no machines remain in **In progress** state after 01:55 AM PT.
- If the window closes with machines still in progress, those machines will not be retried until the next scheduled window — remediate manually using **One-time update**.

> **Goal:** Know exactly what happened during the patch window — no surprises discovered in the morning.

---

## 2. Validate Logs After the Run

After the patch window ends, collect and analyze the following log sources to build a complete post-patching health report.

### Arc Agent Logs

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

### Update Extension Logs

**Path:** `C:\Packages\Plugins\Microsoft.SoftwareUpdateManagement.WindowsOsUpdateExtension\Logs`

Check for:

- Patch installation success/failure per KB
- Reboot status (`RebootRequired`, `RebootCompleted`)
- Maintenance window exceeded warnings
- Error codes (cross-reference with [Troubleshooting](3-operational-workflow.md#troubleshooting))
- Activity ID results matching the run record from the portal

```powershell
# List log files sorted by last write time
Get-ChildItem 'C:\Packages\Plugins\Microsoft.SoftwareUpdateManagement.WindowsOsUpdateExtension\Logs' |
  Sort-Object LastWriteTime -Descending |
  Select-Object Name, LastWriteTime, Length
```

### Windows Update Logs

**Path:** `C:\Windows\WindowsUpdate.log`

> On Windows Server 2016+, this file is encoded. Generate a readable version with:

```powershell
Get-WindowsUpdateLog -LogPath 'C:\Temp\WindowsUpdate-readable.log'
```

Check for:

- Download failures (search for `FAILED` or `error`)
- Install failures (search for `Installation Failure`)
- Pending reboot flags (search for `reboot required`)

### Compliance Results

Azure Portal → **Azure Update Manager → Update compliance**

| View | What to Confirm |
| --- | --- |
| **Installed patches** | Count matches expected KBs from the deployment run |
| **Failed patches** | Zero failed patches, or documented and remediated |
| **Pending patches** | Only approved exclusions remain pending |
| **Reboot required** | All machines have completed reboot; none stuck in pending reboot state |

---

## 3. Prod vs Non-Prod Patching Strategy

A proper enterprise patching strategy separates production and non-production environments to catch patch regressions before they reach production systems.

### Production

| Setting | Value |
| --- | --- |
| **Cadence** | Weekly (or monthly for stable environments) |
| **Day/Time** | Sunday night or Friday night |
| **Window Duration** | 3–4 hours |
| **Reboot** | Allowed (reboot if required) |
| **Update Classifications** | Security, Critical, Update Rollup |
| **Pre/Post Scripts** | Azure Automation runbooks: drain load balancer before patching, validate services after |
| **Staged rollout** | Non-prod → UAT → Prod; Domain Controllers patched last, one at a time (built via the Automation-runbook approach in [Staged / Ring-Based Patching](3-operational-workflow.md#staged--ring-based-patching-known-limitation) — not natively enforced by Update Manager) |

### Non-Production

| Setting | Value |
| --- | --- |
| **Cadence** | Weekly or twice-weekly |
| **Day/Time** | Earlier windows (e.g. weeknight) |
| **Window Duration** | 2–3 hours |
| **Reboot** | Always allowed |
| **Update Classifications** | Security, Critical, Update Rollup, Definition, and optionally Optional updates |
| **Purpose** | Validate patch stability before promoting to Prod; catch regressions early |

### Tagging Model

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

## 4. Alerting for Arc Agent Disconnects

Arc agent disconnects block Update Manager from delivering patches. Detect them proactively with Azure Monitor alerts.

> **Quick Alerts alternative:** For patch-specific events (missing updates, failed deployments, stale assessments, pending reboots), use the **Quick Alerts** feature built directly into Update Manager: **Azure Update Manager → Monitoring → New alerts rule (Preview)**. It creates ARG-backed alert rules without requiring you to navigate to Azure Monitor. See [Section 13 of the Advanced Topics guide](2-Azure_Update_Advance_Topics.md#13-quick-alerts-native-update-manager-alerting). The Azure Monitor alert rules below are complementary — they cover infrastructure-level events (Arc heartbeat, extension failures) that Quick Alerts does not address.

### Azure Monitor Alert Rules

Create the following alert rules in **Azure Monitor → Alerts → + Create → Alert rule**:

| Alert | Signal Type | Condition | Severity |
| --- | --- | --- | --- |
| **Arc Agent Heartbeat Missing** | Log (Heartbeat table) | No heartbeat in last 15 min | Sev 1 |
| **Arc Machine Disconnected** | Resource health | Arc machine status = Disconnected | Sev 1 |
| **Guest Configuration Non-compliant** | Azure Policy compliance | Non-compliant assignment | Sev 2 |
| **Extension Failure** | Activity Log | Extension provisioning state = Failed | Sev 2 |

### Log Analytics KQL Alerts

#### Heartbeat Missing (>15 Minutes)

```kql
Heartbeat
| summarize LastHeartbeat = max(TimeGenerated) by Computer, ResourceGroup
| where LastHeartbeat < ago(15m)
| project Computer, ResourceGroup, LastHeartbeat, MinutesSilent = datetime_diff('minute', now(), LastHeartbeat)
| order by MinutesSilent desc
```

#### Arc Agent Disconnect for Specific Machine

```kql
Heartbeat
| where Computer == "WIN-CE1COEMM5PE"
| where TimeGenerated > ago(5m)
```

> If this query returns zero rows, the agent is disconnected or not sending heartbeats.

#### Extension Failures (Last 24 Hours)

```kql
AzureActivity
| where OperationNameValue has "extensions/write"
| where ActivityStatusValue == "Failure"
| where TimeGenerated > ago(24h)
| project TimeGenerated, ResourceGroup, Resource, Properties
| order by TimeGenerated desc
```

### Notification Channels

1. In **Azure Monitor → Alerts → Action groups**, create an action group with:
   - **Email** notifications to the infrastructure on-call distribution list
   - **Microsoft Teams** webhook for the patching operations channel (via Logic App or Teams incoming webhook)
2. Assign the action group to each alert rule created above.
3. Test alerts by running the KQL queries manually in Log Analytics and confirming they return expected results before relying on them for production.

---

## Standardized Maintenance Configuration (Recommended)

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

### Configuration Notes

- **Duration:** 3 hours 55 minutes keeps the window under 4 hours, which is the recommended ceiling for most fleets. Machines still in progress when the window closes will complete their current patch but no new patches will be started.
- **Reboot inside window:** Ensures reboots happen during the approved change window, not after business hours the next day.
- **Tag-based assignment:** Use the `PatchGroup` tag with dynamic scoping — manually assigning machines does not scale and leads to coverage gaps as the fleet changes.
- **Definition updates:** Including Definition (antimalware signature) updates ensures Defender signatures stay current on every patching cycle without a separate schedule.
- **Hotpatch-eligible machines:** for Arc-enabled Windows Server 2025 machines enrolled in hotpatching, most monthly security fixes install without a reboot inside this same window — see [Hotpatching on Arc-Enabled Servers](3-operational-workflow.md#hotpatching-on-arc-enabled-servers).

---

## Maintenance Configuration — Option by Option Explained

Every setting inside an Azure Update Manager Maintenance Configuration is explained below. Each entry covers what the option does and how it affects patching on Arc-enabled Windows Servers.

### 1. Schedule Enabled

Activates or deactivates the maintenance configuration.

- **Enabled** — patching runs according to the defined schedule.
- **Disabled** — no patching occurs; the configuration is preserved for future use.

### 2. Start Time

The exact clock time at which Azure Update Manager begins the patching workflow. At this moment Azure will:

1. Start the patch assessment
2. Begin downloading updates
3. Start installing updates
4. Trigger a reboot if required

Example: `22:00 PT` — patching begins at 10:00 PM Pacific Time.

### 3. Repeats

Defines how often the schedule fires.

| Option | Behavior |
| --- | --- |
| Every day | Runs daily at the configured start time |
| Every week | Runs once per week |
| On [day] every week | Runs on a specific weekday each week (e.g. every Friday) |
| Monthly | Runs once per month on the configured day |

Example: **On Friday every week** → patching runs every Friday at 22:00 PT.

### 4. Ends On

Defines when the recurring schedule stops.

| Option | Behavior |
| --- | --- |
| No end date | Schedule runs indefinitely |
| Specific date | Schedule stops after the configured date; no further deployments are triggered |

### 5. Maintenance Window

The **maximum allowed duration** for the entire patching operation. The window covers:

- Assessment
- Update download
- Update installation
- Reboot (if required)
- Post-reboot patching
- Extension finalization

If patching does not finish within this window, Azure stops starting new patch operations. Machines already mid-install complete their current update, but no new packages are started.

> **Why this matters:** Exceeding the maintenance window produces `maintenanceWindowExceeded: true` and `InstallationOfAnUpdateWasInterruptedDueToTimeExpired` errors in the extension logs. A window of **3 hours 55 minutes** provides sufficient headroom for most Windows Server workloads.

### 6. Next Maintenance Times

Azure pre-calculates and displays the next upcoming patch run timestamps based on the configured schedule. Use this to confirm the schedule is active and correctly set before the window opens.

Example output:

```
Fri Jul 17 2026 22:00
Fri Jul 24 2026 22:00
Fri Jul 31 2026 22:00
```

### 7. Reboot Options

Controls when (or whether) Azure is permitted to reboot the machine after installing updates.

| Option | Behavior | Recommendation |
| --- | --- | --- |
| **Reboot if required** | Reboots only when an update requires it | Recommended for most servers |
| **Always reboot** | Reboots after every patching run regardless of need | Use when you want a guaranteed clean state |
| **Never reboot** | No reboot is triggered by Update Manager | For Domain Controllers with staggered manual reboots only |
| **Reboot inside maintenance window** | Reboot must complete before the window closes | Required to avoid out-of-window reboots |

> If extension logs show `rebootNeeded: true` and `rebootStatus: Required`, reboot must be permitted inside the window or patching will report as incomplete.

### 8. Patch Classifications

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

### 9. Patch Source

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

### 10. Assignments

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

### Quick Reference Summary

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

[← Operational Workflow](3-operational-workflow.md) | [→ Advanced Topics](2-Azure_Update_Advance_Topics.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
