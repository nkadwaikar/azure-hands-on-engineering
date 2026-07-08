# Zero Trust Advanced Lab

## Conditional Access · Risk-Based Policies · Session Controls · Passwordless · Phishing-Resistant MFA

> **Why this matters:** Legacy Conditional Access configurations that only check "is the user licensed?" leave the tenant wide open to token theft, impossible travel, and compromised credentials — this lab implements risk-based blocking, device compliance gates, session controls via Defender for Cloud Apps, and custom Authentication Strengths so access decisions are continuously evaluated against real-time identity risk signals.

Last validated on: 2026-07-06

---

## Summary

This lab implements advanced Zero Trust controls across Microsoft 365 using admin portals only. You will create a complete set of Conditional Access policies for admin protection, risk-based blocking, device compliance, and session controls. You will configure custom Authentication Strengths for phishing-resistant MFA, deploy session controls via Microsoft Defender for Cloud Apps, and validate the full Zero Trust posture.

**Estimated time:** 4–5 hours
**License required:** Entra ID P2 for risk-based policies; Microsoft 365 E5 or Defender for Cloud Apps for session controls
**Portals used:**

- [Entra Admin Center](https://entra.microsoft.com)
- [Microsoft Defender portal](https://security.microsoft.com)
- [Microsoft Intune Admin Center](https://intune.microsoft.com)

---

## Table of Contents

1. [Conditional Access Advanced](#1-conditional-access-advanced)
2. [Authentication Strength](#2-authentication-strength)
3. [Session Controls](#3-session-controls)
4. [Zero Trust Architecture](#4-zero-trust-architecture)
5. [Validation](#5-validation)
6. [Next Steps](#6-next-steps)

---

## 1. Conditional Access Advanced

### 1.1 Design Philosophy

Conditional Access is the Zero Trust policy engine. Every access request is evaluated against conditions — identity, device, location, app, risk — and a decision is made: allow, block, or allow with controls.

**Policy deployment order (follow this sequence to avoid lockouts):**

1. Create emergency access (break-glass) accounts first
2. Exclude break-glass from all policies
3. Deploy admin policies
4. Deploy user policies
5. Deploy session policies

### 1.2 Create Emergency Access (Break-Glass) Accounts

Break-glass accounts are used only if all Conditional Access policies lock out administrators.

1. **Entra Admin Center** → **Users** → **All users** → **+ New user** → **Create new user**

Create two accounts:

| Field | Account 1 | Account 2 |
| ----- | --------- | --------- |
| Display name | Break Glass 01 | Break Glass 02 |
| UPN | <breakglass01@yourdomain.com> | <breakglass02@yourdomain.com> |
| Password | Generate a strong random password | Same |
| Password expiration | Never expires | Never expires |

1. Assign **Global Administrator** role to both accounts:
   - Open each account → **Assigned roles** → **+ Add assignments** → **Global Administrator**

2. Create an exclusion group:
   - **Entra Admin Center** → **Groups** → **+ New group**
   - Name: `CA-Exclusions-BreakGlass` | Type: Security
   - Add both break-glass accounts as members

> Store break-glass credentials in an offline vault (printed and sealed, or hardware-encrypted USB). Monitor their use via alerts in Entra ID.
> **Cross-track reference:** For production-grade break-glass accounts using FIDO2 hardware keys and Certificate-Based Authentication (CBA), see the [Secure Break-Glass Accounts track](../Secure%20Break%E2%80%91Glass%20Accounts/README.md). The accounts created here are sufficient for this lab — the Break-Glass track covers CBA enrollment, monitoring alert configuration, and Key Vault secret storage patterns required in regulated environments. The same accounts and exclusion group protect both Azure and M365 admin access.

### 1.3 Conditional Access Policies

All policies are created at:
**Entra Admin Center** → **Protection** → **Conditional Access** → **Policies** → **+ New policy**

---

#### Policy 1: Require Passwordless MFA for Admins

| Field | Value |
| --- | --- |
| Name | CA001 - Require Passwordless for Admins |
| Users | Include: **Directory roles** → select all admin roles (Global Admin, Security Admin, Exchange Admin, SharePoint Admin, Compliance Admin, etc.) |
| Users | Exclude: **Groups** → `CA-Exclusions-BreakGlass` |
| Target resources | **All cloud apps** |
| Grant | **Require authentication strength** → select **Phishing-resistant MFA** (create this in Section 2 first) |
| Enable policy | **On** |

---

#### Policy 2: Block High-Risk Sign-Ins

> Requires Entra ID P2 (Identity Protection)

| Field | Value |
| ------- | ------- |
| Name | CA002 - Block High-Risk Sign-Ins |
| Users | Include: **All users** |
| Users | Exclude: `CA-Exclusions-BreakGlass` |
| Target resources | **All cloud apps** |
| Conditions | **User risk** → **High** |
| Conditions | **Sign-in risk** → **High** |
| Grant | **Block access** |
| Enable policy | **On** |

---

#### Policy 3: Require Compliant Device or Approved App

| Field | Value |
| --- | --- |
| Name | CA003 - Require Compliant Device or Approved App |
| Users | Include: **All users** |
| Users | Exclude: `CA-Exclusions-BreakGlass` |
| Target resources | **All cloud apps** |
| Grant | **Require device to be marked as compliant** OR  **Require approved client app** |
| Grant operator | **Require one of the selected controls** (OR) |
| Enable policy | **Report-only** (switch to On after validating device compliance coverage) |

---

#### Policy 4: Session Controls for SharePoint and Teams

| Field | Value |
| --- | --- |
| Name | CA004 - Session Controls for SharePoint and Teams |
| Users | Include: **All users** |
| Users | Exclude: `CA-Exclusions-BreakGlass` |
| Target resources | **Select apps** → search and add **Office 365 SharePoint Online** and **Microsoft Teams** |
| Grant | **Require multifactor authentication** |
| Session | **Sign-in frequency** → **8 hours** |
| Session | **Persistent browser session** → **Never persistent** |
| Session | **Use app enforced restrictions** (enables SharePoint and Exchange to enforce session policy) |
| Enable policy | **On** |

---

### 1.4 Verify Policies

1. **Entra Admin Center** → **Protection** → **Conditional Access** → **Policies**
2. All four policies should appear with correct state (On or Report-only)
3. Use **What If** tool to simulate sign-in scenarios:
   - **Protection** → **Conditional Access** → **What If**
   - Test: Admin user → All apps → What policies apply?
   - Expected: CA001 fires (passwordless required)

---

## 2. Authentication Strength

Authentication Strength defines which MFA methods are accepted. Custom strengths let you require phishing-resistant methods for sensitive scenarios.

### 2.1 Why Phishing-Resistant MFA

| Method | Phishing Resistant | Notes |
| --- | --- | --- |
| FIDO2 Security Key | Yes | Hardware key; cryptographically bound to the site origin |
| Windows Hello for Business | Yes | TPM-backed; PIN or biometric; domain-bound |
| Certificate-Based Authentication | Yes | Smart card or software certificate; PKI-bound |
| Microsoft Authenticator (Passwordless) | Yes | Number match; push notification; no password |
| TOTP / Authenticator OTP | No | Interceptable in real-time AiTM phishing attacks |
| SMS OTP | No | Highly susceptible to SIM-swap and phishing |

### 2.2 Create Custom Authentication Strength

1. **Entra Admin Center** → **Protection** → **Authentication methods** → **Authentication strengths** → **+ New authentication strength**
| Field       | Value                                                                                |
| ----------- | ------------------------------------------------------------------------------------ |
| Name        | Phishing-Resistant MFA                                                               |
| Description | Requires FIDO2, Windows Hello for Business, CBA, or Authenticator passwordless       |
2. Under **Allowed method combinations**, select:
   - FIDO2 security key
   - Windows Hello for Business
   - Microsoft Authenticator (passwordless phone sign-in)
   - Certificate-based authentication (multifactor)
   - Deselect all other combinations
3. Click **Next** → **Create**
4. Return to **CA001** → **Grant** → change to **Require authentication strength** → select **Phishing-Resistant MFA** → **Save**

### 2.3 Enable FIDO2 Security Keys

1. **Entra Admin Center** → **Protection** → **Authentication methods** → **Policies**
2. Select **FIDO2 security key**
3. Toggle **Enable** → **On**
4. Target: **All users** (or a pilot group first)
5. Configure:
   - Allow self-service setup
   - Enforce attestation
   - Key restrictions: leave open (or restrict to specific AAGUID if required)
6. Click **Save**

**Direct users to register:** [aka.ms/mysecurityinfo](https://aka.ms/mysecurityinfo)

---

## 3. Session Controls

Session controls restrict what users can do after successful authentication — enforced by Microsoft Defender for Cloud Apps acting as a reverse proxy.

### 3.1 Enable Defender for Cloud Apps Integration

1. **Entra Admin Center** → **Enterprise applications** → search **Microsoft Cloud App Security**
2. Ensure the app is enabled
3. Verify: your Conditional Access policy CA004 includes **Use app enforced restrictions** — this enables the proxy integration

### 3.2 Configure Session Policies in Defender for Cloud Apps

1. Go to **Microsoft Defender portal** → **Cloud apps** → **Policies** → **Policy management** → **+ Create policy** → **Session policy**

### Session Policy 1: Block Download of Confidential Files

| Field | Value |
| --- | --- |
| Policy name | Block Download - Confidential Content |
| Session control type | **Control file download (with inspection)** |
| Activity source | App: **SharePoint Online**, **Microsoft Teams** |
| Content inspection | Enable; match sensitivity label: **Confidential** or **Highly Confidential** |
| Action | **Block** |
| Customize block message | *"Downloading classified content is restricted on this device. Contact IT if you need access."* |
| Severity | High |
| Alerts | Send alert to admins |

Click **Create**

#### Session Policy 2: Restrict Unmanaged Device Access

| Field | Value |
| ------- | ------- |
| Policy name | Restrict Access - Unmanaged Devices |
| Session control type | **Block activities** |
| Device filter | Device management: **is not** Intune compliant AND **is not** hybrid Azure AD joined |
| Activities to block | Download,  Print,  Copy |
| Action | Block |

### 3.3 Session Control Reference

| Control | Purpose | When to apply |
| --- | --- | --- |
| Block download | Prevents data exfiltration from browser | Unmanaged devices, high-risk users |
| Restrict access | Read-only access to apps | BYOD, external users |
| Sign-in frequency (8 hrs) | Forces re-authentication regularly | All users on sensitive apps |
| Never persistent browser | No "stay signed in" | Shared or lab devices |

---

## 4. Zero Trust Architecture

### 4.1 Zero Trust Pillars in Microsoft 365

```text
┌─────────────────────────────────────────────────────────────────┐
│                     ZERO TRUST ARCHITECTURE                      │
│                  "Never Trust, Always Verify"                    │
└─────────────────────────────────────────────────────────────────┘

  IDENTITY              DEVICE               NETWORK
  ─────────────         ─────────────        ─────────────
  Entra ID P2           Intune Compliance    No implicit trust
  Conditional Access    Defender for         based on network
  Passwordless MFA      Endpoint             location
  PIM (just-in-time)    Health Attestation

  APPLICATIONS          DATA                 TELEMETRY
  ─────────────         ─────────────        ─────────────
  Defender for          Sensitivity Labels   Defender XDR
  Cloud Apps (CASB)     DLP Policies         Entra Sign-in Logs
  App Governance        Encryption           Purview Audit
  Conditional Access    Rights Mgmt          Compliance Manager
```

### 4.2 Zero Trust Policy Matrix

| User type | Device state | Risk level | Required controls |
| --- | --- | --- | --- |
| Admin | Compliant | Low | Phishing-resistant MFA (CA001) |
| Admin | Any | Medium or High | Block (CA002) |
| User | Compliant | Low | MFA (CA003) |
| User | Unmanaged | Low | MFA + session restrictions (CA003 + CA004) |
| User | Any | High | Block (CA002) |
| Guest | Unmanaged | Any | MFA + download block (CA003 + Defender for Cloud Apps session policy) |

---

## 5. Validation

| Test | How to Test | Expected Result |
| --- | --- | --- |
| Passwordless for admins | Sign in to admin account with password + TOTP | Blocked; prompted for FIDO2, WHfB, or Authenticator passwordless |
| Block high-risk sign-in | Check **Entra** → **Security** → **Identity Protection** → **Risky sign-ins** | High-risk sign-ins show blocked status |
| Device compliance | Sign in from a non-Intune-enrolled device | Prompted to use compliant device or approved app |
| Session frequency | Sign in to SharePoint; leave session idle 8+ hours | Re-authentication prompted on next action |
| Block download | On an unmanaged device (browser), try to download a Confidential doc from SharePoint | Download blocked with custom message |
| FIDO2 registration | Log in as test user → My Security Info → Add sign-in method → Security key | Key registered successfully |
| Persistent browser | Sign in on a browser | "Stay signed in?" prompt absent; session ends at browser close |
| Break glass access | Sign in with break-glass account to any M365 app | Full access granted (excluded from all CA policies) |
| What If tool | **Entra** → **Conditional Access** → **What If** → simulate admin sign-in | CA001 listed as applied policy |

---

## 6. Next Steps

- [Lab 6: Identity Governance (Lifecycle Workflows)](6-identity-governance-lifecycle-workflows.md)

---

[← Lab 4: Compliance Automation](4-compliance-automation.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
