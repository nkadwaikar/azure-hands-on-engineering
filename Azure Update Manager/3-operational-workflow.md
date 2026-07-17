# Azure Update Manager — Operational Workflow for Hybrid Fleets

> **Prerequisite:** Complete [1-azure-update-manager.md](1-azure-update-manager.md) before working through this guide. This document assumes Update Manager is enabled, machines are assessed, and at least one maintenance configuration exists.

Last validated on: 2026-07-12

---

## Quick Navigation

- [Pipeline Setup: Azure Arc → Defender for Servers → Azure Update Manager](#pipeline-setup-azure-arc--defender-for-servers--azure-update-manager)
- [Patch Group Tagging Strategy](#patch-group-tagging-strategy)
- [Maintenance Window Design](#maintenance-window-design)
- [Hotpatching on Arc-Enabled Servers](#hotpatching-on-arc-enabled-servers)
- [Staged / Ring-Based Patching (Known Limitation)](#staged--ring-based-patching-known-limitation)
- [Monthly Patch Review Workflow](#monthly-patch-review-workflow)
- [Troubleshooting](#troubleshooting)
- [Why Update Manager Matters](#why-update-manager-matters-engineering-justification)
- [Checklist](#checklist)

---

## Pipeline Setup: Azure Arc → Defender for Servers → Azure Update Manager

This pipeline extends the lab walkthrough into a production-grade monthly patching workflow for large hybrid environments (Arc-onboarded servers + Azure VMs).

### Step 1 — Onboard Servers to Azure Arc

1. Follow the full onboarding flow in the [Azure Arc Hybrid Server Architecture guide](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-azure-arc-hybrid-server-architecture.md) (Sections 3.5 and 3.6).
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

### Step 4 — Configure Azure Update Manager for Production Scale

For production maintenance configurations targeting patch groups, refer to [Maintenance Window Design](#maintenance-window-design) for the recommended schedule structure. The creation steps follow the same flow as [Step 3 — Configure a Maintenance Window](1-azure-update-manager.md#step-3--configure-a-maintenance-window) in the lab guide, with these additional considerations:

- **Naming convention:** use `mc-<env>-<cadence>` (e.g. `mc-prod-monthly`, `mc-dc-monthly`).
- **Tag-based machine assignment:** filter by `PatchGroup` tag rather than selecting machines individually — this keeps assignments accurate as the fleet scales.
- **Pre/Post scripts** (optional): configure Azure Automation runbooks to run before or after patching (e.g. drain load balancer, take snapshot).
- **Maintenance window duration:** set 3–4 hours for large fleets; Update Manager stops deploying to new machines if the window closes mid-run but completes in-progress machines.

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

## Hotpatching on Arc-Enabled Servers

Hotpatching installs security updates without requiring a reboot, reducing scheduled restarts on eligible Windows Server workloads from roughly monthly (12/year) to quarterly baseline reboots (4/year).

- **Eligibility:** Windows Server 2025 Standard or Datacenter, Arc-enabled, with Virtualization Based Security (VBS) enabled. (Windows Server Datacenter: Azure Edition has supported hotpatching for years and is unaffected by the licensing changes below.)
- **Cost:** Hotpatching on Arc-enabled Windows Server 2025 machines was a paid preview at $1.50 per CPU core per month; as of **May 19, 2026**, it is available at **no additional cost** — no per-core meter, no hourly charge, and no separate line item on the invoice. Servers previously enrolled in the paid preview stop being billed automatically; no action is required to keep receiving hotpatches.
- **Enabling it:** Azure Update Manager → **Machines** → select the Arc-enabled server → **Recommended updates** → **Hotpatch** → **Change** → **Receive monthly Hotpatch updates** → **Confirm**. To enable at scale, use **Machines** → **Update settings** → **+Add machine** → set the **Hotpatch** dropdown to **Enable** → **Save**.
- **Monitoring:** add the **Hotpatch status** column to the Machines grid (**Edit columns** → **Hotpatch status**) to see enrollment and patch state across Azure and Arc-enabled machines in one view.
- Hotpatches only carry security fixes (not feature or reliability fixes), so a baseline Latest Cumulative Update is still applied quarterly to deliver the rest of the payload — this is what drives the 4/year reboot cadence rather than zero reboots.

---

## Staged / Ring-Based Patching (Known Limitation)

Update Manager does **not** include a built-in feature for staged (ring-based) rollout — there's no native way to guarantee that only the exact patch versions validated in a test ring are the ones applied in pre-production and production. Where that guarantee matters (e.g. regulated environments), the current workaround is to drive Update Manager through an **Azure Automation runbook** (PowerShell + Azure Resource Graph) that stages machines into resource groups or tags per ring and gates promotion between rings on the previous ring's results. Treat the "staged rollout" language in [Prod vs Non-Prod Patching Strategy](4-operational-runbooks.md#3-prod-vs-non-prod-patching-strategy) as a deliberate addition you build on top of the maintenance-configuration model in this guide, not as something Update Manager enforces for you.

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

> **Shortcut — Updates Pane:** Instead of pivoting from Defender recommendation → machine → Update Manager, use **Azure Update Manager → Updates** (the Updates pane) to go directly from a KB or CVE-linked patch to the list of affected machines and deploy from there. See [Step 7 of the lab guide](1-azure-update-manager.md#step-7--use-the-updates-pane-cve-centric-view).

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

### 5 — Export Monthly Reports

#### Generate Reports in Azure Update Manager

1. Open **Azure Update Manager → Update compliance**.
2. Use the **Download** or **Export** option to save a CSV of the current compliance state.
3. Apply tag filters to export per-environment reports (Prod, UAT, Dev).

#### Generate CVE Reports in Defender for Cloud

Using the **Defender for Cloud → Recommendations** view from [Section 2](#2--review-security--cve-exposure) above:

1. Click **Download** at the top of the recommendations list to export to CSV.
2. Filter by **Severity: High / Critical** to produce the high-risk server list.

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

## Troubleshooting

### Issue: Machine not appearing in Update Manager

- For **Azure VMs**: confirm the **Azure VM Agent** is installed and status is **Ready** — go to VM → **Overview** → check Agent status.
- For **Arc-enabled servers**: confirm **Status: Connected** in **Azure Arc → Machines** — disconnected agents cannot receive Update Manager instructions.
- Confirm the machine's OS is in the [supported list](1-azure-update-manager.md#1-prerequisites).

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

Use this to confirm the hybrid fleet operational workflow is fully in place. Complete [1-azure-update-manager.md](1-azure-update-manager.md) first if you haven't already.

1. **Arc onboarding complete** — all target servers show **Status: Connected** in **Azure Arc → Machines** with correct tags applied ([Pipeline Setup](#pipeline-setup-azure-arc--defender-for-servers--azure-update-manager)).
2. **Tagging validated** — `PatchGroup`, `Environment`, `Criticality` tags present and accurate on all Arc machines ([Patch Group Tagging Strategy](#patch-group-tagging-strategy)).
3. **Defender for Servers Plan 2 enabled** — subscription-level plan active; MDE and vulnerability assessment auto-provisioned ([Step 2 — Enable Defender for Servers](#step-2--enable-defender-for-servers)).
4. **Defender inventory confirmed** — servers visible in [security.microsoft.com](https://security.microsoft.com) with exposure levels and CVE data populated ([Step 3 — Verify Defender for Servers Activation](#step-3--verify-defender-for-servers-activation)).
5. **Maintenance configurations created** — separate schedules per patch group; window durations, reboot settings, and update classifications configured ([Maintenance Window Design](#maintenance-window-design)).
6. **Machines assigned to schedules** — all Arc machines and VMs assigned to the correct maintenance configuration via tag-based selection.
7. **Hotpatch eligibility reviewed** — eligible Windows Server 2025 Arc machines enrolled where reboot reduction is a priority ([Hotpatching on Arc-Enabled Servers](#hotpatching-on-arc-enabled-servers)).
8. **First compliance baseline captured** — Update Manager assessment run completed; export and archive initial compliance state.
9. **Monthly review process documented** — team knows which portal views to check, which KQL queries to run, and who receives which reports ([Monthly Patch Review Workflow](#monthly-patch-review-workflow)).
10. **DC patching procedure confirmed** — staggered reboot runbook or manual procedure documented and tested ([Maintenance Window Design](#maintenance-window-design)).
11. **Report archive location established** — compliance and CVE reports stored with 12-month retention for audit evidence ([5 — Export Monthly Reports](#5--export-monthly-reports)).

---

[← Lab Guide](1-azure-update-manager.md) | [→ Operational Runbooks](4-operational-runbooks.md) | [→ Advanced Topics](2-azure-update-advanced-topics.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
