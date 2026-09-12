# Defender for Identity Track

Last validated on: September 2026

[![Duration](https://img.shields.io/badge/Duration-1.75--2.75%20hours-0A66C2?style=flat-square)](#lab-sequence)
[![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-0052CC?style=flat-square)](#lab-sequence)

> **Why this matters:** Hybrid identity attacks often begin on-premises and then pivot into cloud control planes. Microsoft Defender for Identity provides identity-native detections for Active Directory reconnaissance, credential theft, lateral movement, and domain dominance activity, then correlates those signals in Microsoft Defender XDR for faster investigation and containment.

---

## Coverage

This track focuses on onboarding domain controllers to Defender for Identity, validating sensor health, hardening posture, and operationalizing identity detections in Microsoft Defender XDR.

| Topic | What it covers |
| --- | --- |
| **Defender for Identity Onboarding** | Enable the identities workload and onboard domain controllers |
| **Sensor Health Validation** | Verify DC coverage, service status, and health alerts |
| **Identity Security Posture** | Review identity recommendations and misconfiguration findings |
| **Detection & Investigation** | Investigate identity alerts and lateral movement evidence in Defender XDR |
| **Attack Path Context** | Understand user/device/domain relationships exposed through identity signals |
| **Operational Readiness** | Build a repeatable checklist for monitoring and response |

---

## Prerequisites

- [Deploying a Domain Controller in Azure](../Deploying%20a%20Domain%20Controller%20in%20Azure/README.md) completed with at least one healthy domain controller
- [Defender for Servers](../Defender%20for%20Servers/README.md) completed or in progress (recommended for unified endpoint + identity investigation)
- Microsoft Defender XDR tenant with Defender for Identity licensing enabled
- Security permissions to manage Defender settings and investigate incidents

---

## Track Structure

```text
Defender for Identity/
├── README.md                      ← Track entry point (this file)
├── 1-defender-for-identity.md     ← Lab 1: Onboard, validate, investigate
└── 2-advanced-identity-investigation.md ← Lab 2: Advanced incident triage and response
```

## Lab Sequence

1. [Microsoft Defender for Identity — Onboarding, Health Validation, and Detection Workflow](1-defender-for-identity.md) — enable identities workload, onboard domain controllers, validate sensor and directory service account health, triage identity alerts, and baseline recurring operational checks

2. [Microsoft Defender for Identity — Advanced Investigation and Response Workflow](2-advanced-identity-investigation.md) — investigate high-severity identity incidents, analyze lateral movement and privilege risk, correlate identity and endpoint evidence, and execute containment in a repeatable order

---

## Connection to Other Tracks

| Track | Relationship |
| --- | --- |
| [Deploying a Domain Controller in Azure](../Deploying%20a%20Domain%20Controller%20in%20Azure/README.md) | Supplies the AD DS infrastructure Defender for Identity monitors |
| [Defender for Servers](../Defender%20for%20Servers/README.md) | Correlates server and identity telemetry in shared Defender XDR incidents |
| [Identity-First](../Identity-First/README.md) | Extends Zero Trust design from preventive controls into identity threat detection |
| [Copilot for Security](../Copilot%20for%20Security/README.md) | Uses Defender for Identity alerts and entities for faster analyst triage |

---

[← Back to Azure Hands-On Engineering](../README.md)
