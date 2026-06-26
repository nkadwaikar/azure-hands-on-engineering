# 👋 Hi, I'm Nadeem Kadwaikar

Cloud & Identity Engineer — Azure · Microsoft 365 · Zero Trust

I design and build Azure environments that are secure by default, repeatable by design, and maintainable by the next engineer. My focus is identity-first architecture, infrastructure as code, and production-aligned governance — the kind of work that keeps regulated environments compliant and teams unblocked.

---

## 🎯 Skills

| Area | What I Do |
|---|---|
| **Azure Infrastructure** | VMs, VMSS, VNets, NSGs, Load Balancers, Front Door, Storage — built for resilience |
| **Identity & Zero Trust** | Microsoft Entra ID, RBAC, Conditional Access, Managed Identities, Key Vault |
| **IaC & Automation** | Modular Bicep deployments, GitHub Actions, PowerShell, Azure CLI |
| **Governance & Compliance** | Azure Policy, Resource Locks, Activity Logs, Monitor — aligned to regulated environments |
| **Microsoft 365** | Tenant admin, users & groups, security & compliance, endpoint basics |
| **Business Continuity** | Azure Backup, Site Recovery, VMSS failover patterns |

---

## 🗺️ Platform Architecture

```mermaid
flowchart TD
    subgraph Identity["🔐 Identity Plane"]
        EntraID["Entra ID"]
        MI["Managed Identity"]
        KV["Key Vault"]
    end
    subgraph Governance["📋 Governance"]
        Policy["Azure Policy"]
        Remediation["Auto-Remediation"]
    end
    subgraph Access["🔒 Secure Access"]
        Bastion["Azure Bastion"]
        JIT["JIT · Defender for Cloud"]
        AFD["Front Door · WAF"]
    end
    subgraph Compute["🖥️ Compute"]
        VM["Virtual Machines · VMSS"]
        App["App Service"]
    end
    subgraph Ops["🔄 Ops & Resilience"]
        DevOps["Azure DevOps"]
        Monitor["Azure Monitor"]
        Backup["Recovery Services"]
        Arc["Azure Arc"]
    end

    EntraID --> MI
    MI --> KV
    MI --> App
    MI --> VM
    Policy --> Remediation
    Remediation --> VM & App
    Bastion --> VM
    JIT --> VM
    AFD --> App
    DevOps --> App
    Monitor --> VM & App
    Backup --> VM
    Arc --> VM & Monitor
```

---

## 📌 Labs & Guides

Each lab reflects a real Azure engineering pattern — not a tutorial walkthrough, but a production-aligned implementation with documented reasoning.

### 1. Identity-First Security & Zero Trust

- [Identity-First Architecture — Full Track](Identity-First/README.md) — End-to-end track overview: Entra ID, Managed Identity, Key Vault, RBAC, governance locks, and modular Bicep IaC from fundamentals to capstone
- [Identity-First Bicep Capstone](Identity-First/07-bicep-deployment-identity-stack.md) — Modular Bicep stack: Managed Identity + Key Vault + RBAC + Governance Lock
- [Managed Identity + Key Vault](Identity-First/02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md) — Secretless authentication; eliminates credential sprawl
- [Entra ID Roles & RBAC](Identity-First/03-azuread-roles-rbac-scopes.md) — Least-privilege role assignments across scopes
- [Break-Glass Accounts — Track Overview](Secure%20Break%E2%80%91Glass%20Accounts/README.md) — Emergency access track: FIDO2 hardware keys and certificate-based auth as phishing-resistant MFA
- [Break-Glass Accounts – FIDO2](Secure%20Break%E2%80%91Glass%20Accounts/1-Secure%20Break%E2%80%91Glass%20Accounts.md) — Emergency access with FIDO2 hardware keys and Conditional Access enforcement
- [Break-Glass Accounts – CBA](Secure%20Break%E2%80%91Glass%20Accounts/2-Certificate-Based%20Authentication%28CBA%29for%20Emergency%20Access%20Accounts.md) — Certificate-based auth as phishing-resistant MFA for emergency accounts
- [Entra Backup & Recovery](Microsoft%20Entra%20Backup%20%26%20Recovery/README.md) — Entra ID configuration export, versioning, and restore procedures

### 2. Azure Infrastructure as Code (IaC)

- [Identity-First Bicep Capstone](Identity-First/07-bicep-deployment-identity-stack.md) — Week 1 capstone: assemble the full identity-first foundation — UAMI, Key Vault, RBAC, and locks — as reviewable, deployable Bicep modules *(also in Section 1)*
- [Bicep in VS Code — Toolchain Setup](Identity-First/08-how-to-run-bicep-in-vscode.md) — Install the extension, authenticate, and step through the deploy-validate-redeploy cycle without touching the CLI
- [Bicep in VS Code — Deployment Mechanics](Identity-First/11-vscode-deployment-workflow.md) — How a right-click deploy maps to subscription-scoped → resource-group-scoped module stages under the hood
- [Naming Convention](Naming-Convention.md) — Resource abbreviations, segment pattern, and per-type naming rules used across all labs

### 3. Secure Access & Networking

- [Azure Bastion](Azure%20Bastion/README.md) — Browser-based RDP/SSH, no public IP, hub-spoke VNet peering, secretless Key Vault auth
- [Microsoft Defender for Cloud – JIT](Microsoft%20Defender%20for%20Cloud/Readme.md) — Time-bounded NSG rules, zero standing inbound access
- [Azure Front Door](Azure%20Front%20Door-Static%20Website%20Hosting/README.md) — WAF at the edge, custom domain with TLS, static website origin

### 4. Governance & Compliance

- [Azure Policy Auto-Remediation](Azure%20Policy%20Auto%E2%80%91Remediation/README.md) — Custom policy definitions, assignments, and automated remediation tasks
- [Azure Monitor & Activity Logs](Identity-First/06-azuremonitor-activity-logs.md) — Audit trail and alerting for security events
- [Governance Flow Diagram](Identity-First/09-governance-flow.md) — Visual trace of how RBAC and Resource Locks interact; makes the governance control layer visible, not implied

### 5. Compute & Image Lifecycle

- [Compute — Track Overview](Compute/README.md) — VM provisioning lifecycle: base build, Sysprep, and IIS validation
- [Build Base VM](Compute/1-build-base-vm.md) — Provision a VM with consistent naming conventions, security defaults, and post-deployment validation; foundation for all Compute track labs
- [Install IIS](Compute/3-Install%20IIS.md) — Install IIS web server role and write a test page; validates HTTP traffic before the image is locked for VMSS use
- [Sysprep Azure VM](Compute/2-sysprep-vm.md) — Generalize the Windows installation for image capture; removes machine-specific SIDs and stale OS state
- [VMSS — Track Overview](VMSS/README.md) — Full VM scale set lifecycle: image capture, test deployment, and scale set provisioning
- [Capture & Test Image](VMSS/1-capture-and-test-image.md) — Capture the Sysprepped VM to an Azure Compute Gallery and boot a test VM from it before locking the image version
- [VMSS Deployment](VMSS/2-vmss-deployment.md) — Auto-scaling VM fleet from a golden image

### 6. App Service & DevOps

- [App Service + Managed Identity + Deployment Slots + Azure DevOps](App%20Service%20%2B%20Managed%20Identity%20%2B%20Deployment%20Slots%20%2B%20Azure%20DevOps/ReadME.md) — Secretless app config via Key Vault references, per-slot Managed Identity, multi-stage pipeline with manual approval gates

### 7. Business Continuity & Resilience

- [Recovery Services — Track Overview](Recovery%20Services%20vaults/README.md) — Full resilience stack: VM backup, site recovery, and storage replication
- [Azure VM Backup](Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md) — RPO/RTO-aware backup configuration
- [Azure Site Recovery](Recovery%20Services%20vaults/2-Azure%20Site%20Recovery.md) — Cross-region failover for business continuity
- [Storage Replication](Recovery%20Services%20vaults/3-Azure%20storage%20replication.md) — LRS, ZRS, GRS, RA-GZRS — redundancy options and geo-failover

### 8. Hybrid & Arc

- [Azure Arc Hybrid Server Architecture](Azure%20Arc%20Hybrid%20Server%20Architecture/Readme.md) — Arc-enabled servers, Defender for Servers, Azure Monitor Agent, Update Manager, Guest Configuration

---

## 🛠️ Next

- Defender for Cloud CSPM — security posture management across a hub-and-spoke architecture
- Copilot Studio — AI agent with SharePoint knowledge source, secured with Entra ID

---

## 💡 Engineering Philosophy

I build things that future‑me — and future teams — can pick up without sorting through a mess. Every lab is shaped by three principles: clarity (document decisions, not just commands), repeatability (deployments that run cleanly every time), and secure defaults (identity‑first, least privilege, no hardcoded credentials).

---

## Connect

- 💼 [LinkedIn](https://linkedin.com/in/nadeemkadwaikar)
- 📧 nadeemkadwaikar@outlook.com

---

Last updated: June 2026
