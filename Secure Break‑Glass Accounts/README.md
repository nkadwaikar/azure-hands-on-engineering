# Secure Break-Glass Accounts Track

This track implements Microsoft's 2025 security baseline for emergency access accounts — phishing-resistant MFA, Conditional Access enforcement, and an operational runbook for break-glass use.

## Track Structure

```text
Secure Break‑Glass Accounts/
|-- 1-Secure Break‑Glass Accounts.md
`-- 2-Certificate-Based Authentication(CBA)for Emergency Access Accounts.md
```

## Lab Sequence

1. [Secure Break-Glass Accounts](1-Secure%20Break%E2%80%91Glass%20Accounts.md) — create cloud-only emergency accounts with FIDO2 security keys as the primary phishing-resistant MFA method, configure Authentication Strength policies, enforce Conditional Access, and document the monitoring and runbook pattern
2. [Certificate-Based Authentication (CBA)](2-Certificate-Based%20Authentication%28CBA%29for%20Emergency%20Access%20Accounts.md) — deep-dive into CBA as an alternative phishing-resistant method; covers certificate generation (PowerShell), uploading the root CA to Entra ID, configuring certificate-to-user mapping, and enforcing CBA via Authentication Strength — without excluding accounts from Conditional Access

## What it covers

**Lab 1 (FIDO2):**
- Cloud-only emergency account creation and naming conventions
- FIDO2 security key registration as primary phishing-resistant MFA
- Authentication Strength Conditional Access policy (FIDO2/CBA)
- Why 2025 baseline does not recommend blanket CA exclusions
- Monitoring, alerting, and incident runbook

**Lab 2 (CBA):**
- Certificate generation using PowerShell (self-signed root CA + user certs)
- Uploading the root CA to Entra ID Certificate Authorities trust store
- Configuring CBA authentication binding at MFA level
- Certificate-to-user mapping using Subject Alternative Name UPN
- Authentication Strength and Conditional Access policy enforcing CBA (no CA exclusions)
- Secure device certificate installation and verification

## Prerequisites

- Microsoft Entra tenant with **Global Administrator** role
- Microsoft Entra ID P1 or P2 licensing
- Lab 1: FIDO2 security keys provisioned for break-glass use
- Lab 2: Windows device with PowerShell for certificate generation
- Access to the [Microsoft Entra admin center](https://entra.microsoft.com)

---

[← Back to Azure Hands-On Engineering](../README.md)
