# Microsoft Defender for Cloud Track

This track covers workload protection and secure access controls using Microsoft Defender for Cloud — enabling Just-In-Time VM access, managing security recommendations, and integrating with Azure Bastion for zero-standing-access VM connectivity.

## Track Structure

```text
Microsoft Defender for Cloud/
`-- 1-JIT.md
```

## Lab Sequence

1. [Bastion + Just-In-Time (JIT) VM Access](1-JIT.md) — configure JIT access via Microsoft Defender for Cloud, request time-bounded port openings, connect through Azure Bastion, and validate NSG rule auto-removal

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- Azure Bastion deployed — complete the [Azure Bastion track](../Azure%20Bastion/README.md) first
- Microsoft Defender for Cloud enabled with the **Defender for Servers** plan active on the subscription
- The requesting user must have **Security Reader** + **Virtual Machine Contributor** roles on the target VM

## Key Concepts Covered

| Concept | Description |
| --- | --- |
| Just-In-Time (JIT) VM Access | Time-boxed NSG rule opening — no standing inbound access between sessions |
| Defender for Servers | Prerequisite plan that enables JIT on VMs |
| NSG Auto-Remediation | JIT rules are automatically removed when the time window expires |
| Bastion + JIT Pattern | JIT controls *when* the port is open; Bastion controls *how* you connect |

---

[← Back to Azure Hands-On Engineering](../README.md)