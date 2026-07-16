# Microsoft Defender for Servers — Workload Protection for Azure and Arc Servers

> **Why this matters:** Defender for Servers is the security brain layered on top of Azure Arc and Azure VMs. It provides threat detection, vulnerability assessment, File Integrity Monitoring, and Secure Score recommendations — all without deploying a separate SIEM agent. Enabling Defender for Servers on Arc-enabled machines brings on-premises and multi-cloud servers into the same security posture view as native Azure VMs.

Last validated on: 2026-07-06
Portal experience note: Steps validated against Microsoft Defender for Cloud as of July 2026; labels can vary slightly by subscription tier and feature rollout. Defender for Servers is available in two plan tiers (Plan 1 and Plan 2) — this lab focuses on Plan 2 features (FIM, vulnerability assessment, JIT) since those represent the full workload protection story.

> **Note:** This lab assumes at least one running Azure VM or Arc-enabled server. For Arc server coverage, complete [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) first. For Just-In-Time VM access, see [Bastion + JIT VM Access](2-JIT.md) — the next lab in this track, which depends on the Defender for Servers plan enabled here.

---

## Module / Track Structure

```text
Microsoft Defender for Cloud/
├── README.md                          ← Track entry point
├── 1-Defender-for-Servers.md          ← Lab 1: Workload Protection (you are here)
└── 2-JIT.md                           ← Lab 2: Bastion + JIT VM Access
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)

- [Step 1 — Enable Defender for Servers Plan](#step-1--enable-defender-for-servers-plan)
- [Step 2 — Review Secure Score and Recommendations](#step-2--review-secure-score-and-recommendations)
- [Step 3 — Run Vulnerability Assessment](#step-3--run-vulnerability-assessment)
- [Step 4 — Enable File Integrity Monitoring](#step-4--enable-file-integrity-monitoring)
- [Step 5 — Investigate a Security Alert](#step-5--investigate-a-security-alert)
- [Step 6 — Review Defender for Endpoint Integration](#step-6--review-defender-for-endpoint-integration)

- [Troubleshooting](#troubleshooting)
- [Why Defender for Servers Matters](#why-defender-for-servers-matters-engineering-justification)
- [Cleanup](#cleanup)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Security Admin** on the subscription + **Contributor** on the target resource group |
| Target machines | At least one running Azure VM **or** Arc-enabled server (Status: Connected) |
| Arc prerequisite | For Arc servers: complete [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) first |
| Log Analytics Workspace | Required for FIM data storage — workspace must exist before enabling FIM (Step 4) |
| Plan selection | **Plan 2** required for File Integrity Monitoring and vulnerability assessment (Qualys / Defender VA); Plan 1 covers foundational posture only |
| Next lab | Not required for this lab — [2-JIT.md](2-JIT.md) is the next lab in this track and depends on the Defender for Servers plan enabled here |
| Estimated Time | 60–90 minutes |
| Tools | Azure Portal only — no CLI required |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- This lab enables Defender for Servers at **subscription level** — it will apply to all VMs and Arc machines in the subscription for the duration of the lab. Disable the plan during cleanup if testing on a production subscription.
- Defender for Endpoint (MDE) integration is automatic once Defender for Servers Plan 2 is enabled — no separate MDE deployment step is required for supported OS versions.
- Just-In-Time (JIT) VM Access is covered separately in [2-JIT.md](2-JIT.md), the next lab in this track.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Enabled **Defender for Servers Plan 2** at subscription level and verified coverage of Azure VMs and Arc machines
- Reviewed the **Secure Score** and understood how recommendations are prioritized and remediated
- Run a **vulnerability assessment** and reviewed the CVE findings on a target machine
- Enabled **File Integrity Monitoring (FIM)** and validated that change events are logged to Log Analytics
- Triggered and investigated a **test security alert** using Defender's built-in test mechanism
- Understood how **Defender for Endpoint (MDE)** auto-integrates with Defender for Servers

---

## 3. Scenario

**Your servers are running — but are they secure?**

Misconfigured services, outdated software with known CVEs, and unauthorized file changes are the three most common precursors to a breach. Defender for Servers surfaces all three in a single dashboard. This lab walks through enabling the plan, closing the most actionable recommendations, and validating that the monitoring pipeline fires when something changes.

---

## Step 1 — Enable Defender for Servers Plan

### 1.1 Enable at Subscription Level

1. In the Azure Portal, go to **Microsoft Defender for Cloud**.
2. In the left nav, select **Environment settings**.
3. Expand the management group / subscription hierarchy and select your **subscription**.
4. On the **Defender plans** page, locate **Servers** in the plan list.
5. Toggle the plan to **On**.
6. Click the **Plan** column value to choose between:
   - **Plan 1** — foundational posture: Defender for Endpoint integration, basic recommendations
   - **Plan 2** — full workload protection: adds File Integrity Monitoring, vulnerability assessment (Defender VA), adaptive application controls, and network hardening
7. Select **Plan 2** → click **Save** at the top of the page.

### 1.2 Verify Coverage

1. Go to **Microsoft Defender for Cloud → Inventory** (left nav).
2. Filter by **Resource type**: `Virtual machine` and `Azure Arc machine`.
3. Confirm your target machines appear in the inventory list.
4. Allow up to 15 minutes for newly onboarded Arc machines to surface here.
5. The **Defender for Cloud** column should show **On** for covered machines.

---

## Step 2 — Review Secure Score and Recommendations

### 2.1 Understand Secure Score

1. In **Defender for Cloud** → **Secure Score** (left nav).
2. Review the overall score (0–100%) — this is the primary KPI for your subscription's security posture.
3. The score is driven by **Security controls** — groups of related recommendations. Completing all recommendations in a control gives you that control's maximum point contribution.

### 2.2 Explore Recommendations

1. Go to **Defender for Cloud → Recommendations** (left nav).
2. Filter by **Resource type**: `Virtual machine` to focus on compute.
3. Sort by **Severity** (Critical first) to see the highest-impact items.
4. Click on a recommendation to see:
   - **Why this recommendation:** The security risk it addresses
   - **Affected resources:** Which machines are non-compliant
   - **Remediation steps:** Portal-guided fix or policy-driven auto-remediation
5. Select one Critical or High recommendation and walk through the remediation steps to close it.

### 2.3 Track Recommendation Changes

After remediating a recommendation:

1. Return to **Secure Score** — note the current score.
2. Score updates are not real-time; expect 30–60 minutes for the score to reflect remediated items.
3. Remediated recommendations move to the **Completed** tab in **Recommendations** — check there to confirm your fix registered.

---

## Step 3 — Run Vulnerability Assessment

Vulnerability assessment in Defender for Servers Plan 2 scans installed software for known CVEs without deploying a separate scanner agent.

### 3.1 Enable the Vulnerability Assessment Extension

1. In **Defender for Cloud → Environment settings → [your subscription] → Server settings** (gear icon or Settings column).
2. Under **Vulnerability assessment for machines**, confirm **Microsoft Defender vulnerability management** is selected (default for Plan 2). This uses the Defender for Endpoint integration — no separate Qualys agent.
3. Click **Save** if you changed the setting.

### 3.2 Review Findings

1. Go to **Defender for Cloud → Recommendations**.
2. Search for the recommendation: **"Machines should have vulnerability findings resolved"** (or similar wording — the exact label can vary by portal rollout).
3. Click the recommendation → expand a machine to see its CVE findings.
4. Each finding shows:
   - **CVE ID and description**
   - **Severity** (Critical / High / Medium / Low)
   - **Affected software and version**
   - **Fix available** — whether a patch or upgrade resolves the CVE
5. Note the total count of Critical and High findings — these are the priority targets for [Azure Update Manager](../Azure%20Update%20Manager/1-Azure%20Update%20Manager.md).

### 3.3 Filter to a Specific Machine

1. Go to **Defender for Cloud → Inventory** → click a specific machine.
2. On the machine's detail page, select the **Recommendations** tab.
3. Filter to **Vulnerability** category — this shows all CVE findings scoped to that machine.

---

## Step 4 — Enable File Integrity Monitoring

File Integrity Monitoring (FIM) tracks changes to critical OS files, directories, and registry keys — surfacing unauthorized modifications that may indicate compromise or drift.

> **Note:** FIM requires **Defender for Servers Plan 2** and a connected **Log Analytics Workspace**. FIM change events are written to the `ConfigurationChange` and `ConfigurationData` tables in the workspace.

### 4.1 Enable FIM

1. In **Defender for Cloud → Environment settings → [subscription] → Server settings**.
2. Locate **File integrity monitoring** → toggle to **On**.
3. Select the **Log Analytics workspace** that your target machines report to.
4. Click **Save**.

### 4.2 Configure Monitored Paths

1. Go to **Defender for Cloud → Workload protections** (left nav).
2. Under **Advanced protection**, click **File integrity monitoring**.
3. Select your **Log Analytics Workspace** from the list.
4. Click **Settings** → review the default monitored paths:

   **Windows defaults:**
   - `C:\Windows\System32` — system binaries
   - `C:\Windows\SysWOW64` — 32-bit binaries on 64-bit systems
   - `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion` — registry

   **Linux defaults:**
   - `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin` — system binaries
   - `/etc` — configuration files
   - `/boot` — boot loader files

5. Add a custom path to monitor during the lab (e.g., a test directory you control):
   - Click **+ Add** under **Windows files** or **Linux files**
   - Enter the path (e.g., `C:\TestMonitor\` or `/home/testuser/`)
   - Click **Apply**

### 4.3 Validate FIM Events

1. On a monitored machine, create a test file inside the monitored path (e.g., create `C:\Windows\System32\testfim.txt` on Windows — then delete it immediately after).
2. Wait 10–15 minutes for the FIM scan cycle to pick up the change.
3. In **Log Analytics** → **Logs**, run:

```kql
ConfigurationChange
| where ChangeType == "Files"
| where TimeGenerated > ago(1h)
| project TimeGenerated, Computer, ChangeType, FieldsChanged, ConfigChangeType
| order by TimeGenerated desc
```

1. Confirm the file creation/deletion event appears for your machine.

---

## Step 5 — Investigate a Security Alert

Defender for Cloud generates security alerts based on behavioral analytics and threat intelligence. In this step, use the built-in **sample alert** mechanism to observe the alert investigation workflow without triggering real threats.

### 5.1 Generate Sample Alerts

1. In **Defender for Cloud → Security alerts** (left nav).
2. Click **Sample alerts** at the top of the page.
3. In the **Create sample alerts** panel:
   - Select your **Subscription**
   - Select alert types: check **Virtual Machines** (and **Hybrid + Arc** if applicable)
4. Click **Create sample alerts**.
5. Sample alerts are created within 2–3 minutes — refresh the **Security alerts** page.

### 5.2 Investigate an Alert

1. Click on a sample alert (e.g., **Suspicious process executed**).
2. Review the alert detail pane:
   - **Description** — what behavior triggered the alert
   - **Severity** — Critical / High / Medium / Low
   - **Affected resource** — the machine the activity was detected on
   - **MITRE ATT&CK tactics** — which phase of the attack chain this maps to
   - **Related entities** — process, IP, file hash involved
3. Click **Take action** to see the remediation options:
   - **Mitigate the threat** — manual steps to contain or remediate
   - **Prevent future attacks** — links to related recommendations
   - **Trigger automated response** — open a Logic App or playbook if configured
4. Click **View full details** to open the alert in the full investigation experience (if Microsoft Sentinel is connected, this opens in Sentinel).

### 5.3 Dismiss Sample Alerts

1. Select all sample alerts → click **Change status** → **Dismissed**.
2. Set **Reason**: `Test/Sample` and add a comment confirming these were lab-generated.
3. This keeps the real alert queue clean.

---

## Step 6 — Review Defender for Endpoint Integration

Defender for Servers Plan 2 automatically deploys **Microsoft Defender for Endpoint (MDE)** as an extension on covered machines. This provides EDR (endpoint detection and response) capabilities beyond what AV alone offers — including device health tracking, software inventory CVE mapping, and behavioural alert investigation in the Microsoft Defender portal.

### 6.1 Confirm MDE Extension Installed

1. Go to **Virtual Machines** → select a target machine → **Extensions + applications** (left nav).
2. Look for the extension **MDE.Windows** or **MDE.Linux** — it should show as **Provisioning succeeded**.
3. For Arc-enabled servers: **Azure Arc → Machines → [machine] → Extensions** tab — same extension name applies.

> **If the extension is in a failed state:** Delete it from the Extensions blade and allow Defender for Cloud policy to re-deploy it (30–60 minutes). See Troubleshooting for details.

### 6.2 Confirm Device Onboarding in the MDE Portal

1. Go to [https://security.microsoft.com](https://security.microsoft.com) → sign in with your Azure credentials.
2. In the left nav, go to **Assets → Devices**.
3. Confirm your target machine appears with:
   - **Status:** Active
   - **Onboarding status:** Onboarded
   - **Health state:** No sensor issues
4. If the machine is missing, wait 15–30 minutes — MDE extension deployment and portal onboarding are asynchronous.

### 6.3 Review Device Health and Active Alerts

1. Click on your machine in the **Devices** list to open its **Device page**.
2. Review the **Security status** panel at the top:
   - **Active alerts** — number of open alerts scoped to this machine
   - **Exposure level** — aggregated risk score based on CVEs and configuration weaknesses
3. Go to the **Alerts** tab on the device page:
   - Sample alerts generated in Step 5 may appear here — each maps to a MITRE ATT&CK tactic
   - Click an alert → **Alert story** to see the full process tree and timeline leading to the detection
4. Go to the **Timeline** tab:
   - This shows a raw event stream for the machine — process launches, file writes, network connections, registry changes
   - Use the search box to filter by a process name (e.g., `powershell.exe`) to see all associated activity

### 6.4 Review Software Inventory

1. On the device page, click the **Software inventory** tab.
2. Review the installed software list — each entry shows:
   - **Product name and version**
   - **Vendor**
   - **Weaknesses** — CVE count associated with the installed version
3. Click a software entry with **Weaknesses > 0** to see the full CVE list — this is the same data surfaced in the vulnerability assessment from Step 3, but browseable by product here.
4. Note any **End-of-support** flags — software past vendor EOL with known CVEs is the highest-risk category and the first remediation target for [Azure Update Manager](../Azure%20Update%20Manager/1-Azure%20Update%20Manager.md).

### 6.5 Run a Baseline Advanced Hunting Query

1. In the Microsoft Defender portal, go to **Hunting → Advanced hunting** (left nav).
2. Run the following query to confirm the machine is actively sending telemetry:

```kql
DeviceInfo
| where DeviceName == "<your-machine-name>"
| project Timestamp, DeviceName, OSPlatform, OSVersion, OnboardingStatus, HealthStatus
| order by Timestamp desc
| take 5
```

1. Confirm `OnboardingStatus` shows `Onboarded` and `HealthStatus` shows `Active`.
2. Run a second query to validate network telemetry is flowing:

```kql
DeviceNetworkEvents
| where DeviceName == "<your-machine-name>"
| where Timestamp > ago(1h)
| summarize ConnectionCount = count() by RemoteIPType, RemotePort, ActionType
| order by ConnectionCount desc
```

> **Note:** Replace `<your-machine-name>` with the exact hostname shown in the **Devices** list. Advanced hunting queries run against up to 30 days of MDE telemetry.

### 6.6 Defender for Cloud vs. MDE Portal — When to Use Each

| Task | Portal |
| --- | --- |
| Enable / disable Defender plans | Azure Portal → Defender for Cloud |
| Review Secure Score and recommendations | Azure Portal → Defender for Cloud |
| Manage policy and auto-remediation | Azure Portal → Defender for Cloud / Policy |
| Day-to-day alert triage and investigation | MDE Portal |
| Device inventory, health state, onboarding | MDE Portal |
| Advanced hunting and threat investigation | MDE Portal |
| Software inventory and CVE detail by product | MDE Portal |
| FIM event queries | Azure Portal → Log Analytics |
| Arc machine onboarding and extensions | Azure Portal → Azure Arc |

---

## Troubleshooting

### Issue: Defender for Servers plan shows as On but machines don't appear in Inventory

- Allow up to 30 minutes for newly covered machines to surface in Inventory.
- For Arc machines: confirm agent status is **Connected** in **Azure Arc → Machines** — Defender coverage requires a healthy Arc connection.
- Check that the machine's OS is in the supported list for Defender for Servers.

### Issue: Vulnerability assessment shows "No findings" immediately after enabling

- The initial scan can take 24 hours to complete after the MDE extension is deployed.
- Confirm the **MDE.Windows** or **MDE.Linux** extension shows `Provisioning succeeded` on the machine.
- If the extension is in a failed state, delete it from the Extensions blade and allow Defender for Cloud policy to re-deploy it (can take 30–60 minutes).

### Issue: FIM showing no events after creating a test file

- FIM scan cycles run every 30 minutes by default — wait at least 30 minutes after the file change.
- Confirm the monitored path in the FIM configuration matches the exact directory where the test file was created (case-sensitive on Linux).
- Verify the machine is sending data to the correct Log Analytics workspace by querying the `Heartbeat` table in that workspace.

### Issue: Sample alerts not appearing after 5 minutes

- Refresh the **Security alerts** page manually — it does not auto-refresh.
- Confirm the subscription selected in the sample alert dialog matches the subscription shown in the Defender for Cloud scope filter.
- Sample alerts are created as medium/low severity by default — check that your current filter doesn't exclude those severities.

### Issue: MDE extension deployment fails on Arc machine

- Confirm the Arc machine has outbound HTTPS (port 443) connectivity to `*.endpoint.security.microsoft.com`.
- On Windows Arc machines, confirm the `MsSense.exe` process can run — some endpoint hardening policies block it.
- Check extension deployment logs: **Azure Arc → Machines → [machine] → Extensions → MDE.Windows → View detailed status**.

---

## Why Defender for Servers Matters (Engineering Justification)

- **Unified posture across hybrid environments** — Arc-enabled on-premises and multi-cloud servers appear in the same Secure Score and recommendations view as Azure VMs; one dashboard for the full estate
- **Vulnerability assessment without extra scanners** — CVE findings surface via MDE integration; no Qualys agent or separate scanning infrastructure required
- **FIM closes the drift detection gap** — unauthorized changes to system files, configs, and registry are logged before they result in an incident; change events are queryable from Log Analytics
- **Automatic MDE deployment** — enabling Defender for Servers Plan 2 deploys EDR to all covered machines via extension; no separate endpoint management toolchain required
- **Secure Score as operational KPI** — recommendations are scored and prioritized; teams have a clear, measurable target rather than an unbounded backlog of hardening tasks
- **Alert quality over quantity** — behavioral analytics and MITRE ATT&CK mapping reduce alert noise compared to signature-only detection; each alert includes actionable context

> Combined with JIT VM Access (covered in [2-JIT.md](2-JIT.md)) and Azure Update Manager (covered in the [Azure Update Manager track](../Azure%20Update%20Manager/1-Azure%20Update%20Manager.md)), Defender for Servers completes the three-layer posture: *access control + patch currency + runtime protection*.

---

## Cleanup

### Disable Defender for Servers Plan

> **Important:** Disabling the plan removes Defender coverage from all machines in the subscription — do this only if no other workloads depend on it.

1. Go to **Defender for Cloud → Environment settings → [subscription] → Defender plans**.
2. Toggle **Servers** to **Off** → **Save**.
3. The MDE extension is **not** automatically uninstalled when the plan is disabled — if you want to remove it, do so manually from each machine's **Extensions** blade.

### Disable File Integrity Monitoring

1. Go to **Defender for Cloud → Workload protections → File integrity monitoring**.
2. Select your workspace → **Disable**.
3. FIM data already ingested into Log Analytics remains until the workspace retention window expires — no immediate deletion.

### Remove Sample Alerts

1. If you didn't dismiss sample alerts in Step 5.3:
   - Go to **Security alerts** → filter by **Status: Active**
   - Select all sample alerts → **Change status → Dismissed**

---

[↑ Track README](README.md) | [↑ Repo README](../README.md) | [Bastion + JIT VM Access →](2-JIT.md)
