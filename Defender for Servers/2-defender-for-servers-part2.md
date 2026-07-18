# Microsoft Defender for Servers — Part 2: Vulnerability Assessment, FIM, Alerts & MDE Integration

**This is Part 2 of 2.** Part 2 picks up where [Part 1](1-defender-for-servers-part1.md) left off — Defender for Servers Plan 2 should already be enabled and Secure Score / Recommendations reviewed before starting here. If you haven't completed those steps yet, go to **[Part 1: 1-defender-for-servers-part1.md](1-defender-for-servers-part1.md)** first.

Last validated on: 2026-07-17
Portal experience note: Steps validated against Microsoft Defender for Cloud as of July 2026; labels can vary slightly by subscription tier and feature rollout.

---

## Module / Track Structure

```text
Microsoft Defender for Cloud/
├── README.md                            ← Track entry point
├── 1-defender-for-servers-part1.md       ← Lab 1a: Setup & Security Posture
├── 1-defender-for-servers-part2.md       ← Lab 1b: Vulnerability Assessment, FIM, Alerts, MDE (you are here)
└── 3-jit.md                              ← Lab 2: Bastion + JIT VM Access
```

---

## Quick Navigation — Part 2

- [Step 3 — Run Vulnerability Assessment](#step-3--run-vulnerability-assessment)
- [Step 4 — Enable File Integrity Monitoring](#step-4--enable-file-integrity-monitoring)
- [Step 5 — Investigate a Security Alert](#step-5--investigate-a-security-alert)
- [Step 6 — Review Defender for Endpoint Integration](#step-6--review-defender-for-endpoint-integration)
  - [6.7 — Confirm the Guest Configuration Extension](#67-confirm-the-guest-configuration-extension-for-local-policy-recommendations)
- [Troubleshooting](#troubleshooting)
- [Why Defender for Servers Matters](#why-defender-for-servers-matters-engineering-justification)
- [Cleanup](#cleanup)

**← Back to Part 1** → [Prerequisites through Step 2](1-defender-for-servers-part1.md)

---

## Step 3 — Run Vulnerability Assessment

Vulnerability assessment in Defender for Servers Plan 2 scans installed software for known CVEs without deploying a separate scanner agent.

### 3.1 Enable the Vulnerability Assessment Extension

1. In **Defender for Cloud → Environment settings → [your subscription] → Server settings** (gear icon or Settings column).
2. Under **Vulnerability assessment for machines**, confirm **Microsoft Defender vulnerability management** is selected (default for Plan 2). This uses the Defender for Endpoint integration — no separate Qualys agent.
3. Click **Save** if you changed the setting.

### 3.2 Review Findings

1. Go to **Defender for Cloud → Cloud Security → Recommendations**, and click the **Vulnerabilities** category tab at the top for a focused view.
2. If you still see the grouped-model entry, search for **"Machines should have vulnerability findings resolved"** (tagged **Set for deprecation**); for the individual model, look for findings tagged under the **SoftwareUpdate** category — one row per vulnerable package rather than one per machine. Both may currently be visible side by side (see Step 2.4).
3. Click a recommendation → expand to see its CVE findings, or in individual view, click a finding directly.
4. Each finding shows:
   - **CVE ID and description**
   - **Severity** (Critical / High / Medium / Low)
   - **Affected software and version**
   - **Fix available** — whether a patch or upgrade resolves the CVE
5. Note the total count of Critical and High findings — these are the priority targets for [Azure Update Manager](../Azure%20Update%20Manager/1-azure-update-manager.md). At fleet scale, use the **By Title** view or an Azure Resource Graph query (Step 2.4) rather than reviewing machine by machine.

### 3.3 Filter to a Specific Machine

1. Go to **Defender for Cloud → Inventory** → click a specific machine.
2. On the machine's detail page, select the **Recommendations** tab.
3. Filter to **Vulnerability** category — this shows all CVE findings scoped to that machine. This per-machine view (equivalent to **By Resource**) is best used for investigating one asset, not for routine fleet-wide triage — see Step 2.4.

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
3. For Arc-enabled servers: **Azure Arc → Machines → [machine] → Extensions** tab — same extension name applies. The Arc **Inventory** grid also surfaces this as a **Defender extension** column (values: Not enabled / Provisioning / Provisioning succeeded).

> **If the extension is in a failed state:** Delete it from the Extensions blade and allow Defender for Cloud policy to re-deploy it (30–60 minutes). See Troubleshooting for details.
>
> **If the extension still shows "Not enabled" after 30–60 minutes** (most common cause: the Arc agent was recently reconnected per Step 1.0, and policy hasn't re-evaluated the machine yet), deploy it manually:
>
> 1. Go to **Azure Arc → Machines → [machine] → Extensions**.
> 2. Click **+ Add**.
> 3. Select **Microsoft Defender for Endpoint** from the extension gallery.
> 4. Click **Next** → **Review + create** → **Create**.
> 5. Deployment typically takes 5–15 minutes; watch the status move from **Creating** to **Succeeded**.
> 6. If **Microsoft Defender for Endpoint** doesn't appear in the extension gallery, instead go to **Defender for Cloud → Recommendations**, find **"Endpoint protection should be installed on machines"**, select the non-compliant machine, and click **Fix** to force policy-driven deployment.

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
4. Note any **End-of-support** flags — software past vendor EOL with known CVEs is the highest-risk category and the first remediation target for [Azure Update Manager](../Azure%20Update%20Manager/1-azure-update-manager.md).

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
| Verify Arc agent health / reconnect / reinstall | Local shell (`azcmagent`) + Azure Portal → Azure Arc |
| Enable / disable Defender plans | Azure Portal → Defender for Cloud |
| Review Secure Score and recommendations | Azure Portal → Defender for Cloud → **Cloud Security → Security posture / Recommendations** |
| Triage findings across a large fleet | Azure Resource Graph (via **Open query**) or **By Title** aggregation view — see Step 2.4 |
| Manage policy and auto-remediation | Azure Portal → Defender for Cloud / Policy |
| Day-to-day alert triage and investigation | MDE Portal |
| Device inventory, health state, onboarding | MDE Portal |
| Advanced hunting and threat investigation | MDE Portal |
| Software inventory and CVE detail by product | MDE Portal |
| FIM event queries | Azure Portal → Log Analytics |
| Arc machine onboarding and extensions | Azure Portal → Azure Arc |
| Local-policy / audit recommendations (Guest Config) | Azure Portal → Azure Arc → Machine → Extensions |

### 6.7 Confirm the Guest Configuration Extension (for local-policy recommendations)

A large share of Recommendations — especially ones worded like **"Ensure 'Audit ___' is set to..."** or **"Configure '___'"** — are evaluated by the **Guest Configuration** extension, not MDE. This is a separate extension and has its own deployment lifecycle.

1. Go to **Azure Arc → Machines → [machine] → Extensions**.
2. Look for **ConfigurationforWindows** (or **AzurePolicyforWindows** / **ConfigurationforLinux** on Linux) — it should show **Provisioning succeeded**.
3. If it's missing, add it manually the same way as MDE:
   - Click **+ Add** → select the Guest Configuration extension from the gallery → **Next** → **Review + create** → **Create**.
4. If it's not available directly in the gallery, it's typically deployed via an Azure Policy assignment (often bundled with the Defender for Cloud default initiative) rather than added ad hoc — check **Defender for Cloud → Environment settings → [subscription] → Security Policy** to confirm the default policy initiative is assigned to your subscription (see the "N subscriptions don't have the default policy assigned" banner on the Security posture page if this applies to you).
5. Once installed, allow up to several hours for the first full evaluation cycle — Guest Configuration checks typically run on a longer interval than MDE-driven recommendations, so "Not evaluated" can persist longer here even when everything is healthy.
6. Also check whether the recommendation is tagged **"New version"** (individual model) vs. **"Set for deprecation"** (grouped model, being removed July 31, 2026) — many "Not evaluated" rows on grouped entries reflect the in-progress migration rather than a deployment failure on your machine. See Step 2.4 for how to work with both models cleanly.

---

## Troubleshooting

### Issue: Arc agent shows "Disconnected" or portal shows "Agent Version: Unknown"

- Run `azcmagent show` on the machine directly — if **Agent Status** is `Disconnected` and identity fields (Resource Name, Resource Group, Subscription ID, Tenant ID) are blank, the agent has lost its registration even if local services (`himds`, `arcproxy`, `extensionservice`, `gcarcservice`) are still running.
- Attempt a reconnect first: `azcmagent connect --resource-group "<rg>" --tenant-id "<tenant-id>" --location "<region>" --subscription-id "<sub-id>" --cloud "AzureCloud"`.
- If reconnect fails, perform a full uninstall/reinstall — see Step 1.0 for the complete command sequence.
- This must be resolved before Inventory coverage, Secure Score evaluation, or MDE extension deployment will work correctly for the affected machine — a healthy plan configuration at the subscription level does not compensate for a disconnected agent on an individual machine.

### Issue: Defender for Servers plan shows as On but machines don't appear in Inventory

- Allow up to 30 minutes for newly covered machines to surface in Inventory.
- For Arc machines: confirm agent status is **Connected** in **Azure Arc → Machines** — Defender coverage requires a healthy Arc connection. See the Arc agent issue above if status is Disconnected.
- Check that the machine's OS is in the supported list for Defender for Servers.

### Issue: Can't find "Secure Score" in the left nav

- Current portal versions surface Secure Score under **Defender for Cloud → Cloud Security → Security posture**, not as a bare top-level nav item and not solely as an Overview tile.
- The top-level percentage shown is a **blended average across every subscription in scope** — scroll to the **Environment** tab table to find your specific subscription's individual score and unhealthy-resource count.
- If your tenant's layout differs, try the global Azure Portal search bar and type "Secure Score" directly.

### Issue: Recommendations stuck at "Not evaluated" instead of a severity

- Work through the numbered diagnostic checklist in **Step 2.2a** rather than guessing — it covers all the common causes in order: MDE extension status, Guest Configuration extension status, Arc agent health, evaluation-cycle timing, the grouped-vs-individual transition, and default policy assignment.
- Confirm Arc agent health first (see the Arc agent issue above) — nothing else evaluates correctly if that's broken.

### Issue: Remediated an individual recommendation but Secure Score didn't move

- This is expected, not a bug. **Secure Score currently only reflects grouped (GA) recommendations** — individual recommendations don't yet contribute to the score, since they're still in preview under the new model. Use Secure Score for compliance/reporting and individual recommendations for actual day-to-day remediation; the two are tracked separately for now. See Step 2.1 and Step 2.4.

### Issue: I have too many recommendations / servers to review one by one

- This is expected once you go beyond a handful of machines — see Step 2.4 for the full guidance. In short: use the **Vulnerabilities / Misconfigurations / Secrets** category tabs to scope your view, use the **By Title** aggregation view for bulk remediation of a widespread issue, filter to **Critical/High** as your default, and use **Azure Resource Graph** (via the **Open query** button) for anything beyond roughly a few dozen machines rather than paging through the portal grid.
- Set Governance rules and Exemptions at the **security category** level (Environment settings → Governance rules / Exemption rules) rather than per finding, so ownership and automation apply fleet-wide automatically.

### Issue: Vulnerability assessment shows "No findings" immediately after enabling

- The initial scan can take 24 hours to complete after the MDE extension is deployed.
- Confirm the **MDE.Windows** or **MDE.Linux** extension shows `Provisioning succeeded` on the machine.
- If the extension is in a failed state, delete it from the Extensions blade and allow Defender for Cloud policy to re-deploy it (can take 30–60 minutes), or deploy it manually — see Step 6.1.

### Issue: FIM showing no events after creating a test file

- FIM scan cycles run every 30 minutes by default — wait at least 30 minutes after the file change.
- Confirm the monitored path in the FIM configuration matches the exact directory where the test file was created (case-sensitive on Linux).
- Verify the machine is sending data to the correct Log Analytics workspace by querying the `Heartbeat` table in that workspace.

### Issue: Sample alerts not appearing after 5 minutes

- Refresh the **Security alerts** page manually — it does not auto-refresh.
- Confirm the subscription selected in the sample alert dialog matches the subscription shown in the Defender for Cloud scope filter.
- Sample alerts are created as medium/low severity by default — check that your current filter doesn't exclude those severities.

### Issue: MDE extension deployment fails on Arc machine, or extension gallery shows "Not enabled" / "Not installed" indefinitely

- Confirm the Arc machine has outbound HTTPS (port 443) connectivity to `*.endpoint.security.microsoft.com`.
- On Windows Arc machines, confirm the `MsSense.exe` process can run — some endpoint hardening policies block it.
- Check extension deployment logs: **Azure Arc → Machines → [machine] → Extensions → MDE.Windows → View detailed status**.
- If auto-deployment via policy hasn't triggered after a recent Arc reconnect, deploy the extension manually — see the step-by-step in Step 6.1.

### Issue: A banner says "N subscriptions don't have the default policy assigned"

- This means Defender for Cloud's default security policy initiative isn't assigned to those subscriptions, which affects whether recommendations (particularly Guest Configuration ones) evaluate at all.
- Click the banner's link to open the **Security Policy** page, review the listed subscriptions, and assign the default initiative to your target subscription if it's among them.

---

## Why Defender for Servers Matters (Engineering Justification)

- **Unified posture across hybrid environments** — Arc-enabled on-premises and multi-cloud servers appear in the same Secure Score and recommendations view as Azure VMs; one dashboard for the full estate
- **Vulnerability assessment without extra scanners** — CVE findings surface via MDE integration; no Qualys agent or separate scanning infrastructure required
- **FIM closes the drift detection gap** — unauthorized changes to system files, configs, and registry are logged before they result in an incident; change events are queryable from Log Analytics
- **Automatic MDE deployment** — enabling Defender for Servers Plan 2 deploys EDR to all covered machines via extension; no separate endpoint management toolchain required, provided the Arc agent underneath is healthy
- **Secure Score as operational KPI** — recommendations are scored and prioritized; teams have a clear, measurable target rather than an unbounded backlog of hardening tasks
- **Individual recommendations as the emerging fleet-scale model** — per-finding granularity, category-level governance, and Resource Graph queryability are purpose-built for environments with dozens or hundreds of servers, where per-machine review doesn't scale
- **Alert quality over quantity** — behavioral analytics and MITRE ATT&CK mapping reduce alert noise compared to signature-only detection; each alert includes actionable context

> Combined with JIT VM Access (covered in [3-jit.md](3-jit.md)) and Azure Update Manager (covered in the [Azure Update Manager track](../Azure%20Update%20Manager/1-azure-update-manager.md)), Defender for Servers completes the three-layer posture: *access control + patch currency + runtime protection*.

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

[↑ Track README](README.md) | [↑ Repo README](../README.md) | [Bastion + JIT VM Access →](3-jit.md)
