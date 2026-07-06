# Azure Update Manager Track

Last validated on: July 2026

This track covers OS patch orchestration for Azure VMs and Arc-enabled servers using **Azure Update Manager** — the successor to the legacy Log Analytics Update Management solution. Labs walk through patch assessment, maintenance window scheduling, update deployments, and compliance reporting, all via the Azure Portal.

> **Relationship to other tracks:** Azure Update Manager works across both native Azure VMs and Arc-enabled hybrid servers. If you're managing Arc-enabled servers, complete the [Azure Arc Hybrid Server Architecture track](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) first so your servers are already onboarded and visible in Azure Resource Manager.

## Key Concepts

| Concept | Description |
| --- | --- |
| **Azure Update Manager** | Native Azure service for assessing and deploying OS updates across Azure VMs and Arc-enabled servers |
| **Patch Assessment** | On-demand or scheduled scan that surfaces which updates are available without deploying them |
| **Maintenance Window** | Defined time window during which updates are permitted — keeps patching predictable and change-controlled |
| **Update Deployment** | Orchestrated installation run scoped by machine, schedule, and update classification |
| **Compliance Report** | Rollup view of patch state across your fleet — surfaces machines that are overdue for patching |
| **Dynamic Scope** | Target machines by subscription, resource group, or tag rather than a static list — fleet membership stays accurate automatically |

## Track Structure

```text
Azure Update Manager/
└── 1-Azure Update Manager.md   # Hands-on lab: assessment, scheduling, deployment, and compliance
```

## Lab Sequence

1. [Azure Update Manager — Patch Orchestration for Azure and Arc Servers](1-Azure%20Update%20Manager.md) — enable Update Manager, run on-demand patch assessment, configure a maintenance window, schedule and execute an update deployment, and review the compliance dashboard

## Prerequisites

- Azure subscription with **Contributor** rights on the target resource group
- At least one running Azure VM **or** Arc-enabled server (see [Azure Arc track](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md))
- No legacy Update Management solution (Log Analytics-based) active on the same machines — the two conflict; migrate first if applicable

## Related Tracks

| Track | Relationship |
| --- | --- |
| [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) | Arc-enabled servers are a primary target for Update Manager; onboard servers there first |
| [Microsoft Defender for Cloud](../Microsoft%20Defender%20for%20Cloud/README.md) | Defender for Servers surfaces missing patch recommendations that Update Manager then remediates |
| [Compute](../Compute/README.md) | Baseline VM build — native Azure VMs managed by Update Manager |

---

[← Back to Azure Hands-On Engineering](../README.md)
