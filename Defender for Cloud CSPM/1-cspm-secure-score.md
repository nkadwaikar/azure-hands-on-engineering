# Defender for Cloud CSPM — Part 1: Secure Score and Controls

> **Why this matters:** Secure Score is the fastest single signal that tells you whether a subscription's security configuration is improving or degrading over time. Without CSPM, misconfigured resources accumulate silently across subscriptions until an auditor — or an attacker — finds them. Defender for Cloud CSPM turns posture into a measurable, actionable KPI that engineers and leadership can track, and gives you the control-by-control breakdown needed to fix the right things first.

Last validated on: 2026-07-19
Portal experience note: Steps validated against **Microsoft Defender for Cloud → Cloud Security → Security posture** as of July 2026. The Security posture blade layout and Secure Score calculation methodology described here apply to both Foundational CSPM (free) and Defender CSPM (paid). Features gated to Defender CSPM are called out explicitly.

> **Note:** This lab targets CSPM at the subscription level. If your organisation uses Management Groups, the same controls apply at MG scope — the aggregate score is a weighted average of child subscriptions. See Step 2.3 for multi-subscription scope. This lab builds directly on the [Defender for Servers track](../Defender%20for%20Servers/README.md) — the plan enablement and Secure Score basics covered there are extended here to the full posture management workflow.

---

## Module / Track Structure

```text
Defender for Cloud CSPM/
├── README.md                        ← Track entry point
├── 1-cspm-secure-score.md           ← Lab 1: Secure Score, controls, improvement workflow (you are here)
├── 2-recommendations-triage.md      ← Lab 2: Fleet-scale recommendation triage; ARG queries
├── 3-regulatory-compliance.md       ← Lab 3: Compliance dashboard; framework mapping; export
├── 4-attack-path-analysis.md        ← Lab 4: Attack path graph; exploitable path review
└── 5-governance-rules.md            ← Lab 5: Owner assignment; SLA tracking; reporting
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Enable Defender CSPM Plan](#step-1--enable-defender-cspm-plan)
- [Step 2 — Read the Secure Score Dashboard](#step-2--read-the-secure-score-dashboard)
  - [2.1 — Subscription-level vs. tenant-wide score](#21--subscription-level-vs-tenant-wide-score)
  - [2.2 — Control health and weighting](#22--control-health-and-weighting)
  - [2.3 — Multi-subscription scope](#23--multi-subscription-scope)
- [Step 3 — Improve Your Score by Remediating a Control](#step-3--improve-your-score-by-remediating-a-control)
  - [3.1 — Identify the highest-impact control](#31--identify-the-highest-impact-control)
  - [3.2 — Quick fix vs. manual remediation](#32--quick-fix-vs-manual-remediation)
  - [3.3 — Verify score movement](#33--verify-score-movement)
- [Step 4 — Exempt a Resource from a Recommendation](#step-4--exempt-a-resource-from-a-recommendation)
- [Cleanup](#cleanup)

**Continue to:** [Lab 2 — Fleet-Scale Recommendation Triage →](2-recommendations-triage.md)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Security Admin** or **Security Reader** (read-only) at subscription scope; **Contributor** to apply remediations |
| Defender for Cloud | Must be enabled on the target subscription — navigate **Defender for Cloud → Environment settings** and confirm the subscription is listed |
| Target resources | At least one resource group with running VMs, storage accounts, or key vaults — empty subscriptions produce no meaningful score |
| Prior track | [Defender for Servers track](../Defender%20for%20Servers/README.md) recommended — Secure Score basics are introduced there; this lab builds the full CSPM workflow on top |
| Estimated time | 45–60 minutes |
| Tools | Azure Portal only |

Naming reference: [Naming Convention](../Naming-Convention.md)

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Enabled or verified the **Defender CSPM** plan on a target subscription
- Navigated the **Security posture** blade and correctly read the Secure Score at subscription level vs. tenant-wide
- Understood how **security controls** are weighted and how unhealthy resources within a control lower the score
- Improved the score by **remediating a recommendation** — using Quick Fix where available and manual remediation where not
- Understood the **exempt** workflow for resources that are intentionally non-compliant (e.g., break-glass accounts)
- Recognised the distinction between **Foundational CSPM** (free) and **Defender CSPM** (paid) feature boundaries

---

## 3. Scenario

**Your subscription passed a deployment review last quarter. Is it still compliant today?**

Resources drift. A storage account gets created without HTTPS enforcement. A Key Vault loses its diagnostic setting after a rotation script runs. A VM skips a patch window. Each of these is a misconfiguration that doesn't announce itself — it just quietly lowers your Secure Score and increases your attack surface. This lab teaches you to read that score correctly, understand what's driving it down, and fix the highest-impact issues first.

---

## Step 1 — Enable Defender CSPM Plan

### 1.1 Verify current plan status

1. In the Azure Portal, search for **Microsoft Defender for Cloud** and open it.
2. In the left menu, select **Environment settings**.
3. Expand the subscription you want to assess. Click on the subscription name to open the **Defender plans** blade.
4. Locate **Defender CSPM** in the plans list.

   | Status | What it means |
   | --- | --- |
   | **Off** | Foundational CSPM only — basic Secure Score, no attack path, no cloud security explorer |
   | **On** | Defender CSPM enabled — full feature set including attack path analysis, governance rules, and agentless scanning |

5. If **Defender CSPM** is **Off** and you want the full lab experience, toggle it **On** and click **Save**.

   > **Cost note:** Defender CSPM is billed per billable resource (VMs, storage accounts, SQL servers, etc.). For a small lab environment with 3–5 VMs the monthly cost is minimal. If you are working on a production subscription, enable on a scoped resource group rather than subscription-wide, or use a dedicated lab subscription.

### 1.2 Verify agentless scanning (Defender CSPM only)

1. On the same **Defender plans** blade, click **Settings** next to the Defender CSPM row.
2. Confirm **Agentless scanning for machines** is toggled **On**.
3. Confirm **Sensitive data discovery** is toggled **On**.
4. Click **Save** if you made changes.

   > **Why agentless matters:** Without an agent, Defender CSPM scans VM disk snapshots directly to find secrets, vulnerabilities, and misconfigurations — no extension required on the guest OS.

---

## Step 2 — Read the Secure Score Dashboard

### 2.1 Subscription-level vs. tenant-wide score

1. In the Defender for Cloud left menu, select **Cloud Security → Security posture**.
2. The large score at the top is your **tenant-wide blended average** across all subscriptions and clouds. This number is only meaningful for executive reporting — do not use it for day-to-day operations.
3. Scroll down to the **Environment** table. Each row shows an individual subscription (or AWS/GCP connector) with its own score, unhealthy resource count, and resource count.
4. Click on your **target subscription** row to scope all subsequent views to that subscription.

   > **Key principle:** Always work at subscription scope. The blended score disguises which subscriptions are healthy and which are not.

### 2.2 Control health and weighting

1. With your subscription selected, scroll to the **Security controls** section.
2. Each control card shows:
   - **Control name** (e.g., "Enable MFA", "Restrict unauthorized network access")
   - **Current points / Max points** — points earned if all resources in the control are healthy
   - **Unhealthy resources count** — how many resources are currently failing this control
   - **Potential score increase** — how many points you gain by fully remediating this control

3. Sort controls by **Potential score increase** (descending). This is your remediation priority queue.

   | Control attribute | What it signals |
   | --- | --- |
   | High max points + few unhealthy resources | High ROI — fix a small number of resources for a big score jump |
   | Low max points + many unhealthy resources | Low ROI — large remediation effort for a small score improvement |
   | 0 unhealthy resources | Healthy — no action needed |

4. Click on any control to expand it and see the individual recommendation(s) and the specific resources failing them.

### 2.3 Multi-subscription scope

If you manage multiple subscriptions under a Management Group:

1. In the **Environment settings** blade, expand the Management Group node.
2. Navigate to **Cloud Security → Security posture** at the Management Group level.
3. The **Environment** table now shows one row per child subscription. Use the **Secure Score** column to identify the weakest subscriptions first.
4. You can drill into individual subscriptions directly from this view without leaving CSPM.

---

## Step 3 — Improve Your Score by Remediating a Control

### 3.1 Identify the highest-impact control

1. From the **Security controls** list (subscription-scoped), note the control at the top of your priority list sorted by **Potential score increase**.
2. Click the control to expand it. You will see one or more recommendations listed underneath.
3. Click the first recommendation. The recommendation detail blade opens and shows:
   - **Description** — what the issue is and why it matters
   - **Affected resources** — the Unhealthy, Healthy, and Not applicable resource lists
   - **Remediation steps** — portal steps or code snippets to fix it
   - **Quick fix** button (if available)

### 3.2 Quick fix vs. manual remediation

**If a Quick Fix button appears:**

1. Click **Quick Fix**.
2. Review the list of resources to be remediated. Deselect any you want to skip.
3. Click **Remediate** to apply the configuration change across all selected resources.

   > Quick Fix applies a single targeted configuration change (e.g., "Enable secure transfer on storage account"). It does not make cascading infrastructure changes — review each fix action before applying.

**If no Quick Fix is available:**

1. Follow the step-by-step instructions in the **Remediation steps** section.
2. Common manual remediations:
   - **Enable MFA on accounts**: In Entra ID → Users → select user → Authentication methods → add MFA method.
   - **Enable diagnostic settings on Key Vault**: Key Vault → Diagnostic settings → Add diagnostic setting → select Log Analytics workspace → enable `AuditEvent` log category.
   - **Restrict public network access on storage**: Storage account → Networking → set **Public network access** to **Disabled** or **Enabled from selected virtual networks and IP addresses**.

### 3.3 Verify score movement

Secure Score does not update in real time — changes are reflected within **15–30 minutes** of a successful remediation.

1. Navigate back to **Cloud Security → Security posture**.
2. Select your target subscription in the Environment table.
3. Locate the control you remediated and confirm the **Unhealthy resources** count has decreased.
4. Note the updated **Current points** value for that control.

   > If the score hasn't moved after 30 minutes, verify the remediation was actually applied. Check the resource directly (e.g., open the storage account and confirm **Secure transfer required** is **Enabled**).

---

## Step 4 — Exempt a Resource from a Recommendation

Some resources are intentionally non-compliant — for example, a break-glass storage account that cannot have firewalls enabled because it must be reachable from any network in an emergency.

1. From a recommendation's detail blade, go to the **Unhealthy resources** tab.
2. Select the checkbox next to the resource you want to exempt.
3. Click **Exempt**.
4. Fill in:
   - **Exemption name** — descriptive, kebab-case (e.g., `breakglass-storage-public-access-exemption`)
   - **Exemption category** — **Waiver** (accepted risk) or **Mitigated** (compensating control exists)
   - **Description** — business justification, ticket number, or compensating control reference
   - **Expiration date** — set a review date; exemptions should not be permanent by default
5. Click **Create**.

   > **Governance principle:** Every exemption is an audit trail entry. The exemption name, category, justification, and expiration are all logged and visible under **Cloud Security → Workload protections → Exemptions**. Never exempt without a justification.

---

## Cleanup

This lab does not create any billable resources by itself. If you enabled **Defender CSPM** specifically for this lab on a subscription you share with others:

1. Navigate to **Defender for Cloud → Environment settings**.
2. Click on the target subscription.
3. Toggle **Defender CSPM** to **Off**.
4. Click **Save**.

Remediations applied during the lab (e.g., enabling secure transfer on a storage account) are **intentional improvements** — do not reverse them unless they conflict with a specific application requirement.

---

**Continue to:** [Lab 2 — Fleet-Scale Recommendation Triage →](2-recommendations-triage.md)

← [Back to CSPM Track README](README.md)
