# Defender for Cloud CSPM — Part 3: Regulatory Compliance

> **Why this matters:** A Secure Score tells you your posture is 72%. A regulatory compliance dashboard tells you which specific CIS or NIST controls are failing and gives auditors the evidence they need. For regulated industries — finance, healthcare, government — the compliance dashboard is the difference between passing an audit with documented evidence and scrambling to assemble screenshots the week before a review.

Last validated on: 2026-07-19
Portal experience note: Steps validated against **Microsoft Defender for Cloud → Regulatory compliance** as of July 2026. Available compliance standards vary by subscription region, plan tier, and Azure policy initiative availability. The standards listed in this lab (CIS, NIST, PCI-DSS, ISO 27001) are available in all commercial Azure regions.

> **Note:** Regulatory compliance in Defender for Cloud is built on **Azure Policy initiatives** mapped to compliance framework controls. Adding a compliance standard assigns a policy initiative to your subscription — this is a non-destructive read-only audit operation by default; no existing resources are modified.

---

## Module / Track Structure

```text
Defender for Cloud CSPM/
├── README.md                        ← Track entry point
├── 1-cspm-secure-score.md           ← Lab 1: Secure Score, controls, improvement workflow
├── 2-recommendations-triage.md      ← Lab 2: Fleet-scale recommendation triage; ARG queries
├── 3-regulatory-compliance.md       ← Lab 3: Compliance dashboard; framework mapping; export (you are here)
├── 4-attack-path-analysis.md        ← Lab 4: Attack path graph; exploitable path review
└── 5-governance-rules.md            ← Lab 5: Owner assignment; SLA tracking; reporting
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Open the Regulatory Compliance Dashboard](#step-1--open-the-regulatory-compliance-dashboard)
- [Step 2 — Add a Compliance Standard](#step-2--add-a-compliance-standard)
- [Step 3 — Navigate Controls and Assessments](#step-3--navigate-controls-and-assessments)
  - [3.1 — Control pass/fail and assessment detail](#31--control-passfail-and-assessment-detail)
  - [3.2 — Understand assessment-to-control mapping](#32--understand-assessment-to-control-mapping)
- [Step 4 — Export a Compliance Report](#step-4--export-a-compliance-report)
  - [4.1 — PDF export for auditors](#41--pdf-export-for-auditors)
  - [4.2 — CSV export for engineering teams](#42--csv-export-for-engineering-teams)
- [Step 5 — Create a Custom Compliance Initiative (Optional)](#step-5--create-a-custom-compliance-initiative-optional)
- [Cleanup](#cleanup)

**Continue to:** [Lab 4 — Attack Path Analysis →](4-attack-path-analysis.md)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Security Admin** to add compliance standards; **Security Reader** to view the dashboard and export reports |
| Defender for Cloud | Enabled on the target subscription |
| Prior labs | [Lab 1 — Secure Score](1-cspm-secure-score.md) and [Lab 2 — Recommendation Triage](2-recommendations-triage.md) recommended — compliance controls map directly to Secure Score recommendations |
| Estimated time | 30–45 minutes |
| Tools | Azure Portal only |

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Opened the **Regulatory compliance** dashboard and read the overall compliance posture for a subscription
- Added a **compliance standard** (e.g., CIS Azure Foundations Benchmark, NIST SP 800-53) to your subscription
- Navigated the control-level pass/fail breakdown and understood which **assessments** map to which **compliance controls**
- Exported a **PDF compliance report** suitable for auditors and a **CSV report** for engineering teams
- Understood how Azure Policy initiatives back each compliance standard and how to trace a failed control back to its policy definition

---

## 3. Scenario

**An auditor has requested evidence that your Azure environment meets CIS Azure Foundations Benchmark controls. You have two days to prepare.**

This is a real scenario in regulated environments. The Regulatory compliance dashboard is how you respond — it maps your current resource configuration against the benchmark's controls, shows you exactly which ones are failing, and generates a downloadable report you can hand to the auditor.

---

## Step 1 — Open the Regulatory Compliance Dashboard

1. In **Microsoft Defender for Cloud**, select **Cloud Security → Regulatory compliance** from the left menu.
2. The dashboard opens showing your currently assigned compliance standards and your overall compliance percentage per standard.
3. Note the layout:
   - **Top row** — Summary cards showing the number of passed/failed controls per standard
   - **Standards row** — One card per assigned standard; click any card to drill into it
   - **Controls breakdown** — Lists all control domains and their pass/fail counts

4. The default view may show the **Microsoft Cloud Security Benchmark (MCSB)** — Microsoft's own baseline that is assigned automatically when Defender for Cloud is enabled. Use MCSB as your day-to-day baseline; add sector-specific standards (CIS, NIST, PCI-DSS) as needed.

---

## Step 2 — Add a Compliance Standard

1. Click **Manage compliance policies** (link at the top of the Regulatory compliance blade).
   - This opens **Environment settings → Security policies** for your subscription.
2. Scroll down to the **Industry & regulatory standards** section.
3. Browse the available standards. Common ones:

   | Standard | Use case |
   | --- | --- |
   | **CIS Azure Foundations Benchmark v2.0.0** | General Azure security baseline; widely accepted by auditors |
   | **NIST SP 800-53 Rev. 5** | US federal and regulated industries |
   | **PCI DSS v4.0** | Payment card environments |
   | **ISO/IEC 27001:2022** | International information security management |
   | **SOC 2 Type 2** | Service Organisation Controls — SaaS and cloud providers |

4. Click the toggle next to **CIS Azure Foundations Benchmark v2.0.0** to enable it.
5. Click **Save**.
6. Navigate back to **Cloud Security → Regulatory compliance**.
7. The CIS standard now appears as a card. Initial assessment may take up to **30 minutes** to populate — refresh the blade after waiting.

---

## Step 3 — Navigate Controls and Assessments

### 3.1 Control pass/fail and assessment detail

1. Click on the **CIS Azure Foundations Benchmark** card.
2. The view expands to show all CIS control domains (e.g., "Identity and Access Management", "Logging and Monitoring", "Storage Accounts").
3. Each domain shows:
   - **Passed / Failed / Not applicable** assessment count
   - **Compliance percentage** for that domain

4. Click on a failing domain — for example, **Logging and Monitoring**.
5. The domain expands to show the individual CIS controls within it (e.g., "2.1.1 — Ensure that Microsoft Defender for App Services is set to 'On'").
6. For each control, click the row to see:
   - The specific Azure **assessment** (recommendation) that maps to this control
   - Which **resources** are passing or failing that assessment
   - A direct link to remediation steps

### 3.2 Understand assessment-to-control mapping

One assessment can map to multiple compliance controls across different standards. For example, "Storage accounts should restrict network access" appears in both CIS and NIST. When you remediate that one assessment, your compliance percentage improves in both standards simultaneously.

To trace a control back to its underlying policy:

1. Click on a failing control.
2. In the assessment detail, click **View policy definition**.
3. This opens the Azure Policy definition that drives the assessment — useful if you need to understand exactly what property the policy is evaluating, or if you want to audit the policy's effect (Audit vs. Deny vs. DeployIfNotExists).

---

## Step 4 — Export a Compliance Report

### 4.1 PDF export for auditors

1. On the **Regulatory compliance** blade, click **Download report** (in the toolbar).
2. In the Download report panel:
   - Select the **standard** you want to export (e.g., CIS Azure Foundations Benchmark)
   - Select **PDF**
   - Set the **Report date** to today
3. Click **Download**.
4. The PDF includes:
   - Executive summary with overall compliance percentage
   - Control-by-control pass/fail table
   - Assessment details for failed controls
   - Timestamp and subscription name

   > **Auditor tip:** The PDF is timestamped and signed by Microsoft — it is sufficient as point-in-time evidence for many audit frameworks. For continuous compliance evidence, schedule a monthly report and store the PDFs in a secured SharePoint or Azure Blob container.

### 4.2 CSV export for engineering teams

1. In the **Download report** panel, select **CSV** instead of PDF.
2. The CSV includes the same data in a spreadsheet-friendly format.
3. Use the CSV to:
   - Filter by "Status: Failed" and assign rows to engineering owners
   - Track remediation progress over time by comparing exports month-over-month
   - Feed into a Power BI dashboard for executive compliance reporting

---

## Step 5 — Create a Custom Compliance Initiative (Optional)

If your organisation has internal controls that do not map to any published standard, you can create a custom compliance initiative.

1. Navigate to **Azure Policy → Definitions**.
2. Click **+ Initiative definition**.
3. Select **Scope** (subscription or Management Group).
4. Name the initiative (e.g., `initiative-internal-controls-v1`).
5. Under **Policies**, add the Azure Policy definitions that map to your internal controls.
6. Click **Save**.
7. Assign the initiative to your subscription:
   - **Azure Policy → Assignments → + Assign initiative**
   - Select the initiative you created
   - Set the scope to your target subscription
8. After assignment, the initiative appears in the **Security policies** blade under **Custom initiatives** and will surface in the **Regulatory compliance** dashboard within 30 minutes.

---

## Cleanup

No billable resources are created by this lab. The compliance standards added in Step 2 are Azure Policy initiative assignments — they are **audit-only** by default and do not modify resources.

To remove a standard if no longer needed:

1. Navigate to **Environment settings → Security policies** for your subscription.
2. Toggle off the standard you added.
3. Click **Save**.

---

**Continue to:** [Lab 4 — Attack Path Analysis →](4-attack-path-analysis.md)

← [Back to CSPM Track README](README.md)
