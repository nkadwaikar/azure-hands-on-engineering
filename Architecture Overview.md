
# Architecture Overview

## Identity Governance

Text flow: Engineer/Admin -> Microsoft Entra ID -> Managed Identity -> RBAC -> Key Vault -> Resource Lock.

```mermaid
flowchart LR
    User[Engineer / Admin] --> Entra[Microsoft Entra ID]
    Entra --> UAMI[Managed Identity]
    UAMI --> RBAC[RBAC Assignment]
    RBAC --> KV[Key Vault]
    KV --> Lock[Resource Lock]
```

### Compute Lifecycle

Text flow: Base VM Build -> Sysprep -> Golden Image -> Gallery Version -> VMSS -> Validation.

```mermaid
flowchart LR
    Build[Base VM Build] --> Prep[Sysprep]
    Prep --> Image[Golden Image Capture]
    Image --> Gallery[Image Version]
    Gallery --> VMSS[VM Scale Set]
    VMSS --> Validate[App Validation IIS]
```

### Global Delivery

Text flow: Client -> Front Door -> Origin Group -> Storage Static Website -> $web content.

```mermaid
flowchart LR
    Client[Client] --> FD[Azure Front Door]
    FD --> OG[Origin Group]
    OG --> Site[Storage Static Website]
    Site --> Web[$web Container]
```

### Governance Automation

Text flow: Policy Definition -> Assignment -> Compliance Evaluation -> Auto-remediation -> Compliant state.

```mermaid
flowchart LR
    Def[Policy Definition] --> Assign[Policy Assignment]
    Assign --> Eval[Compliance Evaluation]
    Eval --> Remed[Auto Remediation Task]
    Remed --> State[Compliant Resource State]
```

### Business Continuity

Text flow: Production VM -> Recovery Services Vault -> Backup/ASR -> Restore or Failover.

```mermaid
flowchart LR
    VM[Production VM] --> RSV[Recovery Services Vault]
    RSV --> Backup[Backup Recovery Points]
    RSV --> ASR[Site Recovery Replication]
    ASR --> Failover[Failover / Failback]
    Backup --> Restore[Restore / Point-in-time Recovery]
```

### Secure VM Access

Text flow: Resource Group (rg-bastion-eus-lab) -> VNet with AzureBastionSubnet -> Azure Bastion host -> Engineer browser (HTTPS 443) connects through Bastion -> Target VM (private IP only). JIT opens the NSG rule for a time-bounded window before the session is established.

```mermaid
flowchart LR
    RG[Resource Group\nrg-bastion-eus-lab] --> VNet[Private VNet]
    VNet --> Subnet[AzureBastionSubnet /26]
    Subnet --> Bastion[Azure Bastion Host\nbas-fntech-eus-lab]
    Browser[Engineer Browser\nHTTPS 443] --> Bastion
    Bastion --> VM[Target VM\nPrivate IP Only]
    JIT[JIT Request\nDefender for Cloud] --> NSG[NSG Rule\nTime-Bounded]
    NSG --> VM
```

### Emergency Access

Text flow: Standard identity fails during incident -> Break-glass account (FIDO2 or CBA) -> Authentication Strength enforced by Conditional Access -> Emergency Recovery Actions -> Post-Incident Audit.

```mermaid
flowchart LR
    Admin[Privileged Admin] --> Normal[Standard Identity]
    Normal --> Issue[Access Failure or Incident]
    Issue --> BG[Break-Glass Account]
    BG --> FIDO2[FIDO2 Security Key\nLab 1]
    BG --> CBA[X.509 Certificate\nLab 2]
    FIDO2 --> AS[Authentication Strength\nPhishing-Resistant Only]
    CBA --> AS
    AS --> CA[Conditional Access\nEnforced - Not Bypassed]
    CA --> Recover[Emergency Recovery Actions]
    Recover --> Audit[Post-Incident Audit & Log Review]
```

**Design note:** Both MFA methods are enforced by a dedicated Authentication Strength policy inside Conditional Access. Break-glass accounts are never excluded from CA — consistent with the Microsoft 2025 security baseline.

---

## Lab Tracks

| Track | Description |
| --- | --- |
| [Azure Bastion](./Azure%20Bastion/README.md) | Secure browser-based VM access, JIT integration, no public IP |
| [Identity-First](./Identity-First/README.md) | Managed Identity, Key Vault, RBAC, Locks, Policy, Bicep |
| [Azure Policy Auto-Remediation](./Azure%20Policy%20Auto%E2%80%91Remediation/README.md) | Custom policy, DeployIfNotExists, remediation tasks |
| [Compute](./Compute/README.md) | Base VM build, Sysprep, IIS installation |
| [VMSS](./VMSS/README.md) | Golden image capture, scale set deployment |
| [Azure Front Door](./Azure%20Front%20Door-Static%20Website%20Hosting/README.md) | WAF, custom domains, static website origin |
| [Recovery Services Vaults](./Recovery%20Services%20vaults/README.md) | VM backup, restore, ASR replication |
| [Break-Glass – FIDO2 (Lab 1)](./Secure%20Break%E2%80%91Glass%20Accounts/1-Secure%20Break%E2%80%91Glass%20Accounts.md) | Cloud-only emergency accounts with FIDO2 keys, Authentication Strength, CA enforcement |
| [Break-Glass – CBA (Lab 2)](./Secure%20Break%E2%80%91Glass%20Accounts/2-Certificate-Based%20Authentication%28CBA%29for%20Emergency%20Access%20Accounts.md) | Certificate-based authentication as phishing-resistant MFA for emergency access |
| [Microsoft Entra Backup & Recovery](./Microsoft%20Entra%20Backup%20%26%20Recovery/README.md) | Entra directory backup and object-level recovery |

[← Back to README](./README.md)
