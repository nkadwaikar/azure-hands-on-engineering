# 👋 Hi, I'm Nadeem Kadwaikar

*Cloud Engineer — Azure Infrastructure, Identity, and Microsoft 365*

![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Bicep](https://img.shields.io/badge/Bicep-success?style=flat)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)
![Entra ID](https://img.shields.io/badge/Entra%20ID-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)


I build secure, identity-first Azure platforms for regulated environments using infrastructure as code and practical governance.

## 💡 Engineering Philosophy

I keep cloud engineering clear, repeatable, and secure by default. Every lab follows three principles: **clarity**, **repeatability**, and **secure defaults**.

---

## 🎯 Core Skills

| Area | What I Do |
|---|---|
| **Azure Infrastructure** | VMs, VMSS, VNets, NSGs, Load Balancers, Front Door, Storage — built for resilience |
| **Identity & Zero Trust** | Microsoft Entra ID, RBAC, Conditional Access, Managed Identities, Key Vault |
| **IaC & Automation** | Modular Bicep deployments, GitHub Actions, PowerShell, Azure CLI |
| **Governance & Compliance** | Azure Policy, Resource Locks, Activity Logs, Monitor — aligned to regulated environments |
| **Microsoft 365** | Tenant admin, users & groups, security & compliance, endpoint basics |
| **Business Continuity** | Azure Backup, Site Recovery, VMSS failover patterns |

---

## 🎖️ Certifications

| Certification | Focus |
|---|---|
| **SC-300** | Microsoft Identity and Access Administrator |
| **SC-400** | Microsoft Information Protection Administrator |
| **PMP** | Project Management Professional |
| **PRINCE2 Agile** | Agile Project Delivery |
| **ITIL** | IT Service Management |
| **SAFe PO/PM** | Scaled Agile |
| **PSM I / CSM** | Scrum |
| **VCP-DCV** | VMware Virtualisation |

---

## Naming Convention

Use these standards across labs to keep names predictable, searchable, and automation-friendly.

Token legend:
- `workload`: short solution/system name (`fntech`, `identity`, `web`).
- `region`: short Azure region code (`eus`, `wus2`, `weu`).
- `env`: environment marker (`lab`, `dev`, `tst`, `prd`).
- `purpose` / `role`: concise function (`core`, `dr`, `app`, `kv`).
- `nn`: 2-digit sequence (`01`, `02`).

| Resource Type | Pattern | Example |
|---|---|---|
| Resource Group | `rg-<workload>-<region>-<env>-<purpose>` | `rg-fntech-eus-lab-core` |
| Virtual Machine | `vm-<workload>-<region>-<env>-<role><nn>` | `vm-fntech-eus-lab-app01` |
| User Assigned Managed Identity | `uami-<workload>-<region>-<env>-<purpose>` | `uami-identity-eus-lab-deploy` |
| Key Vault | `kv-<workload>-<region>-<env>-<purpose>` | `kv-identity-eus-lab-core` |
| Recovery Services Vault | `rsv-<workload>-<region>-<env>-<purpose>` | `rsv-fntech-eus-lab-dr` |
| VNet | `vnet-<workload>-<region>-<env>-<purpose>` | `vnet-fntech-wus2-lab-dr` |
| NSG | `nsg-<workload>-<region>-<env>-<scope>` | `nsg-fntech-wus2-lab-vm` |
| Public IP | `pip-<workload>-<region>-<env>-<target>` | `pip-fntech-wus2-lab-vm` |
| Storage Account* | `st<workload><env><purpose><nn>` | `stidentitylabdiag01` |

*Storage account names must be 3-24 chars, lowercase letters/numbers only, and no hyphens.

Naming rules:
- Keep all names lowercase unless an Azure resource explicitly allows and requires otherwise.
- Keep region codes and environment tokens consistent across all labs.
- Use `lab` for non-production exercises; reserve `prd` for production examples.
- Prefer short, stable tokens so scripts and Bicep parameters remain reusable.

---

## 📌 Practical Labs

These labs reflect real Azure engineering patterns. Each includes a documented walkthrough and, where applicable, Bicep templates or scripts for reproducibility.

Who this is for: **Beginner to Intermediate** cloud engineers, and **Advanced** practitioners who want reusable identity-first governance patterns.

### 1. Identity-First Security & Zero Trust (Foundation)
Outcome: Build a secure Entra identity baseline with least-privilege RBAC, phishing-resistant emergency access, and validated access controls.

- [Identity Fundamentals](Identity-First/01-identity%20fundamentals.md) - Understand Entra ID core concepts, tenant structure, and authentication flows
- [Microsoft Entra Break‑Glass & Emergency Access Accounts](Secure%20Break%E2%80%91Glass%20Accounts/1-Secure%20Break%E2%80%91Glass%20Accounts.md) - Implement cloud-only emergency accounts with phishing-resistant MFA and Conditional Access
- [Managed Identity + Key Vault](Identity-First/02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md) - Implement secretless authentication to reduce credential sprawl
- [Microsoft Entra Roles & RBAC](Identity-First/03-azuread-roles-rbac-scopes.md) - Apply least-privilege role assignments across scopes
- [Access Validation](Identity-First/05-access-validation.md) - Validate access using portal and CLI-based checks

Next recommended lab: [Identity-First Bicep Capstone Lab](Identity-First/07-bicep-deployment-identity-stack.md)

### 2. Azure Infrastructure as Code (IaC) & Automation
Outcome: Deploy modular, repeatable Azure infrastructure with identity-first controls using Bicep and a VS Code workflow.

- [Identity-First Bicep Capstone Lab](Identity-First/07-bicep-deployment-identity-stack.md) - Build a modular Bicep stack: Managed Identity + Key Vault + RBAC + Governance Lock
- [VS Code Bicep Deployment Workflow](Identity-First/vscode-deployment-workflow.md) - Deploy Bicep from VS Code with a portal-free workflow

Next recommended lab: [Azure Front Door Static Website Hosting](Azure%20Front%20Door-Static%20Website%20Hosting/Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md)

### 3. Cloud Networking & Global Delivery
Outcome: Publish globally distributed workloads with Front Door and resilient edge routing patterns.

- [Azure Front Door Static Website Hosting](Azure%20Front%20Door-Static%20Website%20Hosting/Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md) - Configure global CDN routing with custom origins

Next recommended lab: [Build Base VM](Compute/1-build-base-vm.md)

### 4. Image Lifecycle & Compute Automation
Outcome: Build, generalize, validate, and scale golden images for consistent compute deployment.

- [Build Base VM](Compute/1-build-base-vm.md) - Create a baseline VM for reusable workloads
- [Sysprep Azure VM](Compute/2-sysprep-vm.md) - Generalize the VM for image capture
- [Capture & Test Image](VMSS/1-capture-and-test-image.md) - Validate golden image readiness
- [VMSS Deployment](VMSS/2-vmss-deployment.md) - Deploy an auto-scaling VM fleet from a golden image

Next recommended lab: [Azure Monitor & Activity Logs](Identity-First/06-azuremonitor-activity-logs.md)

### 5. Monitoring, Compliance & Governance
Outcome: Implement governance guardrails, policy-based remediation, and security monitoring for production-ready operations.

- [Azure Monitor & Activity Logs](Identity-First/06-azuremonitor-activity-logs.md) - Implement audit trails and alerting for security events
- [Azure Locks & Resource Policies](Identity-First/04-azurelocks-resource-policies.md) - Prevent accidental deletion and enforce tagging and SKU constraints
- [Azure Policy Auto-Remediation](Azure%20Policy%20Auto%E2%80%91Remediation/1-Azure%20Policy%20Auto%E2%80%91Remediation.md) - Deploy a DINE policy with managed identity and auto-remediation pipelines
- [Governance Flow Diagram](Identity-First/governance-flow.md) - Review the policy and RBAC control flow visually

Next recommended lab: [Microsoft Entra Backup & Recovery](%20Microsoft%20Entra%20Backup%20%26%20Recovery/1-Microsoft%20Entra%20Backup%20%26%20Recovery.md)

### 6. Business Continuity & Resilience
Outcome: Design and validate backup, recovery, and replication strategies aligned to RPO/RTO requirements.

- [Microsoft Entra Backup & Recovery](%20Microsoft%20Entra%20Backup%20%26%20Recovery/1-Microsoft%20Entra%20Backup%20%26%20Recovery.md) - Compare daily Entra snapshots and recover supported cloud-managed directory objects
- [Azure VM Backup](Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md) - Configure RPO/RTO-aware VM backup
- [Azure Site Recovery](Recovery%20Services%20vaults/2-Azure%20Site%20Recovery.md) - Implement cross-region failover for business continuity
- [Azure Storage Replication](Recovery%20Services%20vaults/3-Azure%20storage%20replication.md) - Compare LRS/ZRS/GRS/GZRS and validate read-access geo-replication

---

## 📚 Recommended Learning Path

Start here and follow the "Next recommended lab" pointers:

1. [Identity Fundamentals](Identity-First/01-identity%20fundamentals.md)
2. [Microsoft Entra Break‑Glass & Emergency Access Accounts](Secure%20Break%E2%80%91Glass%20Accounts/1-Secure%20Break%E2%80%91Glass%20Accounts.md)
3. [Managed Identity + Key Vault](Identity-First/02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md)
4. [Microsoft Entra Roles & RBAC](Identity-First/03-azuread-roles-rbac-scopes.md)
5. [Access Validation](Identity-First/05-access-validation.md)
6. [Identity-First Bicep Capstone Lab](Identity-First/07-bicep-deployment-identity-stack.md)
7. [VS Code Bicep Deployment Workflow](Identity-First/vscode-deployment-workflow.md)
8. [Azure Front Door Static Website Hosting](Azure%20Front%20Door-Static%20Website%20Hosting/Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md)
9. [Build Base VM](Compute/1-build-base-vm.md)
10. [Sysprep Azure VM](Compute/2-sysprep-vm.md)
11. [Capture & Test Image](VMSS/1-capture-and-test-image.md)
12. [VMSS Deployment](VMSS/2-vmss-deployment.md)
13. [Azure Monitor & Activity Logs](Identity-First/06-azuremonitor-activity-logs.md)
14. [Azure Locks & Resource Policies](Identity-First/04-azurelocks-resource-policies.md)
15. [Azure Policy Auto-Remediation](Azure%20Policy%20Auto%E2%80%91Remediation/1-Azure%20Policy%20Auto%E2%80%91Remediation.md)
16. [Governance Flow Diagram](Identity-First/governance-flow.md)
17. [Microsoft Entra Backup & Recovery](%20Microsoft%20Entra%20Backup%20%26%20Recovery/1-Microsoft%20Entra%20Backup%20%26%20Recovery.md)
18. [Azure VM Backup](Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md)
19. [Azure Site Recovery](Recovery%20Services%20vaults/2-Azure%20Site%20Recovery.md)
20. [Azure Storage Replication](Recovery%20Services%20vaults/3-Azure%20storage%20replication.md)

---

## 🛠️ Currently Building

- Azure App Services (deployment slots, scaling, managed identity integration)
- Defender for Cloud — CSPM + Plans with hub-and-spoke topology
- Azure Arc Onboarding (hybrid server management)

---

*Last updated: June 2026 — Built with strong collaboration and a focus on clean, maintainable engineering.*

💼 [LinkedIn](https://linkedin.com/in/nadeemkadwaikar) · 📧 nadeemkadwaikar@outlook.com · 📄 [License](LICENSE)