# Azure Arc Hybrid Server Architecture Track

This track covers designing and operating a hybrid server landing zone using **Azure Arc** as the projection layer and **Microsoft Defender for Cloud** as the security brain — onboarding non-Azure servers (on-prem, VMware, AWS, GCP) into Azure Resource Manager for unified policy, monitoring, patching, and security.

## Track Structure

```text
Azure Arc Hybrid Server Architecture/
`-- Azure Arc Hybrid Server Architecture.md
```

## Lab Sequence

1. [Azure Arc Hybrid Server Architecture](Azure%20Arc%20Hybrid%20Server%20Architecture.md)

   | Section | What It Covers |
   | --- | --- |
   | 0. Prerequisites | Required RBAC roles, supported OS matrix, server requirements, and Azure resources to pre-create |
   | 1. High-Level Architecture | Core components: Arc, Log Analytics, AMA, Update Manager, Policy, Defender, Sentinel |
   | 2. Resource Organization & Governance | Subscription layout, mandatory tagging strategy, RBAC model, management group hierarchy |
   | 3. Connectivity & Agent Architecture | Connected Machine Agent (CMA), outbound endpoint table, private link/proxy options, extension management, agent installation (Windows + Linux), onboarding verification |
   | 4. Monitoring & Operations | AMA + DCR pipeline, Update Manager, KQL workbooks, alerting rules, log retention and archival policy |
   | 5. Policy, Configuration & Compliance | Arc-enabled server policy initiatives, Guest Configuration baselines, exemption management, drift detection |
   | 6. Security Architecture | Defender for Servers integration, security data flow, Secure Score, Zero Trust alignment, JIT access, File Integrity Monitoring, Defender plan cost management |
   | 7. Automation & Lifecycle Management | Automation runbooks, at-scale onboarding, runbook version control and CI/CD, decommissioning, break-glass procedure |
   | 8. Rollout Model | Four-phase rollout (Foundation → Pilot → Scale-Out → Optimization) with success criteria and sign-off owners |
   | Next Steps | Prioritised action checklist |

## Prerequisites

- Azure subscription with **Owner** or **Contributor** rights on the platform subscription
- `Azure Connected Machine Onboarding` role to register Arc machines
- Outbound HTTPS (port 443) connectivity from servers to Azure endpoints
- Windows Server 2008 R2 SP1+ or a supported Linux distribution (RHEL 7+, Ubuntu 16.04+, etc.)
- Azure Portal access and Azure CLI or PowerShell (Az module) installed
- Log Analytics Workspace and Automation Account pre-created in the platform resource group

---

[← Back to Azure Hands-On Engineering](../README.md)
