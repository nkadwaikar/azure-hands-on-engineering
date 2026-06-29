# Compliance Automation Lab (Purview)

## DLP · Auto-Labeling · Insider Risk · Compliance Manager

---

## Summary

This lab automates compliance across Microsoft 365 using Microsoft Purview — entirely through the portal. You will create Data Loss Prevention policies for financial, PII, and health data; configure auto-labeling to classify content without user intervention; enable Insider Risk Management policies to detect data theft and leaks; and set up Compliance Manager assessments for NIST, ISO, and GDPR.

**Estimated time:** 4–5 hours  
**License required:** Microsoft 365 E5 or E5 Compliance add-on  
**Portal used:** [Microsoft Purview portal](https://compliance.microsoft.com)

---

## Table of Contents

1. [DLP Automation](#1-dlp-automation)
2. [Auto-Labeling](#2-auto-labeling)
3. [Insider Risk Management](#3-insider-risk-management)
4. [Compliance Manager](#4-compliance-manager)
5. [Validation](#5-validation)
6. [Next Steps](#6-next-steps)

---

## 1. DLP Automation

Data Loss Prevention policies detect sensitive content and take automated action — blocking transmission, notifying users, and generating audit alerts.

All DLP policies are created in:
**Purview portal** → **Data loss prevention** → **Policies** → **+ Create policy**

### 1.1 DLP Policy: Financial Data

1. Click **+ Create policy**
2. **Start with a template or custom policy:** choose **Financial** → **U.S. Financial Data** → **Next**
3. **Name:** `Protect Financial Data` → **Next**
4. **Locations:** toggle on All (Exchange, SharePoint, OneDrive, Teams, Devices) → **Next**
5. **Policy settings:** choose **Create or customize advanced DLP rules** → **Next**
6. Click **+ Create rule**

#### Rule 1: Block external sharing

| Field | Value |
| ------- | ------- |
| Rule name | Financial Data - External Block |
| Conditions | Content contains sensitive info types: **Credit Card Number** (min count: 1), **U.S. Bank Account Number** (min count: 1) |
| Add condition | Content is shared: **With people outside my organization** |
| Actions | **Restrict access or encrypt the content** → Block everyone |
| User notifications | ✅ Notify the user who sent, shared, or last modified the content |
| Policy tip text | *"This document contains financial data and cannot be shared externally. Contact the Compliance team with questions."* |
| Incident reports | Severity: **High** → Send alert to compliance admins |

1. Save rule → **Next** → **Turn on the policy now** → **Submit**

### 1.2 DLP Policy: Personally Identifiable Information (PII)

1. **+ Create policy** → **Privacy** → **U.S. Personally Identifiable Information (PII) Data** → **Next**
2. Name: `Protect PII` → **Next**
3. Locations: All → **Next**
4. Choose **Create or customize advanced DLP rules** → create two rules:

#### Rule 1: PII - Internal Notify (low count)

| Field | Value |
| ------- | ------- |
| Rule name | PII - Internal Policy Tip |
| Conditions | Content contains: **U.S. Social Security Number (SSN)** (min: 1), **U.S. Driver's License Number** (min: 1) |
| Shared with | Inside my organization |
| Actions | None (warning only) |
| User notifications | ✅ On |
| Policy tip | *"This content contains personal data. Handle in accordance with the Data Privacy Policy."* |
| Priority | 1 (lower priority) |

#### Rule 2: PII - External Block

| Field | Value |
| ------- | ------- |
| Rule name | PII - External Block |
| Conditions | Content contains: **U.S. Social Security Number (SSN)** (min: 1) |
| Shared with | Outside my organization |
| Actions | Block everyone |
| Incident reports | Severity: High |
| Priority | 0 (higher priority) |

1. Submit → **Turn the policy on now**

### 1.3 DLP Policy: Health Data (HIPAA)

1. **+ Create policy** → **Medical and health** → **U.S. Health Insurance Act (HIPAA)** → **Next**
2. Name: `Protect Health Data (HIPAA)` → **Next**
3. Locations: All → **Next**
4. **Create or customize advanced DLP rules** → create:

### Rule: HIPAA - Block and Alert

| Field | Value |
| ------- | ------- |
| Rule name | HIPAA - External Block |
| Conditions | Content contains: **U.S. Health Insurance Claim Number**, **Drug Enforcement Agency (DEA) Number** |
| Shared with | Outside my organization |
| Actions | Block everyone |
| Notifications | Notify user + Incident report (High severity) |

1. Submit → Turn on

### 1.4 DLP Automated Actions Reference

| Scenario | Recommended Action |
| ---------- | -------------------- |
| PII shared externally (1–5 instances) | Block + notify user + alert |
| Financial data emailed externally | Block + notify + high-severity alert |
| Health data in SharePoint (any count) | Block external access + alert |
| Low-count PII (1–2) internally | Policy tip only (no block) |
| High-count PII (10+) | Block all access + generate alert |

---

## 2. Auto-Labeling

Auto-labeling applies sensitivity labels to content automatically — without requiring users to label documents manually.

### 2.1 Create Sensitivity Labels

1. **Purview portal** → **Information protection** → **Labels** → **+ Create a label**

Create four labels in sequence. For each, click **+ Create a label** and work through the wizard:

#### Label 1: Public

| Field | Value |
| ------- | ------- |
| Name | Public |
| Display name | Public |
| Description for users | Content that can be shared freely with anyone inside or outside the organization |
| Scope | Files & emails + Groups & sites |
| Encryption | None |
| Content marking | None |

#### Label 2: Internal

| Field | Value |
| ------- | ------- |
| Name | Internal |
| Description | For internal use only. Do not share externally without approval. |
| Encryption | None |
| Footer | Add footer text: **INTERNAL — Not for external distribution** |

#### Label 3: Confidential

| Field | Value |
| ------- | ------- |
| Name | Confidential |
| Description | Sensitive business content. Share only with authorized personnel. |
| Encryption | ✅ Apply encryption |
| Assign permissions now | Authenticated users — Co-Author |
| Watermark | Add watermark: **CONFIDENTIAL** |
| Footer | **CONFIDENTIAL** |

#### Label 4: Highly Confidential

| Field | Value |
| ------- | ------- |
| Name | Highly Confidential |
| Description | Strictly controlled. Encryption required. Limited distribution. |
| Encryption | ✅ Apply encryption |
| Assign permissions now | Specific people/groups only |
| Content marking | Watermark: **HIGHLY CONFIDENTIAL** + footer |

1. After creating all labels, click **Publish labels** → add all four → scope to all users → submit

> Labels appear in Office apps and SharePoint for users within 24–48 hours of publishing.

### 2.2 Configure Auto-Labeling for SharePoint and OneDrive

1. **Purview portal** → **Information protection** → **Auto-labeling** → **+ Create auto-labeling policy**

### Policy 1: Auto-Label PII as Confidential

| Field | Value |
| ------- | ------- |
| Policy name | Auto-Label PII as Confidential |
| Label to apply | Confidential |
| Locations | SharePoint sites: All sites; OneDrive accounts: All accounts; Exchange: All |

Rules:

| Setting | Value |
| --------- | ------- |
| Rule name | PII Detection |
| Condition | Content contains sensitive info type: **U.S. Social Security Number (SSN)** (min: 1); **Credit Card Number** (min: 1) |

1. Choose **Run policy in simulation mode** → **Save**
2. After reviewing simulation results (usually 24–48 hours), return to the policy → **Turn on policy**

### Policy 2: Auto-Label Health Data as Highly Confidential

Same process:

- Label: **Highly Confidential**
- Sensitive info type: **U.S. Health Insurance Claim Number**
- Start in simulation mode → turn on after review

> Always run in simulation mode first. Review matched items in the portal before going live.

---

## 3. Insider Risk Management

Insider Risk Management correlates Microsoft 365 activity signals to detect patterns suggesting data theft, leaks, or privilege abuse.

### 3.1 Enable Audit Logging (Prerequisite)

1. **Purview portal** → **Audit** → **Start recording user and admin activity** (if not already enabled)
2. Verify: the banner should say **Recording user and admin activity**

### 3.2 Configure Insider Risk Settings

1. **Purview portal** → **Insider risk management** → **Settings** (gear icon)
2. Configure:

| Setting | Value |
| --------- | ------- |
| Privacy | Show anonymized versions of usernames (recommended for initial rollout) |
| Policy indicators | Enable all: Office indicators, Device indicators, Physical access indicators |
| Policy timeframes | Past activity detection: **90 days**; Future activity detection: **90 days** |
| Intelligent detections | Enable anomaly detection |

### 3.3 Create Insider Risk Policies

1. **Insider risk management** → **Policies** → **+ Create policy**

#### Policy 1: Data Theft by Departing Users

| Field | Value |
| ------- | ------- |
| Template | **Data theft by departing users** |
| Name | Data Theft - Departing Users |
| Users | All users |
| Triggering event | Resignation or termination date from HR connector (or Manual triggering) |
| Priority content | Sensitivity labels: Confidential, Highly Confidential |
| Indicators | ✅ File downloads, copy to USB, email to external, cloud upload |
| Alert threshold | Medium |

1. Click **Submit**

### Policy 2: General Data Leaks

| Field | Value |
| ------- | ------- |
| Template | **General data leaks** |
| Name | Data Leaks - All Users |
| Triggering event | DLP policy match |
| Priority content | All sensitivity labels above Internal |
| Indicators | ✅ Sharing externally, bulk download, printing sensitive content |

### Policy 3: Privileged User Risk

| Field | Value |
| ------- | ------- |
| Template | **Security policy violations by users** |
| Name | Privileged User Risk |
| Users | Select specific users: all admin role members |
| Indicators | ✅ Disabling audit logs, modifying DLP, bulk deletions |

### 3.4 Trigger a Test Event

1. Using a test user account, create a Word document containing dummy PII text (e.g., `SSN: 123-45-6789`)
2. Upload to SharePoint and attempt to share externally
3. The DLP policy will fire → this should generate an Insider Risk alert if DLP is configured as a triggering event
4. Check **Insider risk management** → **Alerts** — alert should appear within 24 hours

---

## 4. Compliance Manager

Compliance Manager provides a dashboard of your compliance posture across regulatory frameworks, assigns control ownership, and tracks your improvement score.

### 4.1 Create Assessments

1. **Purview portal** → **Compliance Manager** → **Assessments** → **+ Add assessment**

**NIST SP 800-53 Assessment:**

| Field | Value |
| ------- | ------- |
| Select regulation | **NIST SP 800-53 Rev 5** |
| Assessment name | NIST SP 800-53 — Microsoft 365 |
| Assign group | Create new group: **Enterprise Compliance** |

Click **Create assessment**

**ISO 27001 Assessment:**

| Field | Value |
| ------- | ------- |
| Select regulation | **ISO/IEC 27001:2022** |
| Assessment name | ISO 27001 — Microsoft 365 |
| Group | Enterprise Compliance |

**GDPR Assessment:**

| Field | Value |
| ------- | ------- |
| Select regulation | **GDPR** |
| Assessment name | GDPR — Microsoft 365 |
| Group | Enterprise Compliance |

### 4.2 Assign Controls and Improve Your Score

1. Open any assessment → click **Your improvement actions** tab
2. Filter by **Status: Not started** → sort by **Points impact** (highest first)
3. Click an action → assign to a team member:
   - **Assigned to:** select the responsible person
   - **Status:** In progress
   - Add implementation notes and evidence links

**High-impact actions to prioritize first:**

| Action | Frameworks | Typical points |
| -------- | ----------- | --------------- |
| Require MFA for all users (via Conditional Access) | All | High |
| Deploy sensitivity labels + auto-labeling | All | High |
| Enable unified audit log | NIST, ISO | Medium |
| Configure DLP for PII and financial data | GDPR | High |
| Set up quarterly access reviews | NIST, ISO | Medium |
| Enable encryption at rest confirmation | ISO, GDPR | Medium |

### 4.3 Track Compliance Score

Your compliance score is shown on the **Compliance Manager** home dashboard:

```text
Score = (Points achieved / Total possible points) × 100
```

- Set a target score improvement per sprint (e.g., +10 points per 2-week sprint)
- Use the **Overview** tab to track score changes over time
- Export a score snapshot via **Export** → **Export to Excel** for stakeholder reporting

---

## 5. Validation

| Test | How to Test | Expected Result |
| --- | --- | --- |
| DLP — Financial | Send email with credit card number to external address | Message blocked; policy tip shown |
| DLP — PII external | Share SharePoint doc with SSN content externally | Sharing blocked; alert in Purview |
| DLP — Audit | **Purview** → **Data loss prevention** → **Alerts** | Alerts visible with details |
| Auto-label simulation | **Information protection** → **Auto-labeling** → view policy → **Simulation** tab | Documents matched; labels shown |
| Auto-label live | Upload doc with SSN to SharePoint | Label **Confidential** applied within 24 hours |
| Insider Risk | Check **Insider risk management** → **Alerts** after DLP trigger | Alert visible with risk severity |
| Compliance score | **Compliance Manager** home page | Score visible; assessments populated with controls |
| Control assignment | Open an improvement action and assign to a user | Action shows assigned user and updated status |

---

## 6. Next Steps

- [Lab 5: Zero Trust Advanced](5-zero-trust-advanced.md)
