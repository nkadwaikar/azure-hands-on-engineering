# Secure Break-Glass Accounts — Emergency Access for Microsoft Entra ID

> **Why this matters:** A misconfigured Conditional Access policy or an identity provider outage can lock every administrator out of the tenant simultaneously. Without pre-configured break-glass accounts, recovery requires a multi-day Microsoft Support engagement. With them, recovery takes minutes.

Last validated on: 2026-07-14
Portal experience note: Steps validated against Microsoft Entra admin center as of July 2026. The Conditional Access and Authentication Methods blades are accessed via **Entra admin center → Protection**.

> **Note:** Break-glass accounts carry permanent Global Administrator access. Their configuration must be treated as a critical security control — not a convenience feature. Every step in this lab should be reviewed with your security team before production implementation.

---

## Module / Track Structure

```text
Secure Break-Glass Accounts/
├── README.md                          ← Track entry point
└── 1-Secure-Break-Glass-Accounts.md  ← Lab Guide (you are here)
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Create Break-Glass User Accounts](#step-1--create-break-glass-user-accounts)
- [Step 2 — Assign Global Administrator Role](#step-2--assign-global-administrator-role)
- [Step 3 — Register FIDO2 Security Keys](#step-3--register-fido2-security-keys)
- [Step 4 — Exclude From All Conditional Access Policies](#step-4--exclude-from-all-conditional-access-policies)
- [Step 5 — Configure Sign-In Alerting](#step-5--configure-sign-in-alerting)
- [Step 6 — Validate Access End-to-End](#step-6--validate-access-end-to-end)
- [Step 7 — Seal and Document Credentials](#step-7--seal-and-document-credentials)
- [Operational Procedures](#operational-procedures)
- [Checklist](#checklist)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| **Role** | Global Administrator on the Entra tenant |
| **Hardware** | Two physical FIDO2 security keys — one per account (YubiKey 5 NFC or equivalent; do not use virtual/software authenticators) |
| **Licensing** | Microsoft Entra ID P1 or P2 (required for Conditional Access exclusions and sign-in logs) |
| **Portal** | [Microsoft Entra admin center](https://entra.microsoft.com) |
| **Monitoring** | Log Analytics Workspace — required for sign-in alert routing in Step 5 |
| **Storage** | Two tamper-evident sealed envelopes and a locked, access-controlled physical location |

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Created two **cloud-only break-glass accounts** using the `.onmicrosoft.com` UPN domain — independent of any federation or directory sync
- Assigned **Global Administrator** to both accounts as a permanent role assignment
- Registered a **dedicated FIDO2 security key** on each account as the sole authentication method
- Excluded both accounts from **every Conditional Access policy** in the tenant
- Created an **Azure Monitor alert** that fires immediately on any sign-in attempt from either account
- **Validated sign-in** with a FIDO2 key and confirmed access to the Entra admin center
- **Sealed** the FIDO2 keys and recovery information in a physically secured, auditable location

---

## 3. Scenario

**Every admin account is locked out. Now what?**

A newly deployed Conditional Access policy inadvertently blocked all accounts — including the accounts used to manage Conditional Access. The federation service is unhealthy. Standard MFA methods are unavailable. Without break-glass accounts pre-configured before this event, the only path forward is a days-long Microsoft Support engagement. Break-glass accounts, designed specifically for this scenario, let your team recover the tenant immediately — but only if they are configured, tested, and physically secured before the outage.

---

## Step 1 — Create Break-Glass User Accounts

Break-glass accounts must be **cloud-only** — not synced from Active Directory and not federated. This ensures they remain accessible even when on-premises infrastructure or federation services are unavailable.

### 1.1 Create the First Account

1. In the [Entra admin center](https://entra.microsoft.com), go to **Identity → Users → All users → New user → Create new user**.
2. Fill in the following:

   | Field | Value |
   | --- | --- |
   | **User principal name** | `bg-admin-01@<tenant>.onmicrosoft.com` — use the `.onmicrosoft.com` domain, not a custom domain tied to federation |
   | **Display name** | `Break-Glass Admin 01` |
   | **Password** | Auto-generate a strong password — record it on paper, not digitally |
   | **Account enabled** | Yes |

3. Under **Properties**, leave all optional fields blank — do not associate with a department, manager, or cost centre that would tie this account to a business unit.
4. Select **Create**.

### 1.2 Create the Second Account

Repeat the process for a second account: `bg-admin-02@<tenant>.onmicrosoft.com`.

> **Why two accounts?** If the FIDO2 key for one account is lost, damaged, or inaccessible (stored at a different physical location), the second account provides a backup path. Both accounts should be stored in separate physical locations.

### 1.3 Set Passwords to Never Expire

1. For each account: **Users → [account] → Properties → Edit**.
2. Under **Password settings**, set **Password never expires** to **Yes**.
3. Save.

> Break-glass accounts must not expire or require password rotation on a normal cycle — any automated expiry policy could silently break the emergency access path.

---

## Step 2 — Assign Global Administrator Role

1. Open **Identity → Roles & admins → Global administrator**.
2. Select **Add assignments**.
3. Search for `Break-Glass Admin 01`, select it, and confirm the assignment.
4. Repeat for `Break-Glass Admin 02`.
5. Confirm both accounts appear in the **Global administrator** members list.

> **Do not use PIM eligible assignments.** Break-glass accounts must have **permanent active** Global Administrator — a PIM-eligible assignment requires the account to activate the role, which may itself require MFA or approval. In a lockout scenario, that activation path may also be unavailable.

---

## Step 3 — Register FIDO2 Security Keys

Each break-glass account must use a **dedicated physical FIDO2 security key** as its only authentication method. This eliminates all dependencies on SMS, app-based TOTP, the Microsoft Authenticator app, or any other method that requires an operational device or service.

### 3.1 Enable FIDO2 in Authentication Methods Policy

1. Go to **Protection → Authentication methods → Policies**.
2. Select **FIDO2 security key**.
3. Set **Enable** to **Yes**.
4. Under **Target**, include `All users` or specifically include the break-glass accounts.
5. Save.

### 3.2 Register the Key for Each Account

FIDO2 key registration must be performed while signed in as the break-glass account itself.

1. Open an **InPrivate / Incognito** browser window.
2. Sign in to [https://mysignins.microsoft.com/security-info](https://mysignins.microsoft.com/security-info) as `bg-admin-01@<tenant>.onmicrosoft.com`.
3. Select **Add sign-in method → Security key**.
4. Follow the browser prompts to insert and touch the FIDO2 key.
5. Set a meaningful name, e.g., `BG-01-YubiKey-Serial-XXXXXXXX`.
6. Sign out.
7. Repeat for `bg-admin-02` with its dedicated key.

### 3.3 Verify Registration

1. Sign back in as each break-glass account using the FIDO2 key (no password).
2. Confirm successful authentication and access to the Entra admin center.
3. Sign out immediately after confirming.

> **Label the physical keys.** Each FIDO2 key should be labelled with the account name and serial number using a permanent marker or engraved label. Do not rely on memory or digital records to identify which key belongs to which account.

---

## Step 4 — Exclude From All Conditional Access Policies

Break-glass accounts must be explicitly excluded from **every** Conditional Access policy in the tenant. A policy that blocks sign-in under emergency conditions defeats the entire purpose.

### 4.1 Create a Break-Glass Exclusion Group

1. Go to **Identity → Groups → New group**.
2. Set:

   | Field | Value |
   | --- | --- |
   | **Group type** | Security |
   | **Group name** | `grp-break-glass-exclusion` |
   | **Membership type** | Assigned |

3. Add both `Break-Glass Admin 01` and `Break-Glass Admin 02` as members.
4. Create.

Using a group rather than individual account exclusions makes it easier to audit and ensures no policy is missed if accounts are ever renamed.

### 4.2 Add the Exclusion to Every CA Policy

1. Go to **Protection → Conditional Access → Policies**.
2. For **each** policy listed:
   a. Open the policy.
   b. Under **Assignments → Users → Exclude**, add `grp-break-glass-exclusion`.
   c. Save the policy.
3. Confirm every policy — including report-only policies — has the exclusion applied.

> **Document every exclusion.** Record the name of each CA policy and the date the exclusion was added. This list becomes the audit trail that demonstrates the exclusions are intentional and reviewed.

---

## Step 5 — Configure Sign-In Alerting

Any sign-in from a break-glass account is a security event, regardless of whether it was a legitimate emergency or a test. An alert must fire immediately.

### 5.1 Route Entra Sign-In Logs to Log Analytics

1. Go to **Identity → Monitoring & health → Diagnostic settings**.
2. Select **Add diagnostic setting**.
3. Check **SignInLogs** and **AuditLogs**.
4. Select **Send to Log Analytics workspace** and choose your workspace.
5. Save.

> Allow 15–30 minutes for logs to begin flowing after first configuration.

### 5.2 Create the Alert Rule

1. In the Azure Portal, go to your **Log Analytics Workspace → Alerts → New alert rule**.
2. Under **Condition**, select **Custom log search** and use the following KQL:

   ```kql
   SigninLogs
   | where UserPrincipalName in (
       "bg-admin-01@<tenant>.onmicrosoft.com",
       "bg-admin-02@<tenant>.onmicrosoft.com"
   )
   | project TimeGenerated, UserPrincipalName, AppDisplayName, IPAddress,
             ResultType, ResultDescription, Location
   ```

3. Set **Threshold** to `> 0` results within a **5-minute** evaluation window.
4. Under **Actions**, create or attach an **Action Group** that pages your on-call team (email, SMS, or webhook to your incident management platform).
5. Set **Alert rule name**: `CRITICAL — Break-Glass Account Sign-In Detected`.
6. Set **Severity**: `0 — Critical`.
7. Enable the rule and save.

### 5.3 Test the Alert

Run the KQL query manually in the Log Analytics workspace after completing Step 6 (validation sign-in) to confirm the alert would have fired.

---

## Step 6 — Validate Access End-to-End

Before sealing the credentials, validate that each account can actually sign in and reach the Entra admin center. An unvalidated break-glass account provides false confidence.

1. Open an **InPrivate / Incognito** browser window on a clean device (or use a separate physical machine if available).
2. Navigate to [https://entra.microsoft.com](https://entra.microsoft.com).
3. Enter `bg-admin-01@<tenant>.onmicrosoft.com` as the sign-in name.
4. When prompted, insert the FIDO2 key and touch it.
5. Confirm you reach the Entra admin center dashboard.
6. Verify the account shows **Global Administrator** under **My Account → My roles**.
7. Sign out immediately.
8. Repeat for `bg-admin-02` with its key.

> **Do not perform any administrative actions during validation.** The purpose is to confirm the sign-in path works — not to exercise administrative functions. Every action taken while signed in as a break-glass account should be logged and reviewable.

### What Success Looks Like

| Check | Expected Result |
| --- | --- |
| Sign-in with FIDO2 key only | No password or MFA app prompt — key touch is sufficient |
| Entra admin center loads | Full portal access without any CA policy blocking |
| Role shown | Global Administrator (permanent, not PIM-eligible) |
| Sign-in alert fires | Log Analytics alert triggers within 5 minutes of sign-in |
| Sign-in appears in audit logs | Visible in **Identity → Monitoring → Sign-in logs** |

---

## Step 7 — Seal and Document Credentials

### 7.1 Prepare the Physical Sealed Packages

For each break-glass account, prepare a sealed package containing:

| Item | Notes |
| --- | --- |
| The FIDO2 security key | Labelled with account name and key serial number |
| The account UPN | Printed on paper — `bg-admin-01@<tenant>.onmicrosoft.com` |
| The initial password | Required only if FIDO2 registration ever needs to be re-done |
| Recovery codes (if applicable) | Any printed backup codes generated during FIDO2 registration |
| Date sealed and name of sealer | Chain-of-custody record |

### 7.2 Storage Requirements

- Place each sealed package in a **tamper-evident envelope** and write across the seal: break-glass only.
- Store `bg-admin-01` and `bg-admin-02` packages in **separate physical locations** — e.g., primary office safe and secondary/DR site.
- Location must be accessible to at least two named individuals from your security or operations leadership team.
- **Never store** credentials in a digital password manager, cloud vault, or any system that itself requires authentication to access.

### 7.3 Create the Break-Glass Procedure Document

Write a brief procedure covering:

- Which scenarios authorise break-glass use (federated IdP outage, MFA service unavailability, global CA lockout, account compromise requiring tenant-level recovery)
- Who is authorised to open the sealed envelope
- Steps to use the account (sign-in URL, which key belongs to which account)
- Mandatory post-use steps (sign out, re-seal, file an incident report, review audit logs, rotate the password)
- Who to notify when break-glass is used (CISO, security team, relevant management)

Store this document separately from the physical keys — it should be accessible without opening the sealed envelope.

---

## Operational Procedures

### When to Use Break-Glass

Break-glass accounts are for **tenant recovery only**. Authorised use cases:

- All Global Administrator accounts are locked out or compromised
- The federated identity provider is unavailable and all cloud-synced admin accounts are inaccessible
- MFA service outage makes all normal admin sign-ins impossible
- Emergency revocation of a compromised admin account requires immediate tenant-level access

### Post-Use Protocol (Mandatory)

Every use of a break-glass account — including tests — must follow this protocol:

1. Sign out immediately after completing the required actions.
2. File an incident record documenting: who used the account, when, from which location/IP, and what actions were taken.
3. Review the Entra sign-in audit log to confirm the scope of actions taken.
4. Change the account password and re-register the FIDO2 key.
5. Re-seal the new credentials in a new tamper-evident envelope.
6. Notify the CISO and relevant stakeholders within 24 hours.

### Periodic Review (Quarterly)

| Review Item | Action |
| --- | --- |
| Confirm accounts are enabled | Check account status in Entra admin center |
| Confirm Global Administrator is still assigned | Verify role in **Roles & admins** |
| Confirm CA exclusion is in place on all policies | Review all CA policies for exclusion group membership |
| Confirm alert rule is active | Test alert by querying sign-in logs manually |
| Confirm physical key is accessible | Verify sealed package integrity — do not open unless seals are broken |
| Confirm stored procedure document is current | Update if tenant name, contacts, or procedures have changed |

---

## Checklist

- [ ] `bg-admin-01@<tenant>.onmicrosoft.com` created — cloud-only, `.onmicrosoft.com` UPN
- [ ] `bg-admin-02@<tenant>.onmicrosoft.com` created — cloud-only, `.onmicrosoft.com` UPN
- [ ] Both accounts: password set to never expire
- [ ] Both accounts: Global Administrator assigned as **permanent active** (not PIM-eligible)
- [ ] FIDO2 key registered on `bg-admin-01` — dedicated key, labelled
- [ ] FIDO2 key registered on `bg-admin-02` — dedicated key, labelled, separate from key 01
- [ ] `grp-break-glass-exclusion` group created with both accounts as members
- [ ] Group excluded from **every** Conditional Access policy in the tenant
- [ ] Entra sign-in logs routed to Log Analytics Workspace
- [ ] Alert rule created — severity 0, fires on any sign-in from either account
- [ ] End-to-end sign-in validated for both accounts (FIDO2 key → Entra admin center → Global Administrator confirmed)
- [ ] Sign-in alert confirmed to fire during validation test
- [ ] Credentials sealed in tamper-evident envelopes — stored in separate physical locations
- [ ] Break-glass procedure document written and stored separately from keys
- [ ] Quarterly review cadence established

---

[← Secure Break-Glass Accounts Track](README.md) | [← Back to Azure Hands-On Engineering](../README.md)
