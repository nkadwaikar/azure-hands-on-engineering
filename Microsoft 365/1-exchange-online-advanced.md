# Exchange Online Advanced Lab

## Enterprise Mail Flow · Transport Rules · Threat Protection · Journaling · Governance

> **Why this matters:** An Exchange Online environment without transport rules, journaling, and threat protection is an open relay waiting for a data breach — this lab hardens enterprise mail flow end-to-end so SPF/DKIM/DMARC authentication, Defender for Office 365 policies, and compliance archiving are all provably in place before a single sensitive email leaves the tenant.

Last validated on: July 2026

---

## Summary

This lab builds an enterprise-grade Exchange Online foundation. You will validate DNS authentication records, design mail flow architecture, deploy transport rules, enable journaling and archiving, activate Defender for Office 365 threat protection, and govern shared mailboxes — all through the Microsoft admin portals.

**Estimated time:** 3–4 hours
**License required:** Microsoft 365 E3 (Defender Plan 1) or E5 (Defender Plan 2)
**Portals used:**

- [Exchange Admin Center](https://admin.exchange.microsoft.com)
- [Microsoft 365 Admin Center](https://admin.microsoft.com)
- [Microsoft Defender portal](https://security.microsoft.com)

---

## Table of Contents

1. [Mail Flow Architecture](#1-mail-flow-architecture)
2. [Transport Rules](#2-transport-rules)
3. [Journaling & Archiving](#3-journaling--archiving)
4. [Threat Protection](#4-threat-protection)
5. [Shared Mailbox Governance](#5-shared-mailbox-governance)
6. [Validation](#6-validation)
7. [Next Steps](#7-next-steps)

---

## 1. Mail Flow Architecture

### 1.1 Validate DNS Records

DNS authentication records (SPF, DKIM, DMARC) are the foundation of secure mail flow. Without them your domain is vulnerable to spoofing.

**Check your MX and SPF records:**

1. Go to [MXToolbox][def] → enter your domain → run **MX Lookup** and **SPF Lookup**
2. Your SPF record should contain `include:spf.protection.outlook.com`
3. A recommended SPF record: `v=spf1 include:spf.protection.outlook.com -all`
   > Use `-all` (hard fail) once all legitimate senders are listed in the record

**Enable DKIM signing:**

1. Go to **Exchange Admin Center** → **Mail flow** → **DKIM**
2. Select your domain → click **Enable**
3. Copy the two **CNAME records** shown (Selector1 and Selector2)
4. Publish both CNAME records in your DNS provider (allow up to 48 hours to propagate)
5. Return to the DKIM page and verify the status shows **Enabled**

**Publish a DMARC record:**

Add a TXT record at `_dmarc.yourdomain.com` in your DNS provider:

```txt
v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@yourdomain.com; pct=100
```

Recommended progression:

- **Week 1–2:** `p=none` (monitor only — no action taken)
- **Week 3–4:** `p=quarantine` (suspicious mail goes to junk)
- **Week 5+:** `p=reject` (full enforcement — spoofed mail is blocked)

### 1.2 Review Mail Flow

1. Go to **Exchange Admin Center** → **Mail flow** → **Message trace**
2. Run a trace to confirm inbound and outbound mail is routing through Exchange Online Protection
3. Document the flow:

```text
Inbound:  Internet → MX record → Exchange Online Protection (EOP) → Recipient mailbox
Outbound: Sender mailbox → Exchange Online Protection → DKIM signed → Internet
```

---

## 2. Transport Rules

Transport rules enforce organizational policy on every message — regardless of which client or device the user is on.

Navigate to: **Exchange Admin Center** → **Mail flow** → **Rules** → **+ Add a rule**

### Rule 1: Block External Auto-Forwarding

Prevents data exfiltration via mailbox auto-forwarding to external addresses.

| Field | Value |
| --- | --- |
| Name | Block External Auto-Forwarding |
| Apply this rule if | The message type is **Auto-forward** |
| And | The recipient is **located outside the organization** |
| Do the following | **Reject** the message with explanation: *"Auto-forwarding to external recipients is not permitted by policy."* |
| Rule mode | Enforce |
| Priority | 0 (highest) |

### Rule 2: External Sender Warning

Adds a visible warning banner to all inbound mail from outside your organization.

| Field | Value |
| --- | --- |
| Name | External Sender Warning |
| Apply this rule if | The sender is **located outside the organization** |
| Do the following | **Prepend a disclaimer** |
| Disclaimer text | `⚠ EXTERNAL EMAIL: This message originated outside your organization. Do not click links or open attachments unless you recognize the sender.` |
| Fallback action | Wrap |
| Priority | 1 |

### Rule 3: Redirect Phishing Reports

Routes user-reported phishing messages to your security operations mailbox.

| Field | Value |
| --- | --- |
| Name | Redirect Phishing Reports to SecOps |
| Apply this rule if | The recipient is `phish-reports@yourdomain.com` |
| Do the following | **Add recipients** → Bcc: `secops@yourdomain.com` |
| Priority | 2 |

### Rule 4: Encrypt Highly Confidential Messages

Automatically encrypts messages when the Highly Confidential sensitivity label is applied.

| Field | Value |
| --- | --- |
| Name | Encrypt Highly Confidential Messages |
| Apply this rule if | A message sensitivity label matches **Highly Confidential** |
| Do the following | **Apply Office 365 Message Encryption** → select the Encrypt template |
| Priority | 3 |

> Requires Microsoft Purview Message Encryption (included with E3/E5).

### Rule 5: Block High-Risk File Types

Blocks delivery of executable and script attachments commonly used in malware attacks.

| Field | Value |
| --- | --- |
| Name | Block High-Risk Attachment Types |
| Apply this rule if | Any attachment's file extension matches: `exe, bat, cmd, vbs, js, ps1, msi, scr, hta, pif` |
| Do the following | **Reject** with explanation: *"This file type is blocked by organizational security policy."* |
| Priority | 4 |

---

## 3. Journaling & Archiving

### 3.1 Configure Journaling

Journaling captures a copy of all messages for regulatory and legal purposes.

> **Important:** In production, the journal mailbox must be external to your Exchange Online organization (a dedicated archiving service or on-premises mailbox). For lab purposes, a shared mailbox is acceptable.

**Create a journaling mailbox:**

1. Go to **Microsoft 365 Admin Center** → **Users** → **Shared mailboxes** → **+ Add a shared mailbox**
2. Name: `Journal Archive` | Email: `journalarchive@yourdomain.com`
3. Click **Save changes**

**Create a journal rule:**

1. Go to **Exchange Admin Center** → **Compliance management** → **Journal rules** → **+ Add a rule**

| Field | Value |
| ------- | ------- |
| Send journal reports to | `journalarchive@yourdomain.com` |
| Journal rule name | Regulatory Journaling - All Messages |
| If the message is sent to or received from | Anyone |
| Journal the following messages | All messages |

1. Click **Save**

### 3.2 Enable In-Place Archive

Provides each user a secondary "archive" mailbox in Outlook for long-term storage.

1. Go to **Exchange Admin Center** → **Recipients** → **Mailboxes**
2. Select all user mailboxes (use the checkbox at the top to select all)
3. Click **...** (More options) → **Enable archive**
4. Confirm in the dialog

### 3.3 Configure Retention Policies

1. Go to **Exchange Admin Center** → **Recipients** → **Retention policies** → **+ Add**

| Field       | Value                       |
| ----------- | --------------------------- |
| Policy name | Enterprise Retention Policy |

1. Add the following retention tags (create each via **Retention tags** → **+ Add**):

| Tag name | Type | Age limit | Action |
| --- | --- | --- | --- |
| Inbox - 2 Year Delete | Inbox | 730 days | Delete and allow recovery |
| Sent Items - 1 Year Delete | Sent Items | 365 days | Delete and allow recovery |
| Default - 7 Year Archive | Default | 2555 days | Move to archive |

1. Apply the policy to all mailboxes:
   - Select all mailboxes → **...** → **Apply retention policy** → select **Enterprise Retention Policy**

### 3.4 Enable Litigation Hold

Places a legal hold on mailbox content so items cannot be permanently deleted.

1. Go to **Exchange Admin Center** → **Recipients** → **Mailboxes**
2. Open each executive/finance/legal/security mailbox
3. Go to the **Others** tab → **Litigation hold** → **Edit**
4. Toggle **Litigation hold** to **On**
5. Set hold duration: `2555` days (7 years)
6. Add a note: `Legal Department hold — do not remove without written approval`
7. Click **Save**

> **Tip:** Repeat for all mailboxes in the Executives, Finance, Legal, and Security departments.

---

## 4. Threat Protection

All threat protection settings are configured in the **Microsoft Defender portal** at [security.microsoft.com](https://security.microsoft.com).

Navigate to: **Email & collaboration** → **Policies & rules** → **Threat policies**

### 4.1 Safe Links

Safe Links rewrites URLs in email and Office documents, checking them against Microsoft's threat intelligence at click time.

1. Click **Safe Links** → **+ Create**
2. Configure:

| Setting | Value |
| --------- | -------- |
| Name | Enterprise Safe Links Policy |
| On — rewrite URLs and check against known malicious links | On |
| Apply real-time URL scanning | On |
| Wait for URL scanning before delivering the message | On |
| Apply Safe Links to email sent within the org | On |
| Apply Safe Links to Microsoft Teams | On |
| Apply Safe Links to Office 365 apps | On |
| Track user clicks | On (do NOT disable — needed for threat investigation) |
| Let users click through to the original URL | Off |

1. Under **Users and domains** → add `yourdomain.com`
2. Click **Submit**

### 4.2 Safe Attachments

Safe Attachments opens attachments in a sandbox before delivery.

1. Click **Safe Attachments** → **+ Create**
| Setting | Value |
| --- | --- |
| Name | Enterprise Safe Attachments Policy |
| Safe Attachments unknown malware response | **Dynamic Delivery** (delivers body immediately; reattaches after scan) |
| Redirect messages with detected attachments | Off (for lab; enable with SOC mailbox in production) |
| Enable Safe Attachments for SharePoint, OneDrive, Teams | On |
2. Under **Users and domains** → add `yourdomain.com`
3. Click **Submit**

> **Dynamic Delivery** eliminates delivery delays while maintaining security — it's the recommended setting for most organizations.

### 4.3 Anti-Phishing

1. Click **Anti-phishing** → **+ Create**
| Setting | Value |
| --- | --- |
| Name | Enterprise Anti-Phishing Policy |
| Phishing email threshold | **3 - More aggressive** |
| Enable mailbox intelligence | On |
| Enable intelligence for impersonation protection | On |
| Enable spoof intelligence | On |
| Show first contact safety tip | On |
| Show user impersonation safety tip | On |
| Show domain impersonation safety tip | On |
| Show unusual characters safety tip | On |

2. Under **Protected users** → **+ Add** → add executive email addresses (CEO, CFO, CTO)
3. Under **Trusted senders and domains** → add any known partner domains
4. Set **If message is detected as impersonation** → **Quarantine the message**
5. Under **Users and domains** → add `yourdomain.com`
6. Click **Submit**

---

## 5. Shared Mailbox Governance

### 5.1 Create Shared Mailboxes

1. Go to **Microsoft 365 Admin Center** → **Users** → **Shared mailboxes** → **+ Add a shared mailbox**
2. Create each mailbox:

| Display name | Email address |
| --- | --- |
| Support | <support@yourdomain.com> |
| Finance | <finance@yourdomain.com> |
| Projects | <projects@yourdomain.com> |

### 5.2 Assign Access via Groups

Never assign mailbox permissions directly to individual users — use security groups for auditable, manageable access.

**Create access groups:**

1. Go to **Microsoft 365 Admin Center** → **Teams & groups** → **Active teams & groups** → **Security** → **+ Add**
2. Create:
   - `Shared-Support-Access`
   - `Shared-Finance-Access`
3. Add appropriate users to each group

**Assign mailbox permissions:**

1. Go to **Microsoft 365 Admin Center** → **Users** → **Shared mailboxes**
2. Open the **Support** mailbox → **Mailbox permissions**
3. Under **Read and manage (Full Access)** → **Edit** → add `Shared-Support-Access` group
4. Under **Send as** → **Edit** → add `Shared-Support-Access` group
5. Repeat for Finance and Projects mailboxes

### 5.3 Shared Mailbox Lifecycle

| Stage | Action | Owner |
| --- | --- | --- |
| **Creation** | Submit IT service desk request with business purpose and owner | Business owner |
| **Operation** | Quarterly membership review of access groups | Business owner |
| **Archival** | Remove all members from access group; apply litigation hold if required | IT |
| **Deletion** | Export PST if required; delete shared mailbox in Admin Center | IT / Legal |

---

## 6. Validation

| Test | How to Test | Expected Result |
| --- | --- | --- |
| SPF/DKIM/DMARC | [MXToolbox][def] → SuperTool | All three records valid; DKIM enabled |
| Block auto-forwarding | Set up a forward on a test mailbox; send from external | NDR returned to sender |
| External disclaimer | Send from Gmail to your domain | Yellow warning banner visible in message |
| Block file type | Send email with `.exe` attachment | NDR with policy text |
| Safe Links | Click a link in a delivered test email | URL rewrites to `safelinks.protection.outlook.com` |
| Safe Attachments | Send email with a benign PDF | Delivered with dynamic delivery placeholder during scan |
| Journaling | Send test messages; check journal mailbox | Copies appear in journal mailbox |
| Litigation hold | Open a held mailbox; delete an item; check Recoverable Items | Item retained and visible in eDiscovery search |
| Shared mailbox access | Sign in as a group member; open shared mailbox | Mailbox opens; Send As works |

---

## 7. Next Steps

- [Lab 2: SharePoint Information Architecture](2-sharepoint-information-architecture.md)
- [Lab 3: Lifecycle Governance](3-teams-lifecycle-governance.md)
- [Lab 4: Compliance Automation](4-compliance-automation.md)
- [Lab 5: Zero Trust Advanced](5-zero-trust-advanced.md)

[def]: https://mxtoolbox.com
