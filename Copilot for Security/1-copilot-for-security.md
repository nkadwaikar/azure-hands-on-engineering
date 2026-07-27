# Microsoft Security Copilot — Incident Investigation and SOC Workflows

> **Why this matters:** Security operations teams are overwhelmed by alert volume and context-switching across Defender XDR, Sentinel, Entra ID, and Purview. Microsoft Security Copilot surfaces natural-language summaries, correlated signals, and guided remediation steps directly inside those tools — cutting triage time from hours to minutes. This lab builds the end-to-end pattern: provisioning capacity, configuring RBAC, connecting plugins, and running real investigation workflows using promptbooks and embedded Copilot experiences.

Last validated on: July 2026
Portal experience note: Steps validated against Microsoft Security Copilot (securitycopilot.microsoft.com) and the embedded Copilot experiences in Microsoft Defender XDR and Microsoft Entra ID as of July 2026. UI labels can vary slightly by tenant configuration and feature rollout.

> **Note:** This lab assumes Microsoft Defender for Servers Plan 2 is active on the subscription and at least one Log Analytics Workspace is connected to Microsoft Sentinel or Defender XDR. Complete the [Identity-First Track](../Identity-First/README.md) and [Defender for Servers Track](../Defender%20for%20Servers/README.md) first.

---

## Module / Track Structure

```text
Copilot for Security/
├── README.md                             ← Track entry point
└── 1-copilot-for-security.md             ← Lab 1: Provisioning, RBAC, plugins, promptbooks, investigation (you are here)
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Provision Security Compute Units](#step-1--provision-security-compute-units)
- [Step 2 — Configure RBAC](#step-2--configure-rbac)
- [Step 3 — Connect Plugins](#step-3--connect-plugins)
- [Step 4 — Incident Summarisation](#step-4--incident-summarisation)
- [Step 5 — Identity Investigation](#step-5--identity-investigation)
- [Step 6 — KQL Assistance](#step-6--kql-assistance)
- [Step 7 — Build a Promptbook](#step-7--build-a-promptbook)
- [Step 8 — Audit Copilot Sessions](#step-8--audit-copilot-sessions)
- [Troubleshooting](#troubleshooting)
- [What I Learned](#what-i-learned)
- [Cleanup](#cleanup)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Global Administrator** or **Security Administrator** to provision SCUs and configure RBAC |
| Copilot Role | **Security Copilot Owner** to manage plugins and promptbooks; **Security Copilot Contributor** for investigation tasks |
| Defender for Servers | Plan 2 active — complete [Defender for Servers Track](../Defender%20for%20Servers/README.md) first |
| Identity foundation | Complete [Identity-First Track](../Identity-First/README.md) — RBAC and Conditional Access are prerequisites for identity investigation workflows |
| Licensing | Microsoft Security Copilot capacity (Security Compute Units — SCUs); minimum 1 SCU for lab use |
| Region | SCU capacity is provisioned in a specific Azure region; data residency applies — select the region that aligns with your data boundary requirements |
| Estimated Time | 90–120 minutes |
| Tools | Azure Portal, Security Copilot portal (securitycopilot.microsoft.com), Microsoft Defender XDR portal (security.microsoft.com), Microsoft Entra admin center |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- SCUs are billed by the hour from the moment they are provisioned. The cleanup step at the end of this lab deletes the SCU capacity to stop billing — complete cleanup promptly after finishing the lab.
- Security Copilot data residency is governed by the region you select during provisioning. Prompts, responses, and session data are stored in that region. Understand your data boundary requirements before selecting a region in a production tenant.
- This lab uses the **standalone Security Copilot portal** for prompt-level work and **embedded Copilot experiences** in Defender XDR and Entra ID for in-context investigation. Both surface the same underlying model but different UI entry points.
- The embedded Copilot experience in Defender XDR requires the tenant to have Microsoft Defender XDR licensed and active.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Provisioned **Security Compute Units (SCUs)** and understood the capacity and billing model
- Configured **Copilot for Security RBAC** — Owner and Contributor roles — with least-privilege access
- Connected and verified **Microsoft plugins** (Defender XDR, Sentinel, Entra ID, Intune, Purview)
- Summarised a **Defender XDR incident** using natural language in the embedded Copilot experience
- Investigated a **risky user** in Entra ID using Copilot's identity investigation prompt flow
- Generated and refined a **KQL query** using Copilot assistance in Log Analytics
- Built a reusable **promptbook** for a repeatable SOC triage workflow
- Reviewed **Copilot session audit logs** in Microsoft Purview Audit to validate the activity trail

---

## 3. Scenario

**Your SOC is triaging faster — but correlation across tools still takes too long.**

A security alert fires in Defender XDR. Investigating it fully means pivoting to Entra ID for sign-in context, querying Log Analytics for related events, and cross-referencing Purview for any data exfiltration signals — all manually. Security Copilot removes that pivot-and-correlate burden: it pulls context from every connected source and surfaces a coherent narrative in a single prompt. This lab builds that capability from scratch.

---

## Step 1 — Provision Security Compute Units

Security Copilot capacity is provisioned as Security Compute Units (SCUs) in Azure. Each SCU provides a fixed compute throughput; most lab workloads run comfortably on 1–2 SCUs.

1. Go to the **Azure Portal** → search for **Microsoft Security Copilot**
2. Click **Set up Security Copilot**
3. Select your **Azure subscription** and **resource group**
4. Choose a **capacity name** (e.g., `scu-lab-eus`) following your naming convention
5. Set **Security Compute Units** to `1` for lab use
6. Select a **region** — choose the Azure region closest to your data residency requirement
7. Review the estimated cost shown (charged per SCU per hour)
8. Click **Review + create** → **Create**
9. Once provisioning completes, navigate to **securitycopilot.microsoft.com**
10. Confirm the portal loads and displays your tenant name in the top-right corner

> **Capacity note:** 1 SCU supports roughly 10 concurrent users for light investigation tasks. For the purposes of this lab (single user, sequential prompts), 1 SCU is sufficient. Production SOC deployments typically start at 3–5 SCUs.

---

## Step 2 — Configure RBAC

Security Copilot has two built-in roles, separate from Azure RBAC:

| Role | What it allows |
| --- | --- |
| **Security Copilot Owner** | Manage capacity, configure plugins, create and share promptbooks, access all sessions |
| **Security Copilot Contributor** | Submit prompts, use promptbooks, view own sessions — no plugin or capacity management |

### 2.1 Assign the Security Copilot Owner Role

1. In the Security Copilot portal, click the **Settings** gear icon (top right) → **Roles**
2. Under **Security Copilot Owner**, click **Add members**
3. Search for and select your admin account
4. Click **Add** → confirm the assignment appears in the members list

### 2.2 Assign the Security Copilot Contributor Role

1. Still in **Settings → Roles**, under **Security Copilot Contributor**, click **Add members**
2. Add a test user account (e.g., the test user created in [Identity-First Lab 1](../Identity-First/01-identity-fundamentals.md))
3. Click **Add**

### 2.3 Validate Least-Privilege Access

1. Open a private browser window and sign in as the Contributor test user
2. Navigate to **securitycopilot.microsoft.com**
3. Confirm the user can submit prompts but **cannot** access Settings → Roles or manage plugins
4. Close the private window

---

## Step 3 — Connect Plugins

Plugins give Security Copilot access to data sources. Microsoft first-party plugins require no credential configuration — they use the signed-in user's existing permissions.

1. In the Security Copilot portal, click **Settings** → **Plugins**
2. Under **Microsoft plugins**, enable the following (toggle each to **On**):
   - **Microsoft Defender XDR** — incident and alert data
   - **Microsoft Sentinel** — SIEM events and analytics rules (if Sentinel is active on your workspace)
   - **Microsoft Entra** — sign-in logs, risky users, Conditional Access policies
   - **Microsoft Intune** — device compliance state
   - **Microsoft Purview** — data classification and DLP alert context
3. For each plugin, click **Configure** and confirm the workspace or subscription binding is correct
4. Click **Save** after enabling all plugins
5. Run a test prompt to confirm plugin connectivity:
   ```
   List the top 5 open incidents in Microsoft Defender XDR.
   ```
   The response should return real incident data from your Defender XDR tenant — not a "no data found" message.

> **Permissions note:** Copilot for Security uses the calling user's permissions to query each data source. If you don't have Security Reader on a Sentinel workspace, those queries will return empty results even if the plugin is enabled.

---

## Step 4 — Incident Summarisation

### 4.1 Summarise an Incident in the Standalone Portal

1. In **securitycopilot.microsoft.com**, open a **New session**
2. Enter the following prompt (replace `<incident-id>` with a real incident ID from Defender XDR):
   ```
   Summarize Defender XDR incident <incident-id>. Include the attack timeline,
   affected entities, and the top three recommended remediation actions.
   ```
3. Review the response — it should include:
   - Natural language summary of what happened and when
   - List of affected users, devices, and IP addresses
   - Correlated alerts grouped by kill chain stage
   - Recommended next steps

### 4.2 Use the Embedded Experience in Defender XDR

1. Go to **security.microsoft.com** → **Incidents & alerts** → **Incidents**
2. Open any active incident
3. Click the **Copilot** icon in the top-right of the incident page (or look for the **Summarize** button in the incident header)
4. Copilot will auto-generate a summary scoped to that incident's data — no prompt needed
5. Scroll through the summary and click **Show evidence** to expand correlated alerts

---

## Step 5 — Identity Investigation

### 5.1 Investigate a Risky User

1. In the Security Copilot standalone portal, enter:
   ```
   In Microsoft Entra ID, show me the recent sign-in activity and risk events
   for user <upn>. Summarize any anomalies and suggest remediation steps.
   ```
2. The response should pull from Entra ID Protection and Identity logs, returning:
   - Recent sign-in locations and device details
   - Risk level (Low / Medium / High) and risk event type
   - Suggested actions (e.g., reset password, block sign-in, require MFA step-up)

### 5.2 Review Conditional Access Gaps

1. Continue the same session and add:
   ```
   Are there any Conditional Access policies that currently exclude this user
   or that this user's recent risky sign-in bypassed?
   ```
2. Review the Copilot response for policy gaps and cross-reference with the Conditional Access blade in Entra ID to validate the finding

---

## Step 6 — KQL Assistance

Security Copilot can generate, explain, and refine KQL queries without requiring the analyst to know KQL syntax.

### 6.1 Generate a KQL Query

1. In the Security Copilot portal, enter:
   ```
   Write a KQL query for Microsoft Sentinel that finds all successful sign-ins
   from IP addresses that also appear in the last 7 days of failed sign-in logs.
   ```
2. Copilot returns a KQL query block — review it for accuracy

### 6.2 Copy and Run in Log Analytics

1. Copy the generated query
2. Go to **Azure Portal** → **Log Analytics Workspace** → **Logs**
3. Paste the query and click **Run**
4. If the query returns errors, return to Copilot and ask:
   ```
   The query returned this error: <paste error text>. Fix it.
   ```
5. Copilot will diagnose and correct the syntax

### 6.3 Explain an Existing Query

1. Paste an unfamiliar KQL query into Copilot and ask:
   ```
   Explain what this KQL query does, step by step:
   <paste query here>
   ```
2. Copilot returns a plain-language breakdown of each clause

---

## Step 7 — Build a Promptbook

Promptbooks are saved, reusable sequences of prompts — the equivalent of a runbook for Copilot investigations.

### 7.1 Create a Phishing Triage Promptbook

1. In the Security Copilot portal, click **Promptbooks** (left sidebar) → **New promptbook**
2. Name it `Phishing Triage` and add a description
3. Add the following prompts in sequence:

   **Prompt 1:**
   ```
   Summarize Defender XDR incident {{IncidentId}}. Focus on email-related alerts
   and affected mailboxes.
   ```

   **Prompt 2:**
   ```
   List all email addresses and domains involved in the phishing campaign
   from this incident. Flag any that are newly registered or have low reputation.
   ```

   **Prompt 3:**
   ```
   Check Microsoft Entra ID for any users from this incident who have
   performed suspicious actions (e.g., inbox rule creation, forwarding rule,
   OAuth consent) in the last 48 hours.
   ```

   **Prompt 4:**
   ```
   Summarize recommended containment actions for this phishing incident
   as a numbered checklist.
   ```

4. Click **Save promptbook**

### 7.2 Run the Promptbook

1. Go to **Promptbooks** → select `Phishing Triage`
2. Click **Run** — Copilot will prompt you to supply the `{{IncidentId}}` input variable
3. Enter a real incident ID and observe each prompt executing in sequence
4. Review the final summary checklist

---

## Step 8 — Audit Copilot Sessions

All Security Copilot activity is logged to Microsoft Purview Audit.

1. Go to **Microsoft Purview** → **Audit** → **New search**
2. Set the date range to the last 24 hours
3. Under **Activities**, search for and select:
   - `SecurityCopilot.PromptSubmitted`
   - `SecurityCopilot.PromptbookRun`
4. Click **Search**
5. Review the audit records — each entry shows:
   - The user who submitted the prompt
   - Timestamp and session ID
   - Plugins queried during the session
6. Confirm your test Contributor user's activity appears in the audit log

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
| --- | --- | --- |
| Portal shows "No capacity found" | SCU provisioning incomplete or wrong subscription | Verify SCU resource exists in Azure Portal under the correct subscription |
| Plugin returns no data | Insufficient permissions for the querying user | Confirm the user has Security Reader on the Sentinel workspace and Defender XDR access |
| Promptbook variable not resolving | Variable name in `{{}}` doesn't match the input field name | Check that the variable name is consistent across all prompts in the promptbook |
| Audit log shows no Copilot events | Purview Audit not enabled | Go to **Purview → Audit → Audit log search** and confirm auditing is turned on for the tenant |
| Embedded Copilot not visible in Defender XDR | Feature not yet rolled out to tenant | Check Microsoft 365 Roadmap for the feature rollout status; use the standalone portal in the interim |

---

## What I Learned

- Security Copilot doesn't replace analyst judgment — it removes the **context-gathering burden** so judgment can be applied faster
- The **SCU billing model** means capacity management matters: idle SCUs still bill; right-size for actual concurrent usage
- **Promptbooks** encode institutional knowledge — a phishing triage promptbook built once runs the same way for every analyst, every time
- The **Contributor role** is sufficient for day-to-day analyst work; Owner rights should be tightly scoped to SOC leads and administrators
- **Plugin permissions cascade**: Copilot surfaces only what the signed-in user's own permissions allow — it doesn't elevate access, it aggregates it

---

## Cleanup

> Remove SCU capacity immediately after finishing this lab to stop billing.

1. Go to **Azure Portal** → search for **Microsoft Security Copilot**
2. Select your SCU capacity resource (e.g., `scu-lab-eus`)
3. Click **Delete** → confirm deletion
4. Verify the Security Copilot portal at **securitycopilot.microsoft.com** shows "No capacity provisioned"

---

**Track:** [Copilot for Security](README.md)
**Related:** [Identity-First Track](../Identity-First/README.md) · [Defender for Servers Track](../Defender%20for%20Servers/README.md) · [Microsoft 365 Track](../Microsoft%20365/README.md)
