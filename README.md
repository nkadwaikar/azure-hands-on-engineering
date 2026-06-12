# 👋 Hi, I'm Nadeem Kadwaikar

# 👋 Hi, I'm Nadeem Kadwaikar

*Cloud Engineer - Azure Infrastructure, Identity, and Microsoft 365*

![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Bicep](https://img.shields.io/badge/Bicep-success?style=flat)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)
![Entra ID](https://img.shields.io/badge/Entra%20ID-0078D4?style=flat&logo=microsoftazure&logoColor=white)


I build secure, identity-first Azure platforms...
I build secure, identity-first Azure platforms for regulated environments using infrastructure as code and practical governance.

## 💡 Engineering Philosophy

I keep cloud engineering clear, repeatable, and secure by default. Every lab follows three principles: **clarity**, **repeatability**, and **secure defaults**.

---

## 🎯 Core Skills

| Area | What I Do |
|---|---|
| **Azure Infrastructure** | VMs, VMSS, VNets, NSGs, Load Balancers, Front Door, Storage - built for resilience |
| **Identity & Zero Trust** | Microsoft Entra ID, RBAC, Conditional Access, Managed Identities, Key Vault |
| **IaC & Automation** | Modular Bicep deployments, GitHub Actions, PowerShell, Azure CLI |
| **Governance & Compliance** | Azure Policy, Resource Locks, Activity Logs, Monitor - aligned to regulated environments |
| **Microsoft 365** | Tenant admin, users & groups, security & compliance, endpoint basics |
| **Business Continuity** | Azure Backup, Site Recovery, VMSS failover patterns |

---

## 🎖️ Azure-Focused Certifications

| Certification | Focus |
|---|---|
| **SC-300** | Microsoft Identity and Access Administrator |
| **SC-400** | Microsoft Information Protection Administrator |

---

## Naming Convention

Use these patterns across labs to keep resource names predictable and avoid drift.

| Resource Type | Pattern | Example |
|---|---|---|
| Resource Group | `rg-<workload>-<region>-<env>-<purpose>` | `rg-fntech-asr-lab-eus-core` |
| VM | `vm-<workload>-<region>-<role><nn>` | `vm-fntech-asr-lab-eus-app01` |
| Recovery Services Vault | `rsv-<workload>-<region>-<purpose>` | `rsv-fntech-asr-lab-eus-dr` |
| Storage Account | `st<workload><purpose><nn>` | `streplicationlab01` |
| VNet | `vnet-<workload>-<region>-<purpose>` | `vnet-fntech-asr-lab-wus2-dr` |
| NSG | `nsg-<workload>-<region>-<scope>` | `nsg-asr-dr-vm` |
| Public IP | `pip-<workload>-<region>-<target>` | `pip-asr-dr-vm` |

Naming notes:
- Keep names lowercase where required by Azure service rules.
- Use short region codes consistently (`eus`, `wus2`, `weu`).
- Keep `lab` in names for non-production resources.

---

## 📌 Practical Labs

These labs reflect real Azure engineering patterns. They are production-aligned implementations with the reasoning documented, not step-by-step tutorials.

### 1. Azure Infrastructure as Code (IaC)
- [Identity-First Bicep Capstone Lab](Identity-First/07-bicep-deployment-identity-stack.md) - Modular Bicep stack: Managed Identity + Key Vault + RBAC + Governance Lock
- [VS Code Bicep Deployment Workflow](Identity-First/vscode-deployment-workflow.md)

Next recommended lab: [Identity Fundamentals](Identity-First/01-identity%20fundamentals.md)

### 2. Identity-First Security & Zero Trust
- [Identity Fundamentals](Identity-First/01-identity%20fundamentals.md) - Entra ID core concepts, tenant structure, and authentication flows
- [Managed Identity + Key Vault](Identity-First/02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md) - Secretless authentication to reduce credential sprawl
- [Azure AD Roles & RBAC](Identity-First/03-azuread-roles-rbac-scopes.md) - Least-privilege role assignments across scopes
- [Access Validation](Identity-First/05-access-validation.md) - Portal and CLI-based access verification

Next recommended lab: [Azure Front Door Static Website Hosting](Azure%20Front%20Door-Static%20Website%20Hosting/Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md)

### 3. Cloud Networking & Global Delivery
- [Azure Front Door Static Website Hosting](Azure%20Front%20Door-Static%20Website%20Hosting/Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md) - Global CDN routing with custom origins

Next recommended lab: [Build Base VM](Compute/1-build-base-vm.md)

### 4. Image Lifecycle & Automation
- [Build Base VM](Compute/1-build-base-vm.md)
- [Sysprep Azure VM](Compute/2-sysprep-vm.md)
- [Capture & Test Image](VMSS/1-capture-and-test-image.md)
- [VMSS Deployment](VMSS/2-vmss-deployment.md) - Auto-scaling VM fleet from a golden image

Next recommended lab: [Azure Monitor & Activity Logs](Identity-First/06-azuremonitor-activity-logs.md)

### 5. Monitoring, Compliance & Governance
- [Azure Monitor & Activity Logs](Identity-First/06-azuremonitor-activity-logs.md) - Audit trail and alerting for security events
- [Azure Locks & Resource Policies](Identity-First/04-azurelocks-resource-policies.md) - Prevent accidental deletion and enforce tagging and SKU constraints
- [Azure Policy Auto-Remediation](Azure%20Policy%20Auto%E2%80%91Remediation/Azure%20Policy%20Auto%E2%80%91Remediation.md) - DINE policy with managed identity and auto-remediation pipelines
- [Governance Flow Diagram](Identity-First/governance-flow.md)

Next recommended lab: [Azure VM Backup](Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md)

### 6. Business Continuity & Resilience
- [Azure VM Backup](Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md) - RPO/RTO-aware backup configuration
- [Azure Site Recovery](Recovery%20Services%20vaults/2-Azure%20Site%20Recovery.md) - Cross-region failover for business continuity
- [Azure Storage Replication](Recovery%20Services%20vaults/3-Azure%20storage%20replication.md) - Compare LRS/ZRS/GRS/GZRS and validate read-access geo-replication

Next recommended lab: [Identity-First Bicep Capstone Lab](Identity-First/07-bicep-deployment-identity-stack.md)

Recommended lab order:
1. [Azure VM Backup](Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md)
2. [Azure Site Recovery](Recovery%20Services%20vaults/2-Azure%20Site%20Recovery.md)
3. [Azure Storage Replication](Recovery%20Services%20vaults/3-Azure%20storage%20replication.md)

---

## 🛠️ Currently Building

- Azure App Services (deployment slots, scaling, managed identity integration)
- Defender for Cloud - CSPM + Plans with Hub-and-Spoke topology
- Azure Arc Onboarding (hybrid server management)

---

*Last updated: June 2026 - Built with strong collaboration and a focus on clean, maintainable engineering.*

💼 [LinkedIn](https://linkedin.com/in/nadeemkadwaikar) · 📧 nadeemkadwaikar@outlook.com