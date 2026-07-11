# Azure Update Manager Track

Last validated on: 2026-07-10

This track covers OS patch orchestration for Azure VMs and Arc-enabled servers using **Azure Update Manager** — the successor to the legacy Log Analytics Update Management solution. Labs walk through patch assessment, maintenance window scheduling, update deployments, and compliance reporting, all via the Azure Portal.

> **Relationship to other tracks:** Azure Update Manager works across both native Azure VMs and Arc-enabled hybrid servers. If you're managing Arc-enabled servers, complete the [Azure Arc Hybrid Server Architecture track](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) first so your servers are already onboarded and visible in Azure Resource Manager.

## Key Concepts

| Concept | Description |
| --- | --- |
| **Azure Update Manager** | Native Azure service for assessing and deploying OS updates across Azure VMs and Arc-enabled servers |
| **Patch Assessment** | On-demand or scheduled scan that surfaces which updates are available without deploying them |
| **Periodic Assessment** | Automatic 24-hour re-assessment (per-machine or via Azure Policy at scale) that keeps compliance data current without manual "Check for updates" runs |
| **Maintenance Window** | Defined time window during which updates are permitted — keeps patching predictable and change-controlled |
| **Update Deployment** | Orchestrated installation run scoped by machine, schedule, and update classification |
| **Hotpatching** | Reboot-free security patching for eligible Arc-enabled Windows Server 2025 machines — reduces routine reboots from monthly to quarterly |
| **Compliance Report** | Rollup view of patch state across your fleet — surfaces machines that are overdue for patching |
| **Dynamic Scope** | Target machines by subscription, resource group, or tag rather than a static list — fleet membership stays accurate automatically |

## Track Structure

```text
Azure Update Manager/
├── README.md
├── 1-Azure Update Manager.md          # Hands-on lab: enable Update Manager, assessment, maintenance window, deployment, compliance
├── 2-Azure Update Advance Topics.md   # Advanced topics: pre/post scripts, rollback, KQL, CVE mapping, ESU, Bicep IaC
├── 3-operational-workflow.md          # Hybrid fleet pipeline, tagging, maintenance window design, hotpatching, pricing, monthly review
└── 4-operational-runbooks.md          # Runbooks: monitor patch runs, log validation, prod/non-prod strategy, alerting, config reference
```

## Lab Sequence

1. [Azure Update Manager — Patch Orchestration for Azure and Arc Servers](1-Azure%20Update%20Manager.md) — enable Update Manager, enable periodic assessment and run an on-demand patch assessment, configure a maintenance window, schedule and execute an update deployment, and review the compliance dashboard
2. [Azure Update Manager — Advanced Topics](2-Azure%20Update%20Advance%20Topics.md) — pre/post maintenance scripts, rollback procedures, patch exemptions, compliance workbooks, advanced KQL queries, CVE-to-KB mapping, zero-day response, patch SLA policy, DC staggered reboot runbook, Windows Server 2012 R2 ESU, and Bicep IaC for maintenance configurations
3. [Operational Workflow for Hybrid Fleets](3-operational-workflow.md) — Arc → Defender for Servers → Update Manager pipeline setup, patch group tagging strategy, maintenance window design, hotpatching, pricing and licensing, the staged/ring-based patching limitation, and the monthly patch review workflow
4. [Operational Runbooks](4-operational-runbooks.md) — monitoring a live patch run, post-run log validation, prod vs non-prod patching strategy, Arc agent disconnect alerting, the standardized maintenance configuration template, and the full option-by-option maintenance configuration reference

## Prerequisites

- Azure subscription with **Contributor** rights on the target resource group
- At least one running Azure VM **or** Arc-enabled server (see [Azure Arc track](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md))
- No legacy Update Management solution (Log Analytics-based) active on the same machines — the two conflict; migrate first if applicable

> **Note:** Update Manager does not natively enforce staged/ring-based rollout (test → pre-prod → prod using only the exact patch versions validated earlier). If that guarantee matters for your environment, see the staged-patching workaround and caveat in [Operational Workflow for Hybrid Fleets](3-operational-workflow.md#staged--ring-based-patching-known-limitation).

## Related Tracks

| Track | Relationship |
| --- | --- |
| [Azure Arc Hybrid Server Architecture](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) | Arc-enabled servers are a primary target for Update Manager; onboard servers there first |
| [Microsoft Defender for Cloud](../Microsoft%20Defender%20for%20Cloud/README.md) | Defender for Servers surfaces missing patch recommendations that Update Manager then remediates |
| [Compute](../Compute/README.md) | Baseline VM build — native Azure VMs managed by Update Manager |

---

## Update Log

### 2026-07-10 revision (this file)

- Aligned "Last validated on" precision (`July 2026` → `2026-07-10`) to match both linked docs.
- Added **Periodic Assessment** and **Hotpatching** to the Key Concepts table — both became first-class concepts in the Lab guide after its content refresh and weren't represented here.
- Expanded the Lab Sequence description for doc 1 to mention periodic assessment, hotpatching, and Arc-enabled server pricing.
- Added a Prerequisites callout noting that staged/ring-based rollout is not natively enforced by Update Manager, cross-referencing the caveat and workaround now documented in both linked guides.
- No changes to Track Structure, doc 2's Lab Sequence description, or Related Tracks — verified these still accurately reflect the current content.

### 2026-07-11 revision (this file)

- **Updated Track Structure and Lab Sequence** to include `3-operational-workflow.md` and `4-operational-runbooks.md`, which were missing entirely — the track had been split into 4 files, but this README was never updated past the original 2-file structure.
- Narrowed doc 1's Lab Sequence description back to its actual current scope (Part 1 lab only) now that hybrid-fleet pipeline/hotpatching/pricing content has moved to doc 3.
- **Fixed a broken cross-file link**: the staged/ring-based patching note pointed to `1-Azure Update Manager.md#staged--ring-based-patching-known-limitation`, but that section was relocated to `3-operational-workflow.md` during the 4-file split and the reference was never updated. Repointed to the correct file and anchor.
- Verified via automated link-and-anchor audit across all 4 track documents plus this README: all internal anchors and cross-file references now resolve correctly (2 broken anchors found and fixed here and in doc 2; see doc 2's own Update Log for its fix).

---

[← Back to Azure Hands-On Engineering](../README.md)
