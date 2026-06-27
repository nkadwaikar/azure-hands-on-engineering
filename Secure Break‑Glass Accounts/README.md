# Secure Break‑Glass Accounts Track

This track covers the design, implementation, and monitoring of emergency access accounts in Microsoft Entra ID — following Microsoft's 2025 security baseline with phishing-resistant MFA and Conditional Access enforcement, ensuring tenant recovery is possible without bypassing zero-trust controls.

## Track Structure

```text
Secure Break‑Glass Accounts/
├── 1-Secure Break‑Glass Accounts.md
└── 2-Certificate-Based Authentication(CBA)for Emergency Access Accounts.md
```

## Lab Sequence

1. [Break‑Glass & Emergency Access Accounts (FIDO2)](1-Secure%20Break%E2%80%91Glass%20Accounts.md) — create cloud-only emergency accounts backed by FIDO2 security keys, enforce Authentication Strength via Conditional Access, configure monitoring alerts, and validate a full tenant-lockout recovery scenario
2. [Certificate-Based Authentication for Emergency Accounts](2-Certificate-Based%20Authentication(CBA)for%20Emergency%20Access%20Accounts.md) — provision self-signed certificates, upload the root CA to Entra ID, and enforce CBA as the phishing-resistant MFA method when FIDO2 keys are unavailable

## Prerequisites

- **Global Administrator** role on the target Microsoft Entra ID tenant
- A non-production or isolated tenant recommended for initial testing
- FIDO2 security key (2 recommended) for Lab 1, or a device supporting X.509 certificates for Lab 2
- Microsoft Entra admin center access — no CLI or PowerShell required for Lab 1
- Estimated time: 90–120 minutes per lab

---

[← Back to Azure Hands-On Engineering](../README.md)
