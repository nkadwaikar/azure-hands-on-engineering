# Microsoft Defender for Cloud Track

Last validated on: July 2026

This track covers workload protection and secure access controls using Microsoft Defender for Cloud — enabling Defender for Servers plan coverage, managing Secure Score and recommendations, running vulnerability assessments, monitoring with File Integrity Monitoring (FIM), and enabling Just-In-Time VM access for zero-standing-access connectivity.

> **Note:** Lab 1 (Defender for Servers) is split across two files — **Part 1** (setup and security posture) and **Part 2** (vulnerability assessment, FIM, alerts, and MDE integration) — to keep each file to a manageable length. Complete Part 1 before Part 2; Lab 2 (JIT) depends on both.

## Key Concepts

| Concept | Description |
| --- | --- |
| **Defender for Servers** | Cloud workload protection plan that adds threat detection, vulnerability assessment, FIM, and EDR via MDE to Azure VMs and Arc-enabled servers |
| **Secure Score** | 0–100% KPI measuring your subscription's security posture; driven by completing prioritized (currently grouped) recommendations |
| **Individual Recommendations** | The emerging per-finding recommendation model (one row per vulnerability/secret/rule) replacing grouped, per-resource recommendations — grouped recommendations are being removed from the Azure portal on July 31, 2026 |
| **Vulnerability Assessment** | CVE scanning for installed software via MDE integration — no separate scanner agent required |
| **File Integrity Monitoring (FIM)** | Tracks changes to critical OS files, registry keys, and directories; logs events to Log Analytics |
| **Just-In-Time (JIT) Access** | Time-bounded, IP-scoped NSG port openings managed by Defender for Cloud — no standing inbound access between sessions |

## Track Structure

```text
Microsoft Defender for Cloud/
├── 1-defender-for-servers-part1.md  # Hands-on: Enable plan, Arc agent health, Secure Score, Recommendations
├── 1-defender-for-servers-part2.md  # Hands-on: Vulnerability assessment, FIM, alerts, MDE integration
└── 2-jit.md                         # Hands-on: JIT VM access + Azure Bastion zero-standing-access pattern
```

## Lab Sequence

Complete these in order — Lab 2 (JIT) depends on the Defender for Servers plan being active on the subscription, which Lab 1 (Parts 1 and 2) enables.

1. [Microsoft Defender for Servers, Part 1 — Setup and Security Posture](1-defender-for-servers-part1.md) — verify Arc agent health, enable Defender for Servers Plan 2, and review Secure Score and Recommendations (including diagnosing "Not evaluated" status and scaling recommendations across a large fleet)

2. [Microsoft Defender for Servers, Part 2 — Vulnerability Assessment, FIM, Alerts & MDE Integration](1-defender-for-servers-part2.md) — run vulnerability assessment, enable File Integrity Monitoring, investigate a test security alert, and confirm Defender for Endpoint / Guest Configuration extension integration

3. [Bastion + Just-In-Time (JIT) VM Access](2-jit.md) — configure JIT access via Microsoft Defender for Cloud, request time-bounded port openings, connect through Azure Bastion, and validate NSG rule auto-removal

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- Azure Bastion deployed (for Lab 3, JIT) — complete the [Azure Bastion track](../Azure%20Bastion/README.md) first
- At least one running Azure VM or Arc-enabled server, with a **Connected** Arc agent status (verified in Lab 1, Part 1, Step 1.0)
- For Arc coverage: complete the [Azure Arc Hybrid Server Architecture track](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) first

## Related Tracks

| Track | Relationship |
| --- | --- |
| [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) | Arc-enabled servers are onboarded to Defender for Cloud in Section 6 of the Arc Architecture guide |
| [Azure Update Manager](../Azure%20Update%20Manager/README.md) | Defender for Servers surfaces missing patch recommendations; Update Manager remediates them |
| [Azure Bastion](../Azure%20Bastion/README.md) | Required dependency for JIT lab — Bastion provides the browser-based session after JIT opens the port |

---

[← Back to Azure Hands-On Engineering](../README.md)
