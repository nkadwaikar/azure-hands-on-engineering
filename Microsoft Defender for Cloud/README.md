# Microsoft Defender for Cloud Track

Last validated on: July 2026

This track covers workload protection and secure access controls using Microsoft Defender for Cloud — enabling Defender for Servers plan coverage, managing Secure Score and recommendations, running vulnerability assessments, monitoring with File Integrity Monitoring (FIM), and enabling Just-In-Time VM access for zero-standing-access connectivity.

## Key Concepts

| Concept | Description |
| --- | --- |
| **Defender for Servers** | Cloud workload protection plan that adds threat detection, vulnerability assessment, FIM, and EDR via MDE to Azure VMs and Arc-enabled servers |
| **Secure Score** | 0–100% KPI measuring your subscription's security posture; driven by completing prioritized recommendations |
| **Vulnerability Assessment** | CVE scanning for installed software via MDE integration — no separate scanner agent required |
| **File Integrity Monitoring (FIM)** | Tracks changes to critical OS files, registry keys, and directories; logs events to Log Analytics |
| **Just-In-Time (JIT) Access** | Time-bounded, IP-scoped NSG port openings managed by Defender for Cloud — no standing inbound access between sessions |

## Track Structure

```text
Microsoft Defender for Cloud/
├── 1-JIT.md                   # Hands-on: JIT VM access + Azure Bastion zero-standing-access pattern
└── 2-Defender-for-Servers.md  # Hands-on: Enable plan, Secure Score, vulnerability assessment, FIM, alerts
```

## Lab Sequence

> **Recommended order:** Complete Lab 2 (Defender for Servers) before Lab 1 (JIT) if you are new to the Defender for Cloud portal — Lab 2 walks through enabling the plan and navigating the Defender for Cloud blade, which Lab 1 depends on.

1. [Microsoft Defender for Servers — Workload Protection for Azure and Arc Servers](2-Defender-for-Servers.md) — enable Defender for Servers Plan 2, review Secure Score and recommendations, run vulnerability assessment, enable File Integrity Monitoring, and investigate a test security alert

2. [Bastion + Just-In-Time (JIT) VM Access](1-JIT.md) — configure JIT access via Microsoft Defender for Cloud, request time-bounded port openings, connect through Azure Bastion, and validate NSG rule auto-removal

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- Azure Bastion deployed (for Lab 2) — complete the [Azure Bastion track](../Azure%20Bastion/README.md) first
- At least one running Azure VM or Arc-enabled server
- For Arc coverage: complete the [Azure Arc Hybrid Server Architecture track](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) first

## Related Tracks

| Track | Relationship |
| --- | --- |
| [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) | Arc-enabled servers are onboarded to Defender for Cloud in Section 6 of the Arc Architecture guide |
| [Azure Update Manager](../Azure%20Update%20Manager/README.md) | Defender for Servers surfaces missing patch recommendations; Update Manager remediates them |
| [Azure Bastion](../Azure%20Bastion/README.md) | Required dependency for JIT lab — Bastion provides the browser-based session after JIT opens the port |

---

[← Back to Azure Hands-On Engineering](../README.md)
