# Kia ora, I'm Nadeem Kadwaikar👋

Identity and Access Administrator. I build Azure platforms that are secure by design, not by accident.

Most of my work sits where identity, Zero Trust, and resilient infrastructure meet. Everything I build is meant to run in the real world — no theory, no slideware.

## What I'm building

| Area | Focus |
| --- | --- |
| 🔐 Identity | Secretless auth with Managed Identity + Key Vault — credentials out of the stack entirely |
| 📋 Governance | Policy-driven governance with auto-remediation — compliance that enforces itself |
| 🖥️ Compute | VM image lifecycle and scale-set engineering — golden images, repeatable builds |
| 🌐 Networking | Global delivery via Azure Front Door — WAF at the edge, custom domains, static hosting |
| 🔒 Secure Access | Browser-based VM access via Bastion — zero public IP, hub-spoke VNet Peering, JIT time-boxed sessions via Defender for Cloud |
| 🔄 Resilience | Backup, DR, and Entra recovery — platforms that come back cleanly |
| 🚀 CI/CD | App Service deployment slots with Managed Identity, Key Vault references, and Azure DevOps approval gates |
| 🛡️ Security | Break-glass account design — emergency access that doesn't punch a hole in Zero Trust |
| 🌍 Hybrid | Azure Arc hybrid server onboarding — project on-prem and multi-cloud servers into Azure Resource Manager |

---

## Recently shipped

| Lab | What it covers |
| --- | --- |
| [Azure Bastion](./Azure%20Bastion/README.md) | Browser-based RDP/SSH with no public IP, NSG rules for Bastion subnet, Key Vault secretless auth, hub-spoke VNet Peering, troubleshooting guide |
| [Microsoft Defender for Cloud](./Microsoft%20Defender%20for%20Cloud/Readme.md) | Just-In-Time VM access, time-bounded NSG rules, zero standing access |
| [Identity-First Stack](./Identity-First/README.md) | Managed Identity, Key Vault, RBAC, Locks, Policy, Bicep deployment |
| [App Service + Managed Identity + Deployment Slots + Azure DevOps](./App%20Service%20%2B%20Managed%20Identity%20%2B%20Deployment%20Slots%20%2B%20Azure%20DevOps/ReadME.md) | System-Assigned Managed Identity per slot, Key Vault references (secretless), deployment slots, multi-stage Azure DevOps YAML pipeline, manual approval gates |
| [Azure Policy Auto-Remediation](./Azure%20Policy%20Auto%E2%80%91Remediation/README.md) | Policy definitions, assignments, and automatic remediation tasks |
| [VMSS & Golden Images](./VMSS/README.md) | Sysprep, image capture, scale set deployment |
| [Azure Front Door](./Azure%20Front%20Door-Static%20Website%20Hosting/README.md) | WAF, custom domains, static website origin |
| [Backup & Site Recovery](./Recovery%20Services%20vaults/README.md) | VM backup, restore, ASR replication |
| [Break-Glass Accounts – FIDO2](./Secure%20Break%E2%80%91Glass%20Accounts/1-Secure%20Break%E2%80%91Glass%20Accounts.md) | Emergency access with FIDO2 keys, Authentication Strength, and CA enforcement |
| [Break-Glass Accounts – CBA](./Secure%20Break%E2%80%91Glass%20Accounts/2-Certificate-Based%20Authentication%28CBA%29for%20Emergency%20Access%20Accounts.md) | Certificate-based authentication as phishing-resistant MFA for emergency accounts |
| [Entra Backup & Recovery](./Microsoft%20Entra%20Backup%20%26%20Recovery/README.md) | Entra ID configuration backup and restore procedures |
| [Compute & IIS](./Compute/README.md) | Base VM build, Sysprep, IIS installation and configuration |
| [Azure Arc Hybrid Server Architecture](./Azure%20Arc%20Hybrid%20Server%20Architecture/Readme) | Arc Connected Machine Agent, Defender for Servers, Azure Monitor Agent, Update Manager, Guest Configuration policy, private connectivity options |

---

## Reference

- [Naming Convention](./Naming-Convention.md) — resource abbreviations, segment pattern, and per-type naming rules used across all labs
- [Architecture Overview](./Architecture%20Overview.md) — system diagrams for every track

---

## Coming soon — adding this shortly

- Defender for Cloud CSPM and security posture management in a hub-and-spoke architecture

---

## Get in touch

Open to conversations about platform engineering, identity architecture, and Zero Trust.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-nadeemkadwaikar-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://linkedin.com/in/nadeemkadwaikar)
[![Email](https://img.shields.io/badge/Email-nadeemkadwaikar%40outlook.com-0078D4?style=flat&logo=microsoftoutlook&logoColor=white)](mailto:nadeemkadwaikar@outlook.com)
