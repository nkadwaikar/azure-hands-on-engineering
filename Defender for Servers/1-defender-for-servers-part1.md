# Microsoft Defender for Servers — Part 1: Setup and Security Posture

> **Why this matters:** Defender for Servers is the security brain layered on top of Azure Arc and Azure VMs. It provides threat detection, vulnerability assessment, File Integrity Monitoring, and Secure Score recommendations — all without deploying a separate SIEM agent. Enabling Defender for Servers on Arc-enabled machines brings on-premises and multi-cloud servers into the same security posture view as native Azure VMs.

**This is Part 1 of 2.** Part 1 covers Prerequisites through Step 2 (enabling the plan, verifying Arc/coverage, and working the Secure Score / Recommendations experience — including diagnosing "Not evaluated" status and scaling recommendations across a large fleet). **Part 2** ([1-defender-for-servers-part2.md](1-defender-for-servers-part2.md)) picks up at Step 3 (Vulnerability Assessment) through Cleanup.

Last validated on: 2026-07-17
Portal experience note: Steps validated against Microsoft Defender for Cloud as of July 2026; labels can vary slightly by subscription tier and feature rollout. Secure Score and Recommendations live under **Defender for Cloud → Cloud Security → Security posture** / **Recommendations** in current portal versions (see Step 2). Defender for Servers is available in two plan tiers (Plan 1 and Plan 2) — this lab focuses on Plan 2 features (FIM, vulnerability assessment, JIT) since those represent the full workload protection story.

> **Important — recommendations model transition:** Defender for Cloud is moving from **grouped recommendations** (one row aggregating all findings per resource) to **individual recommendations** (one row per finding — e.g., per vulnerable software package, per secret, per rule). Grouped recommendations are tagged **"Set for deprecation"** and are being removed from the Azure portal on **July 31, 2026**. Individual recommendations are tagged **"New version"** and are the model to build workflows around going forward. Both may appear side by side during the transition — see Step 2.4 for what this changes operationally, especially at fleet scale.
> **Note:** This lab assumes at least one running Azure VM or Arc-enabled server. For Arc server coverage, complete [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-azure-arc-hybrid-server-architecture.md) first. For Just-In-Time VM access, see [Bastion + JIT VM Access](2-jit.md) — the next lab in this track, which depends on the Defender for Servers plan enabled here.

---

## Module / Track Structure

```text
Microsoft Defender for Cloud/
├── README.md                            ← Track entry point
├── 1-defender-for-servers-part1.md       ← Lab 1a: Setup & Security Posture (you are here)
├── 1-defender-for-servers-part2.md       ← Lab 1b: Vulnerability Assessment, FIM, Alerts, MDE
└── 2-jit.md                              ← Lab 2: Bastion + JIT VM Access
```

---

## Quick Navigation — Part 1

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Enable Defender for Servers Plan](#step-1--enable-defender-for-servers-plan)
- [Step 2 — Review Secure Score and Recommendations](#step-2--review-secure-score-and-recommendations)
  - [2.2a — Diagnosing "Not Evaluated" Status](#22a-diagnosing-not-evaluated-status)
  - [2.4 — Scaling Recommendations Beyond a Single Machine](#24-scaling-recommendations-beyond-a-single-machine)

**Continue to Part 2** → [Step 3 (Vulnerability Assessment) through Cleanup](1-defender-for-servers-part2.md)

---

# Microsoft Defender for Servers — Workload Protection for Azure and Arc Servers

> **Why this matters:** Defender for Servers is the security brain layered on top of Azure Arc and Azure VMs. It provides threat detection, vulnerability assessment, File Integrity Monitoring, and Secure Score recommendations — all without deploying a separate SIEM agent. Enabling Defender for Servers on Arc-enabled machines brings on-premises and multi-cloud servers into the same security posture view as native Azure VMs.

Last validated on: 2026-07-17
Portal experience note: Steps validated against Microsoft Defender for Cloud as of July 2026; labels can vary slightly by subscription tier and feature rollout. Secure Score and Recommendations live under **Defender for Cloud → Cloud Security → Security posture** / **Recommendations** in current portal versions (see Step 2). Defender for Servers is available in two plan tiers (Plan 1 and Plan 2) — this lab focuses on Plan 2 features (FIM, vulnerability assessment, JIT) since those represent the full workload protection story.

> **Important — recommendations model transition:** Defender for Cloud is moving from **grouped recommendations** (one row aggregating all findings per resource) to **individual recommendations** (one row per finding — e.g., per vulnerable software package, per secret, per rule). Grouped recommendations are tagged **"Set for deprecation"** and are being removed from the Azure portal on **July 31, 2026**. Individual recommendations are tagged **"New version"** and are the model to build workflows around going forward. Both may appear side by side during the transition — see Step 2.4 for what this changes operationally, especially at fleet scale.

> **Note:** This lab assumes at least one running Azure VM or Arc-enabled server. For Arc server coverage, complete [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-azure-arc-hybrid-server-architecture.md) first. For Just-In-Time VM access, see [Bastion + JIT VM Access](2-jit.md) — the next lab in this track, which depends on the Defender for Servers plan enabled here.

---

## Module / Track Structure

```text
Microsoft Defender for Cloud/
├── README.md                          ← Track entry point
├── 1-defender-for-servers.md          ← Lab 1: Workload Protection (you are here)
└── 2-jit.md                           ← Lab 2: Bastion + JIT VM Access
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)

- [Step 1 — Enable Defender for Servers Plan](#step-1--enable-defender-for-servers-plan)
- [Step 2 — Review Secure Score and Recommendations](#step-2--review-secure-score-and-recommendations)
  - [2.2a — Diagnosing "Not Evaluated" Status](#22a-diagnosing-not-evaluated-status)
  - [2.4 — Scaling Recommendations Beyond a Single Machine](#24-scaling-recommendations-beyond-a-single-machine)
- [Step 3 — Run Vulnerability Assessment](#step-3--run-vulnerability-assessment)
- [Step 4 — Enable File Integrity Monitoring](#step-4--enable-file-integrity-monitoring)
- [Step 5 — Investigate a Security Alert](#step-5--investigate-a-security-alert)
- [Step 6 — Review Defender for Endpoint Integration](#step-6--review-defender-for-endpoint-integration)
  - [6.7 — Confirm the Guest Configuration Extension](#67-confirm-the-guest-configuration-extension-for-local-policy-recommendations)

- [Troubleshooting](#troubleshooting)
- [Why Defender for Servers Matters](#why-defender-for-servers-matters-engineering-justification)
- [Cleanup](#cleanup)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Security Admin** on the subscription + **Contributor** on the target resource group |
| Target machines | At least one running Azure VM **or** Arc-enabled server (Status: Connected) |
| Arc prerequisite | For Arc servers: complete [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/1-azure-arc-hybrid-server-architecture.md) first, and confirm agent status is **Connected** (not just installed) before starting this lab — see Step 1.0 |
| Log Analytics Workspace | Required for FIM data storage — workspace must exist before enabling FIM (Step 4) |
| Plan selection | **Plan 2** required for File Integrity Monitoring and vulnerability assessment (Qualys / Defender VA); Plan 1 covers foundational posture only |
| Next lab | Not required for this lab — [2-jit.md](2-jit.md) is the next lab in this track and depends on the Defender for Servers plan enabled here |
| Estimated Time | 60–90 minutes (add 15–30 minutes if an Arc agent reconnect/reinstall is needed) |
| Tools | Azure Portal, plus local shell access (PowerShell or bash) on the target machine if Arc agent troubleshooting is required |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- This lab enables Defender for Servers at **subscription level** — it will apply to all VMs and Arc machines in the subscription for the duration of the lab. Disable the plan during cleanup if testing on a production subscription.
- If your Azure tenant has multiple subscriptions in scope, the **top-level Secure Score is a blended average across all of them** — always confirm the score and unhealthy-resource count for your **specific target subscription** (via the Environment table under Security posture) rather than relying on the tenant-wide number. See Step 2.1.
- **Secure Score currently reflects only grouped recommendations.** Individual recommendations (the "New version" tagged ones) do not yet affect Secure Score as of this writing — Microsoft has flagged this as a known, temporary gap during the transition. Don't be alarmed if remediating individual recommendations doesn't move the score; continue using Secure Score for grouped-recommendation compliance/reporting, and individual recommendations for actual day-to-day risk reduction. See Step 2.1 and Step 2.4.
- Defender for Endpoint (MDE) integration is automatic once Defender for Servers Plan 2 is enabled **and the target machine's Arc agent is healthy and Connected** — no separate MDE deployment step is required for supported OS versions under normal conditions. If the Arc agent is disconnected or has stale identity info, the MDE extension will not deploy until that's resolved — see Step 1.0 and Troubleshooting.
- A large batch of Recommendations (particularly Guest Configuration / local-policy audit checks such as "Audit Credential Validation," "Audit PNP Activity," etc.) depend on the **Guest Configuration extension**, a separate extension from MDE. If these stay stuck at **Not evaluated**, check that extension specifically — see Step 6.7.
- **This lab was validated against a single target machine.** If you're rolling this out across a larger fleet (10, 50, 100+ servers), see Step 2.4 for how the individual-recommendations model and Azure Resource Graph change the practical workflow at scale — the per-machine steps in this lab still apply for initial validation, but aren't how you'd operate day-to-day across a large fleet.
- Just-In-Time (JIT) VM Access is covered separately in [2-jit.md](2-jit.md), the next lab in this track.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Verified Arc agent health and re-established connectivity if the agent shows Disconnected or an Unknown version
- Enabled **Defender for Servers Plan 2** at subscription level and verified coverage of Azure VMs and Arc machines
- Reviewed the **Secure Score** — both the tenant-wide blended figure and your target subscription's actual score — and understood how recommendations are prioritized and remediated
- Understood the ongoing transition from **grouped** to **individual** recommendations, and how to triage findings at fleet scale using category tabs, aggregation views, and Azure Resource Graph
- Run a **vulnerability assessment** and reviewed the CVE findings on a target machine
- Enabled **File Integrity Monitoring (FIM)** and validated that change events are logged to Log Analytics
- Triggered and investigated a **test security alert** using Defender's built-in test mechanism
- Understood how **Defender for Endpoint (MDE)** auto-integrates with Defender for Servers, and how to deploy it manually if auto-deployment stalls
- Understood the role of the **Guest Configuration extension** in evaluating local-policy recommendations, separate from MDE

---

## 3. Scenario

**Your servers are running — but are they secure?**

Misconfigured services, outdated software with known CVEs, and unauthorized file changes are the three most common precursors to a breach. Defender for Servers surfaces all three in a single dashboard. This lab walks through enabling the plan, closing the most actionable recommendations, and validating that the monitoring pipeline fires when something changes.

---

## Step 1 — Enable Defender for Servers Plan

### 1.0 Verify Arc Agent Health (Arc machines only — do this first)

Before enabling the plan, confirm the target Arc machine is actually **Connected**, not just installed. A disconnected or stale agent silently blocks every later step in this lab (Inventory coverage, MDE extension deployment, Secure Score evaluation) even if the plan itself is enabled correctly at the subscription level.

1. On the target machine, open an elevated shell and run:

   ```powershell
   azcmagent show
   ```

2. Check the **Agent Status** field:
   - **Connected** with populated Resource Name, Resource Group, Subscription ID, Tenant ID, and a recent **Agent Last Heartbeat** → healthy, proceed to 1.1.
   - **Disconnected** with blank identity fields, or **Agent Version: Unknown** in the portal's Extensions blade → the agent has lost its registration. Continue below.

3. **If disconnected**, first attempt a normal reconnect:

   ```powershell
   azcmagent connect --resource-group "<your-rg>" --tenant-id "<tenant-id>" --location "<region>" --subscription-id "<sub-id>" --cloud "AzureCloud"
   ```

   You'll be prompted for device code login unless using a service principal.

4. **If reconnect fails, or you want a guaranteed clean state**, perform a full uninstall/reinstall:

   ```powershell
   # 1. Disconnect locally (works even without valid Azure connectivity)
   azcmagent disconnect --force-local-only

   # 2. Uninstall the agent
   Get-Package -Name "Azure Connected Machine Agent" | Uninstall-Package

   # 3. Remove leftover state, then reboot
   Remove-Item -Path "C:\ProgramData\AzureConnectedMachineAgent" -Recurse -Force -ErrorAction SilentlyContinue
   Remove-Item -Path "C:\Program Files\AzureConnectedMachineAgent" -Recurse -Force -ErrorAction SilentlyContinue
   ```

   Optionally, delete the stale resource in the portal first (**Azure Arc → Machines → [machine] → Delete**) to avoid a duplicate/conflicting resource ID on re-onboarding.

   ```powershell
   # 4. Reinstall
   Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" -OutFile "AzureConnectedMachineAgent.msi"
   msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn

   # 5. Re-connect (or run the fresh onboarding script generated by Azure Arc → Machines → Add → Add a single server)
   azcmagent connect --resource-group "<your-rg>" --tenant-id "<tenant-id>" --location "<region>" --subscription-id "<sub-id>" --cloud "AzureCloud"
   ```

5. Confirm with `azcmagent show` again: **Agent Status: Connected**, identity fields populated, recent heartbeat.
6. In the portal, confirm under **Azure Arc → Machines → [machine] → Extensions**, the agent version now displays correctly (not "Unknown").

> **Note:** "Agent Version: Unknown" in the Extensions blade is a stronger signal than the routine "a newer agent version is available" banner — it typically means the portal isn't receiving current heartbeat data at all, which points to a Disconnected or corrupted local agent rather than a simple version lag.

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
5. The **Defender for Cloud** column should show **On** for covered machines. The Inventory grid also has separate **Defender extension** and **Monitoring extension** columns — these track whether MDE and the monitoring agent have actually finished deploying, and can lag behind the plan-level "On" status. Both may show **Not enabled** / **Not installed** for a period after enabling the plan or after an Arc reconnect — this is expected and resolves automatically within 30–60 minutes. See Step 6.1 if it doesn't.

---

## Step 2 — Review Secure Score and Recommendations

### 2.1 Understand Secure Score

1. In **Defender for Cloud**, expand **Cloud Security** in the left nav → select **Security posture**.
2. At the top, the **Azure environment** panel shows:
   - **Secure score** — the overall percentage across every subscription currently in scope for your session
   - **Environment risk** — Critical recommendations and Attack paths counts
   - **All recommendations by risk** — a breakdown by Critical / High / Medium / Low / **Not evaluated**
3. **If multiple subscriptions are shown** (check the "Showing N subscriptions" text under the page title), the top **Secure score** is a **blended average** — it is not specific to any one subscription. Scroll down to the **Environment** tab table, which lists each subscription individually with its own **Secure score** and **Unhealthy resources** count. Find your actual target subscription in that list and use its individual score, not the blended total, as your working baseline.
4. Click **View recommendations >** next to your target subscription's row to jump straight to recommendations scoped to that subscription.
5. The score is driven by **Security controls** — groups of related recommendations. Completing all recommendations in a control gives you that control's maximum point contribution. Control-level detail is visible from the full posture view.
6. **Important:** Secure Score currently reflects only **grouped (GA) recommendations**. **Individual recommendations do not currently affect Secure Score**, since they're still in preview under the new model. Remediating an individual recommendation is real risk reduction, but don't expect it to move this number yet — see Step 2.4 for the practical implication.

### 2.2 Explore Recommendations

1. From **Security posture**, click **View recommendations >** on your target subscription's row (or select **Recommendations** directly from the **Cloud Security** left-nav group).
2. Use the **Environment type** filter at the top to narrow to **Azure** if you have other cloud providers connected.
3. Sort by **Risk level** (Critical first) to see the highest-impact items. Note that many recommendations may show **Not evaluated** rather than a severity — see the note below before assuming something is broken.
4. Click on a recommendation to see:
   - **Why this recommendation:** The security risk it addresses
   - **Affected resources:** Which machines are non-compliant
   - **Remediation steps:** Portal-guided fix or policy-driven auto-remediation
5. Select one Critical or High recommendation and walk through the remediation steps to close it.

> **Note:** If recommendations show as **Not evaluated** rather than a severity, this can mean one of a few things — see Step 2.2a for how to actually diagnose it, rather than guessing.

### 2.2a Diagnosing "Not Evaluated" Status

"Not evaluated" means Defender for Cloud hasn't been able to assess the machine against that recommendation yet — it isn't a severity, and it isn't automatically a problem. Work through these steps in order to find out which of the four common causes applies to your machine.

1. **Click into the recommendation itself first.** Open the "Not evaluated" recommendation and expand the affected machine row. Many recommendations show a specific reason directly in the UI (e.g., "Extension not installed," "Awaiting first scan," "Not applicable to this resource type") — check here before assuming anything.

2. **Check whether the recommendation depends on MDE.** Go to **Inventory** (or **Azure Arc → Machines → [machine] → Extensions**) and look at the **Defender extension** column / **MDE.Windows / MDE.Linux** status.
   - If it's **Not enabled** or **Provisioning** → this is your cause. Wait 30–60 minutes, or deploy it manually per Step 6.1.
   - If it shows **Provisioning succeeded** → move to the next check.

3. **Check whether the recommendation depends on Guest Configuration instead.** Recommendations worded like "Ensure 'Audit _**'..." or "Configure '**_'" are evaluated by the Guest Configuration extension, not MDE.
   - Go to **Azure Arc → Machines → [machine] → Extensions** and look for **ConfigurationforWindows** / **ConfigurationforLinux**.
   - If missing or not succeeded → this is your cause. See Step 6.7 to deploy it.
   - Guest Configuration also evaluates on a longer cycle than MDE — allow several hours after installation before expecting a result, even when healthy.

4. **Check the underlying Arc agent connection.** If the machine's Arc agent is Disconnected or has an unclear identity (Step 1.0), nothing above will evaluate correctly regardless of extension status. Run `azcmagent show` on the machine and confirm **Agent Status: Connected** with a recent heartbeat before troubleshooting extensions further.

5. **Check if the recommendation is simply new or recently in scope.** A newly enabled plan, a newly onboarded machine, or a machine that was just reconnected needs its first full evaluation cycle to complete. This can take:
   - Up to 30–60 minutes for MDE-driven recommendations
   - Up to several hours for Guest Configuration recommendations
   - Up to 24 hours for the first vulnerability assessment scan (Step 3)

6. **Check whether it's a grouped recommendation on its way out.** If the recommendation is tagged **"Set for deprecation"** (and often paired with a **"New version"** tag pointing to its individual-recommendation replacement), "Not evaluated" can reflect Microsoft's in-progress migration away from the grouped model (portal removal **July 31, 2026**) rather than anything wrong on your machine. Filter to the **"New version"** tag to see if the individual-recommendation equivalent already has a real severity — if it does, the grouped entry's status can usually be ignored. See Step 2.4.

7. **Confirm the default security policy is assigned to your subscription.** Some recommendations (especially Guest Configuration ones) won't evaluate at all if the underlying policy initiative isn't assigned. Check **Defender for Cloud → Environment settings → [subscription] → Security Policy**, or look for a banner reading _"N subscriptions don't have the default policy assigned"_ on the Security posture page. Assign the default initiative if your subscription is listed.

8. **If all of the above check out and it's still "Not evaluated" after 24 hours**, treat it as a genuine issue rather than a timing gap — recheck extension deployment logs (**Extensions → [extension name] → View detailed status**) for an explicit failure reason, or see Troubleshooting.

### 2.3 Track Recommendation Changes

After remediating a recommendation:

1. Return to **Defender for Cloud → Cloud Security → Security posture** — note the current score for your target subscription (not just the blended total). Remember this only reflects grouped-recommendation remediation (Step 2.1).
2. Score updates are not real-time; expect 30–60 minutes for the score to reflect remediated items.
3. Remediated recommendations move to the **Completed** tab in **Recommendations** — check there to confirm your fix registered.

### 2.4 Scaling Recommendations Beyond a Single Machine

The single-machine workflow above (Steps 2.2–2.3) is fine for validating the lab on one server, but it does not scale to a real fleet. If you're managing 10, 50, or 100+ servers, work through the numbered steps below instead of reviewing machines one by one.

1. **Understand what changed: grouped vs. individual recommendations.** Before touching the portal, know which model you're looking at:

   | | Grouped recommendations (old) | Individual recommendations (new) |
   | --- | --- | --- |
   | Structure | One row per resource, aggregating every finding on it (e.g., all CVEs on a VM rolled into one row) | One row per finding (e.g., one row per vulnerable software package, one per secret) |
   | Tag shown in portal | **Set for deprecation** | **New version** |
   | Status | Being removed from the Azure portal on **July 31, 2026** | The model to standardize on now |
   | Row count at scale | Lower — one row per machine | Higher — one row per finding, across all machines |

   Both may appear in your Recommendations list at the same time right now — that's expected during the transition, not a bug.

2. **Pick a category tab first.** At the top of the Recommendations page, click one of: **All**, **Misconfigurations**, **Vulnerabilities**, **Secrets**. Don't work from **All** by default — it mixes every finding type together. Pick the tab matching what you're actually triaging right now (e.g., **Vulnerabilities** if you're chasing CVEs this week).

3. **Choose the right view for what you're doing.** Three view buttons sit near the top-right of the page: **Flat list**, **By Title**, **By Resource**. Pick based on your task:

   | Your goal | View to use | What it shows |
   | --- | --- | --- |
   | Fix one issue everywhere it appears (e.g., patch one vulnerable package across every affected machine) | **By Title** | One row per recommendation, with every affected machine listed underneath it |
   | Investigate one specific machine in depth | **By Resource** | One row per machine, with every finding on it listed underneath |
   | Export or filter across everything | **Flat list** | Every individual finding as its own row |

   For fleet-wide remediation work, **By Title** is almost always the answer — it's still fully supported going forward and is Microsoft's recommended view for bulk fixes, even under the new individual-recommendations model.

4. **Filter to Critical and High first.** Once you've picked a category and view, filter **Risk level** to **Critical** and **High** before doing anything else. Treat this filtered view as your default working queue — with individual recommendations, the unfiltered list at fleet scale is too large to work through top to bottom.

5. **Set up ownership and automation once, at the category level**, instead of assigning an owner or exemption to individual findings one at a time:
   - Go to **Environment settings → Governance rules** (or **Exemption rules**).
   - Create a rule scoped to a **security category** (e.g., "all Vulnerability findings" or "all Secrets findings") rather than a specific recommendation.
   - That rule automatically applies to every current and future individual recommendation in that category — this is how ownership, due dates, and exemptions get applied fleet-wide without repeating the setup per finding.

6. **For anything past a few dozen machines, query it instead of scrolling it:**
   - On the Recommendations page, click **Open query** in the toolbar — this generates a starting KQL query in Azure Resource Graph (ARG) scoped to whatever recommendation/category you were viewing.
   - Run and refine it in **Azure Resource Graph Explorer** to filter, aggregate, or export findings across your whole fleet in one pass.
   - For vulnerability findings specifically, query the `SoftwareUpdate` category directly rather than the old per-machine aggregation:

     ```kql
     securityresources
     | where type == "microsoft.security/assessments"
     | where properties.metadata.recommendationCategory == "SoftwareUpdate"
     | project resourceId = properties.resourceDetails.Id, recommendation = properties.displayName, severity = properties.status.severity
     ```

   > If you have existing dashboards or automation built against the old **Sub Assessment APIs** or grouped recommendation keys, plan to migrate them to the **Assessment APIs** / individual `securityFindings` equivalents — the grouped keys they depend on are being removed.

7. **If grouped and individual recommendations side by side are causing confusion**, filter explicitly to one tag rather than leaving both visible:
   - **"New version"** → shows only individual recommendations (use this as your working view)
   - **"Set for deprecation"** → shows only grouped recommendations (reference only, being removed July 31, 2026)

   Standardize your team on individual recommendations for day-to-day work. Keep using Secure Score (Step 2.1) for compliance/reporting — remember it currently only reflects grouped recommendations, so it's a separate metric from the queue you're actually working.

---

## Continue to Part 2

Part 1 ends here. **Part 2** picks up at Step 3 — Run Vulnerability Assessment, and continues through Step 4 (File Integrity Monitoring), Step 5 (Security Alerts), Step 6 (Defender for Endpoint Integration), Troubleshooting, Why Defender for Servers Matters, and Cleanup.

**→ [Continue to Part 2: 1-defender-for-servers-part2.md](1-defender-for-servers-part2.md)**

---

[↑ Track README](README.md) | [↑ Repo README](../README.md) | [Continue to Part 2 →](1-defender-for-servers-part2.md)
