# Secure Break-Glass Accounts Track

This track implements Microsoft's 2025 security baseline for emergency access accounts — phishing-resistant MFA, Conditional Access enforcement, and an operational runbook for break-glass use.

## Track Structure

```text
Secure Break‑Glass Accounts/
`-- 1-Secure Break‑Glass Accounts.md
```

## Lab Sequence

1. [Secure Break-Glass Accounts](1-Secure%20Break%E2%80%91Glass%20Accounts.md) — create cloud-only emergency accounts with FIDO2/CBA, configure Authentication Strength policies, enforce Conditional Access, and document the monitoring and runbook pattern

## What it covers

- Cloud-only emergency account creation and naming conventions
- FIDO2 security key and Certificate-Based Authentication (CBA) configuration
- Authentication Strength Conditional Access policy
- Break-glass account exclusion design (and why 2025 baseline no longer recommends blanket CA exclusions)
- Monitoring, alerting, and incident runbook

## Prerequisites

- Microsoft Entra tenant with **Global Administrator** role
- Microsoft Entra ID P1 or P2 licensing
- FIDO2 security keys provisioned for break-glass use
- Access to the [Microsoft Entra admin center](https://entra.microsoft.com)
