
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

### Emergency Access

Text flow: Standard identity fails during incident -> Break-glass account -> Recovery actions -> Audit.

```mermaid
flowchart LR
    Admin[Privileged Admin] --> Normal[Standard Identity]
    Normal --> Issue[Access Failure or Incident]
    Issue --> BreakGlass[Break-Glass Account]
    BreakGlass --> Recover[Emergency Recovery Actions]
    Recover --> Audit[Post-Incident Audit]
```
