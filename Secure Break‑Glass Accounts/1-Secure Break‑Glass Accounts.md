# Microsoft Entra Break‑Glass & Emergency Access Accounts

> **Why this matters:** Every tenant lockout scenario — misconfigured CA policies, federated IdP failure, MFA service degradation — comes down to whether your emergency accounts actually work under zero-trust constraints; this lab builds FIDO2-backed break-glass accounts that comply with Microsoft's 2025 security baseline rather than bypassing it.

A complete, portal-only lab implementing Microsoft's 2025 security baseline for emergency access accounts with phishing-resistant MFA and Conditional Access enforcement.

Last validated on: 2026-06-20  
Portal experience note: Steps validated against Entra Admin Center as of June 2026.

> **Note:** This lab uses cloud-only emergency accounts with FIDO2/CBA and Authentication Strength policies. These accounts are NOT excluded from Conditional Access. The design follows Microsoft's 2025 identity security baseline requiring all admins to use phishing-resistant MFA.

---

## Module Structure

```text
Secure Break‑Glass Accounts/
`-- 1-Secure Break‑Glass Accounts.md
```

This module is a focused single-lab implementation guide for modern break-glass account design.

## Quick Navigation

- [Module Structure](#module-structure)
- [Prerequisites](#prerequisites)
- [Learning Objectives](#learning-objectives)
- [Scenario](#scenario)
- [Design Principles](#design-principles)
- [Hands-On Implementation](#hands-on-implementation)
- [Conditional Access Configuration](#conditional-access-configuration)
- [Testing, Monitoring, and Runbook](#testing-monitoring-and-runbook)

---

## Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Global Administrator** on the target Entra ID tenant |
| Tenant Type | Cloud-only (hybrid/federated not required) |
| MFA Hardware | FIDO2 security key (2 recommended) or Certificate-based authentication support |
| Estimated Time | 90-120 minutes |
| Tools | Entra Admin Center only — no CLI or PowerShell required |

### Assumptions and Scope Boundaries

- This lab uses a non-production or isolated Entra ID tenant for testing.
- Break‑glass accounts are cloud-only with no federation or external IdP.
- PIM (Privileged Identity Management) is NOT used; roles are Active assignments.
- Monitoring is discussed but full Sentinel/Log Analytics integration is out of scope.
- This follows Microsoft's 2025 baseline; legacy break‑glass designs (with MFA bypass) are deprecated.

---

## Learning Objectives

By the end of this lab, you will have:

- Two cloud-only emergency accounts with phishing-resistant MFA (FIDO2/CBA)
- Global Administrator roles assigned (Active, not PIM-eligible)
- A custom Authentication Strength policy enforcing FIDO2/CBA only
- A Conditional Access policy protecting break‑glass accounts
- Monitoring and alerting configured for all emergency account sign-ins
- Tested break‑glass recovery scenarios
- A documented runbook for lockout recovery

This is the exact design pattern required by Microsoft's 2025 security baseline.

---

## Scenario

**Ensure Operational Continuity with Secure Emergency Access.**

Your tenant is locked out due to:

- Misconfigured Conditional Access policies blocking all admins
- MFA outage affecting standard admin accounts
- Network restrictions preventing access from corporate locations

Break‑glass accounts remain functional because they:

- Use phishing-resistant FIDO2 keys (not dependent on Authenticator app)
- Are protected by dedicated Authentication Strength (not bypassed)
- Maintain access during outages (Conditional Access still enforces, but break‑glass can authenticate)

This lab walks through creating, testing, and validating this scenario

---

## 1. Design Principles for Secure Break‑Glass Accounts

### 1.1 Two Cloud‑Only Emergency Accounts

- No federation, no sync, no external IdP

### 1.2 Global Administrator Role

- Active assignment (not PIM‑eligible)

### 1.3 Phishing‑Resistant MFA (Required)

- FIDO2 security keys (preferred)
- Certificate‑based authentication (CBA) (alternative)
- Windows Hello for Business (acceptable)
- **Blocked:** Authenticator app, SMS, voice, password-only

### 1.4 Conditional Access Enforced

- Break‑glass accounts are NOT excluded from CA
- Protected by dedicated Authentication Strength policy

### 1.5 Monitoring & Alerting

- Every break‑glass sign-in generates an alert
- Role changes, MFA modifications tracked

### 1.6 Tested & Documented

- Recovery runbook maintained
- Quarterly break‑glass tests performed

---

## 2. Hands‑On Lab: Create & Secure Break‑Glass Accounts

### 2.1 Create Two Cloud‑Only Emergency Accounts

1. Navigate to **Entra Admin Center** → **Users** → **+ New User**
2. Create your first emergency account:
   - **User principal name:** `emergency-admin-01@tenant.onmicrosoft.com` (replace `tenant` with your actual tenant)
   - **Display name:** `Emergency Admin 01`
   - **Password:** Generate a long, random password (16+ characters with mixed case, numbers, symbols)
   - Click **Create**
3. Repeat for the second account:
   - **User principal name:** `emergency-admin-02@tenant.onmicrosoft.com`
   - **Display name:** `Emergency Admin 02`
   - **Password:** Generate another unique long password
   - Click **Create**
4. **Important:** Sign in as each emergency account once to complete setup
5. Store passwords securely in a password manager or a sealed envelope kept in physical security

---

### 2.2 Assign Global Administrator Role

1. Navigate to **Entra Admin Center** → **Roles & Administrators** → **Global Administrator**
2. Click **+ Add Assignments**
3. Search for and select **Emergency Admin 01**
4. Click **Add** (verify **Assignment type** is set to **Active**, not **Eligible**)
5. Repeat for **Emergency Admin 02**
6. **Verification:** Both emergency accounts should now appear under Global Administrator assignments

---

### 2.3 Configure Phishing‑Resistant MFA

Microsoft now requires MFA for all admins. Complete this step for each emergency account:

1. Sign in to **<https://myaccount.microsoft.com>** as **Emergency Admin 01**
2. Navigate to **Security Info** → **+ Add sign-in method** → **Security key**
3. **Register FIDO2 Security Key (Recommended):**
   - Click **+ Add method** → **Security key**
   - Follow the on-screen prompts to register your FIDO2 key
   - Test the key by signing out and back in
4. **Register Certificate-Based Authentication (Optional but Recommended):**
   - Click **+ Add method** → **Certificate-based authentication**
   - Follow the enrollment process
5. **Remove Weak MFA Methods:**
   - Delete any **SMS** or **Voice call** methods
   - Delete **Authenticator app** if present (use only FIDO2/CBA)
6. **Verification:** Only FIDO2 and/or CBA should remain
7. **Repeat for Emergency Admin 02**

---

## 3. Conditional Access Configuration

Break‑glass accounts must not be excluded from Conditional Access. Instead, they must be protected by a dedicated Authentication Strength policy.

### 3.1 Create Authentication Strength

1. Navigate to **Entra Admin Center** → **Protection** → **Authentication Strengths**
2. Click **+ Create authentication strength**
3. Configure:
   - **Name:** `Emergency Admin – Phishing Resistant Only`
   - **Description:** `Restricted MFA methods for break-glass accounts`
4. Under **Allowed Methods**, select:
   - FIDO2 security keys
   - Certificate-based authentication
   - Windows Hello for Business
5. Under **Blocked Methods**, ensure these are NOT selected:
   - Authenticator app
   - SMS or Voice calls
   - Password only
6. Click **Create**

---

### 3.2 Create Conditional Access Policy

1. Navigate to **Entra Admin Center** → **Protection** → **Conditional Access**
2. Click **+ Create new policy**
3. Configure the policy:

   **Basic Information:**
   - **Name:** `Emergency Admin – Phishing‑Resistant MFA Required`
   - **Enable policy:** Toggle **On**

   **Assignments:**
   - **Users:**
     - Click **Include** → **Select users and groups**
     - Select **Emergency Admin 01** and **Emergency Admin 02**
   - **Target resources:**
     - Click **Include** → **Select what this policy applies to** → **All cloud apps**
   - **Conditions:**
     - No additional conditions needed (applies to all scenarios)

   **Access Controls:**
   - Click **Grant** → **Require authentication strength**
   - Select **Emergency Admin – Phishing Resistant Only**
   - Click **Select**

4. Click **Create**

**Result:** This ensures:

- Break‑glass accounts must use FIDO2/CBA
- They cannot use weak MFA
- They cannot bypass CA
- They remain usable during outages

---

## 4. Monitoring & Alerting

Every sign‑in by a break‑glass account must trigger an alert.

### 4.1 What to Monitor

1. **Sign‑in logs** — Track all break‑glass account sign‑ins
2. **Audit logs** — Monitor role assignments and MFA changes
3. **Role assignment changes** — Alerts when break‑glass roles change
4. **MFA method changes** — Alerts if MFA is disabled or modified
5. **Conditional Access policy changes** — Monitor CA modifications

### 4.2 Recommended Alerting Tools

- **Entra ID** — Native sign-in and audit logs
- **Defender for Cloud Apps** — Advanced threat detection
- **Sentinel** — SIEM integration and automation
- **Log Analytics** — Custom queries and dashboards

### 4.3 Alert Configuration

Set up alerts to trigger when:

- Emergency Admin accounts sign in
- Global Administrator role is assigned
- Authentication methods are modified
- Conditional Access policies are changed

---

## 5. Test the Break‑Glass Scenario

Testing is required for compliance and operational readiness.

### 5.1 Conditional Access Lockout Simulation

1. Create a temporary CA policy that blocks all admins
2. Sign in as your normal (non-emergency) admin account
3. **Expected result:** You are blocked by the CA policy
4. Sign in as **Emergency Admin 01** using FIDO2 key
5. **Validate:**
   - FIDO2 authentication works
   - You successfully sign in despite the blocking CA policy
   - Authentication Strength is enforced
6. Disable or delete the test CA policy
7. Sign in as your normal admin account to verify access is restored

---

### 5.2 MFA Outage Simulation

1. Temporarily disable **Microsoft Authenticator** from your emergency account's MFA methods
2. Attempt to sign in as **Emergency Admin 01**
3. **Validate:**
   - FIDO2/CBA is still available and works
   - You can successfully authenticate without Authenticator
4. Re-enable Authenticator after testing (if needed)

---

### 5.3 Network Restriction Simulation

1. Create a CA policy that blocks all access outside a specific trusted location
2. Attempt to sign in as your normal admin from an untrusted network
3. **Expected result:** Blocked
4. Sign in as **Emergency Admin 01** from the same untrusted network
5. **Validate:**
   - Emergency account successfully authenticates
   - Network restrictions do not apply to break-glass accounts
6. Disable the test policy

---

## 6. Recovery Runbook

If locked out due to a misconfigured Conditional Access policy:

1. **Use FIDO2 key** — Sign in to Azure Portal with your FIDO2 security key
2. **Sign in as Emergency Admin** — Use either Emergency Admin 01 or 02
3. **Navigate to CA policies** — Go to **Entra Admin Center** → **Protection** → **Conditional Access**
4. **Disable or fix the bad policy** — Turn off the problematic policy or modify the conditions
5. **Validate normal admin access** — Sign in as your regular admin account
6. **Rotate break‑glass passwords** — Generate new passwords for both emergency accounts
7. **Review logs** — Check sign-in logs and audit logs for unauthorized attempts
8. **Document the incident** — Create an incident report noting the time, cause, and resolution

---

## 7. Validation Checklist

Before completing the lab, verify:

- Two cloud‑only emergency accounts exist
- Both use phishing‑resistant MFA (FIDO2/CBA)
- Both have Global Administrator role assigned
- Both are protected by Conditional Access
- Authentication Strength is enforced (Phishing Resistant Only)
- No weak MFA methods are enabled (no SMS, Authenticator app)
- Monitoring alerts are configured
- Break‑glass tests completed successfully
- Runbook documented and accessible

---

## 8. Final Summary

This updated lab reflects Microsoft's 2025 identity security baseline, ensuring your break‑glass accounts are:

- **Secure** — Cloud-only, no federation
- **MFA‑protected** — Phishing-resistant methods enforced
- **Phishing‑resistant** — FIDO2/CBA only
- **CA‑enforced** — Protected by Authentication Strength policies
- **Monitored** — All sign-ins generate alerts
- **Tested** — Operational readiness verified
- **Documented** — Runbook and procedures in place
