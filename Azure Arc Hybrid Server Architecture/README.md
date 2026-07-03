# Azure Arc Hybrid Server Architecture Track

This track covers designing and operating a hybrid server landing zone using **Azure Arc** as the projection layer and **Microsoft Defender for Cloud** as the security brain — onboarding non-Azure servers (on-prem, VMware, AWS, GCP) into Azure Resource Manager for unified policy, monitoring, patching, and security.

## Track Structure

```text
Azure Arc Hybrid Server Architecture/
├── 1-Azure Arc Hybrid Server Architecture.md
└── 2-On-Prem Hyper-V Lab Setup for Azure Arc.md
```

## Lab Sequence

1. [Azure Arc Hybrid Server Architecture](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md)

   | Section | What It Covers |
   | --- | --- |
   | 0. Prerequisites | Required RBAC roles, supported OS matrix, server requirements, resource provider registration, and Azure resources to pre-create |
   | 1. High-Level Architecture | Core components: Arc, Log Analytics, AMA, Update Manager, Policy, Defender, Sentinel |
   | 2. Resource Organization & Governance | Subscription layout, mandatory tagging strategy, RBAC model, management group hierarchy |
   | 3. Connectivity & Agent Architecture | Connected Machine Agent (CMA), outbound endpoint table, private link/proxy options, agent health & extension management, single-server onboarding (Windows + Linux), onboarding verification |
   | 4. Monitoring & Operations | AMA + DCR pipeline, Update Manager, KQL workbooks, alerting rules, log retention and archival policy |
   | 5. Policy, Configuration & Compliance | Arc-enabled server policy initiatives, Guest Configuration baselines, exemption management, drift detection |
   | 6. Security Architecture | Defender for Servers integration, security data flow, Secure Score, Zero Trust alignment, JIT access, File Integrity Monitoring, Defender plan cost management |
   | 7. Automation & Lifecycle Management | Automation runbooks, at-scale onboarding, runbook version control and CI/CD, break-glass procedure, decommissioning |
   | Check List | End-to-end rollout checklist covering prerequisites through decommissioning validation |

2. [On-Prem Hyper-V Lab Setup for Azure Arc](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md)

   | Step | What It Covers |
   | --- | --- |
   | Why a Lab | Why Hyper-V VMs (not Azure VMs) are required to exercise real Arc onboarding |
   | 1. Hyper-V Host Prerequisites | Host OS, Hyper-V role enablement, BIOS/UEFI virtualisation, sizing guidance |
   | 1a. Optional VMs | Decision guide for Domain Controller (GPO onboarding) and File Server (FIM testing) |
   | 2. Networking | External vs. Internal + NAT virtual switch; inserting a proxy to simulate restricted on-prem |
   | 3. Create Lab VMs | Windows Server 2022 + Linux, Generation 2, Arc-ready hostname conventions, connectivity check |
   | 4. Azure Side (Isolated Scope) | `rg-arc-lab`, optional `law-arc-lab`, resource provider registration, lab-specific tags |
   | 5. Onboard Lab VMs | Single-server onboarding script from portal, targeting `rg-arc-lab` |
   | 6. Verify | Connected status, tags, AMA extension, Defender for Cloud inventory checks |
   | 7. Governance End-to-End | Lab-scoped RBAC, policy initiative assignment, Automation account wiring, Defender for Servers |
   | 8. What to Actually Test | Checklist of architecture components to validate: tagging, AMA, Defender, FIM, proxy, RBAC, runbooks |
   | 9. Teardown | Portal-based Arc resource deletion, CMA uninstall, RBAC/policy cleanup, resource group removal |
   | Notes | Isolation principle (scope not copies), bulk onboarding in the lab, VM snapshot strategy |

## Prerequisites

- Azure subscription with **Owner** or **Contributor** rights on the platform subscription
- `Azure Connected Machine Onboarding` role to register Arc machines
- Outbound HTTPS (port 443) connectivity from servers to Azure endpoints
- Windows Server 2008 R2 SP1+ or a supported Linux distribution (RHEL 7+, Ubuntu 16.04+, etc.)
- Azure Portal access and Azure CLI or PowerShell (Az module) installed
- Log Analytics Workspace and Automation Account pre-created in the platform resource group

---

## Related

- [1 — Azure Arc Hybrid Server Architecture](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) — architecture reference and production design guide
- [2 — On-Prem Hyper-V Lab Setup for Azure Arc](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) — disposable lab to validate onboarding before production
- [Back to Azure Hands-On Engineering](../README.md)
