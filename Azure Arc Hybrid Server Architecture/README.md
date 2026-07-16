# Azure Arc Hybrid Server Architecture Track

> **Last validated:** July 2026 — Azure Portal UI; agent installation steps apply to Windows Server and supported Linux distributions.

This track covers designing and operating a hybrid server landing zone using **Azure Arc** as the projection layer and **Microsoft Defender for Cloud** as the security brain — onboarding non-Azure servers (on-prem, VMware, AWS, GCP) into Azure Resource Manager for unified policy, monitoring, patching, and security.

> **Why Azure Arc?** Managing on-premises and multi-cloud servers without Arc means separate toolchains for policy, patching, monitoring, and security. Arc projects every server into Azure Resource Manager so the same governance stack applies everywhere — with Defender for Servers as the security layer and a single pane of glass across environments.

## Key Concepts

| Concept | Description |
| --- | --- |
| **Connected Machine Agent (CMA)** | Lightweight agent installed on each non-Azure server; establishes the outbound HTTPS channel to ARM |
| **Azure Arc projection** | Non-Azure servers appear as first-class ARM resources with resource IDs, tags, RBAC, and Policy |
| **Azure Monitor Agent (AMA) + DCR** | Replaces the legacy MMA; collects logs/metrics and streams them to Log Analytics via Data Collection Rules |
| **Update Manager** | Native Azure service for OS patch orchestration across Arc-enabled servers |
| **Defender for Servers** | Provides threat detection, vulnerability assessment, JIT access, and File Integrity Monitoring for Arc machines |
| **Guest Configuration** | Audits and enforces OS-level settings (DSC/Chef InSpec baselines) through Arc |

## Track Structure

```text
Azure Arc Hybrid Server Architecture/
├── 1-Azure Arc Hybrid Server Architecture.md   # Architecture reference & production design guide
└── 2-On-Prem Hyper-V Lab Setup for Azure Arc.md  # Disposable environment to validate onboarding flow
```

## Guide Sequence

> **Recommended order:** Complete Guide 1 (architecture + design decisions) before Guide 2. The Hyper-V environment in Guide 2 validates every design choice documented in Guide 1.

1. [Azure Arc Hybrid Server Architecture](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) — *Estimated effort: 3–4 hours* (Guide 1)

   | Section | What It Covers |
   | --- | --- |
   | 0. Prerequisites | Required RBAC roles, supported OS matrix, server requirements, resource provider registration, and Azure resources to pre-create |
   | 1. High-Level Architecture | Core components: Arc, Log Analytics, AMA, Update Manager, Policy, Defender |
   | 2. Resource Organization & Governance | Subscription layout, mandatory tagging strategy, RBAC model, management group hierarchy |
   | 3. Connectivity & Agent Architecture | Connected Machine Agent (CMA), outbound endpoint table, private link/proxy options, agent health & extension management, single-server onboarding (Windows + Linux), onboarding verification |
   | 4. Monitoring & Operations | AMA + DCR pipeline, Update Manager, KQL workbooks, alerting rules, log retention and archival policy |
   | 5. Policy, Configuration & Compliance | Arc-enabled server policy initiatives, Guest Configuration baselines, exemption management, drift detection |
   | 6. Security Architecture | Defender for Servers integration, security data flow, Secure Score, Zero Trust alignment, JIT access, File Integrity Monitoring, Defender plan cost management |
   | 7. Automation & Lifecycle Management | Automation runbooks, at-scale onboarding, runbook version control and CI/CD, break-glass procedure, decommissioning |
   | Check List | End-to-end rollout checklist covering prerequisites through decommissioning validation |

2. [On-Prem Hyper-V Lab Setup for Azure Arc](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) — *Estimated effort: 2–3 hours* (Guide 2)

   > **Why Hyper-V, not Azure VMs?** Azure VMs are already native ARM resources and never go through the CMA onboarding flow. A Hyper-V environment gives you disposable "on-prem" machines that Arc does not already know about — the only way to exercise real onboarding.

   | Step | What It Covers |
   | --- | --- |
   | Why This Approach | Why Hyper-V VMs (not Azure VMs) are required to exercise real Arc onboarding |
   | 1. Hyper-V Host Prerequisites | Host OS, Hyper-V role enablement, BIOS/UEFI virtualisation, sizing guidance |
   | 1a. Optional VMs | Decision guide for Domain Controller (GPO onboarding) and File Server (FIM testing) |
   | 2. Networking | External vs. Internal + NAT virtual switch; inserting a proxy to simulate restricted on-prem |
   | 3. Create VMs | Windows Server 2022 + Linux, Generation 2, Arc-ready hostname conventions, connectivity check |
   | 4. Azure Side (Isolated Scope) | `rg-arc-lab`, optional `law-arc-lab`, resource provider registration, lab-specific tags |
   | 5. Onboard VMs | Single-server onboarding script from portal, targeting `rg-arc-lab` |
   | 6. Verify | Connected status, tags, AMA extension, Defender for Cloud inventory checks |
   | 7. Governance End-to-End | Environment-scoped RBAC, policy initiative assignment, Automation account wiring, Defender for Servers |
   | 8. What to Actually Test | Checklist of architecture components to validate: tagging, AMA, Defender, FIM, proxy, RBAC, runbooks |
   | 9. Teardown | Portal-based Arc resource deletion, CMA uninstall, RBAC/policy cleanup, resource group removal |
   | Notes | Isolation principle (scope not copies), bulk onboarding in this environment, VM snapshot strategy |

## Prerequisites

### Azure-Side Requirements

- Azure subscription with **Owner** or **Contributor** rights on the platform subscription
- `Azure Connected Machine Onboarding` role to register Arc machines
- `Azure Connected Machine Resource Administrator` role to manage Arc machine resources
- Resource providers registered: `Microsoft.HybridCompute`, `Microsoft.GuestConfiguration`, `Microsoft.HybridConnectivity`
- Log Analytics Workspace and Automation Account pre-created in the platform resource group
- Defender for Cloud with **Servers plan** enabled at the subscription level

### Server Requirements

- Outbound HTTPS (port 443) from target servers to Azure endpoints — no inbound access required
- 200 MB free disk space on the target server
- PowerShell 4.0+ (Windows) or `systemd` (Linux)
- TLS 1.2 or later
- Supported OS: Windows Server 2008 R2 SP1+; Linux: RHEL 7+, SLES 12+, Ubuntu 16.04+, Debian 9+, Amazon Linux 2

### For the Hyper-V Environment (Guide 2)

- Windows host with Hyper-V role enabled (Intel VT-x / AMD-V in BIOS)
- ~2 vCPU / 4–8 GB RAM / 60 GB disk per VM
- Host outbound internet access (VMs inherit via virtual switch)
- Windows Server 2022 Evaluation ISO and/or Ubuntu Server ISO

---

## Related Tracks

This track covers the Arc projection and governance layer. The security and patching capabilities referenced in the Arc Architecture guide (Sections 4.2 and 6) each have their own dedicated track:

| Track | What it covers | Arc Architecture doc reference |
| --- | --- | --- |
| [Defender for Servers](../Defender%20for%20Servers/README.md) | Enable Defender for Servers Plan 2, Secure Score, vulnerability assessment, FIM, alerts | Section 6 — Security Architecture |
| [Bastion + JIT VM Access](../Defender%20for%20Servers/2-JIT.md) | Time-bounded NSG port openings via Defender for Cloud | Section 6.5 — JIT Admin Access |
| [Azure Update Manager](../Azure%20Update%20Manager/README.md) | Patch assessment, maintenance windows, update deployments, compliance reporting | Section 4.2 — Update Management |
| [Identity-First Track](../Identity-First/README.md) | RBAC and managed identity patterns referenced in the Arc governance model | Section 2.3 — RBAC Model |

- [Back to Azure Hands-On Engineering](../README.md)
