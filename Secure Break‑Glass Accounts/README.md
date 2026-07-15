# Secure Break-Glass Accounts Track

Last validated on: 2026-07-14

This track covers the design, configuration, and validation of emergency access accounts in Microsoft Entra ID — accounts that allow tenant recovery when all normal authentication paths are unavailable (federated identity provider outage, MFA service disruption, accidental lock-out of all administrators).

## Track Structure

```text
Secure Break-Glass Accounts/
├── README.md                          ← Track entry point
└── 1-Secure-Break-Glass-Accounts.md  ← Lab Guide: design, configure, validate, and alert on break-glass accounts
```

## Lab Sequence

1. [Secure Break-Glass Accounts](1-Secure-Break-Glass-Accounts.md) — create cloud-only emergency access accounts, register FIDO2 security keys, exclude accounts from all Conditional Access policies, configure sign-in alerting, validate access end-to-end, and seal credentials offline

## Key Concepts

| Concept | Description |
| --- | --- |
| **Break-Glass Account** | Highly privileged, permanently active cloud-only account used exclusively when all normal admin authentication paths fail |
| **FIDO2 Security Key** | Phishing-resistant hardware authenticator used as the primary credential — eliminates all password and software-MFA dependencies |
| **Certificate-Based Authentication (CBA)** | Second independent credential path using a client certificate — provides access if FIDO2 keys are lost or damaged |
| **Cloud-Only Identity** | Accounts use `.onmicrosoft.com` UPN — never federated or synced from AD DS, so they remain usable even if the identity provider is down |
| **CA Policy Exclusion** | Break-glass accounts are explicitly excluded from every Conditional Access policy — intentional, documented, and monitored |
| **Global Administrator** | Minimum role required to recover tenant access in all failure scenarios — break-glass accounts hold this permanently |
| **Sign-In Alert** | Azure Monitor alert fires on any sign-in from these accounts — every use is treated as a security event requiring post-incident review |

## Prerequisites

| Requirement | Detail |
| --- | --- |
| **Role** | Global Administrator on the Entra tenant |
| **Hardware** | At least two physical FIDO2 security keys (YubiKey 5 series or equivalent) — one per account |
| **Licensing** | Microsoft Entra ID P1 or P2 (required for Conditional Access) |
| **Portal** | Access to [Microsoft Entra admin center](https://entra.microsoft.com) |
| **Monitoring** | Log Analytics Workspace available for sign-in alert routing |

> **Security note:** Break-glass credentials are extremely sensitive. Physical FIDO2 keys and any printed recovery codes must be stored in a tamper-evident sealed envelope in a locked, access-controlled physical location — never in a digital password manager, key vault, or cloud storage.

## Related Tracks

| Track | Relationship |
| --- | --- |
| [Identity-First](../Identity-First/README.md) | Foundation track — RBAC, Managed Identity, and governance patterns that break-glass accounts operate within |
| [Microsoft Entra Backup & Recovery](../Microsoft%20Entra%20Backup%20%26%20Recovery/README.md) | Directory-level recovery procedures; break-glass accounts are the access path when recovery operations are required |
| [Microsoft Defender for Cloud](../Microsoft%20Defender%20for%20Cloud/README.md) | Defender for Cloud surfaces risky sign-ins — break-glass usage triggers high-severity alerts there as well |

---

[← Back to Azure Hands-On Engineering](../README.md)
