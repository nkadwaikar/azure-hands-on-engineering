# Naming Convention

All resources across these labs follow a consistent pattern aligned with the Azure Cloud Adoption Framework (CAF). This page is the single reference for the abbreviations, segment order, and per-resource-type rules used throughout every lab guide.

---

## Pattern

```text
{type}-{project}-{region}-{env}-{component}
```

| Segment | Purpose | Examples |
| --- | --- | --- |
| `type` | Resource type abbreviation (see table below) | `rg`, `vm`, `kv` |
| `project` | Project or workload short-code | `identity`, `fntech`, `policy` |
| `region` | Azure region short-code | `eus` (East US), `wus2` (West US 2) |
| `env` | Deployment environment | `lab`, `core`, `prod` |
| `component` | Functional role or sub-component | `core`, `app`, `dr`, `backup` |

Instance numbers (`01`, `02`, …) are appended when multiple instances of the same type exist in the same scope.

---

## Resource type abbreviations

| Abbreviation | Resource type |
| --- | --- |
| `rg` | Resource Group |
| `vm` | Virtual Machine |
| `vmss` | Virtual Machine Scale Set |
| `vnet` | Virtual Network |
| `snet` | Subnet |
| `nsg` | Network Security Group |
| `pip` | Public IP Address |
| `kv` | Key Vault |
| `st` | Storage Account (no hyphens — globally unique) |
| `rsv` | Recovery Services Vault |
| `rp` | Recovery Plan |
| `asr` | ASR Replication Group |
| `law` | Log Analytics Workspace |
| `uami` | User-Assigned Managed Identity |
| `fd` | Azure Front Door profile |

---

## Region codes

| Code | Region |
| --- | --- |
| `eus` | East US |
| `wus2` | West US 2 |

---

## Examples by resource type

### Resource Groups

```text
rg-identity-eus-lab-core        Identity-First lab core infrastructure
rg-fntech-vm-lab-eus-core       Base VM build lab
rg-policy-eus-lab-remedy        Azure Policy auto-remediation lab
rg-fntech-eus-lab-backup        VM backup and recovery lab
rg-fntech-wus2-lab-dr           Disaster recovery environment (West US 2)
rg-vmss-lab                     VMSS deployment lab
```

### Virtual Machines

```text
vm-identity-eus-lab-app01       Ubuntu 22.04 with system-assigned managed identity
vm-fntech-eus-lab-app01         Windows Server 2022 — golden image source
vm-fntech-eus-lab-fs01          Windows Server 2019 — backup source
```

### Key Vaults

```text
kv-identity-eus-lab-core        RBAC-mode vault for secretless authentication lab
```

### Storage Accounts

Storage accounts cannot contain hyphens and must be globally unique. The format drops hyphens:

```text
st{project}{purpose}{number}
```

Examples:

```text
stidentitylabcore01             Identity lab core storage
stfntechlabbkp01                Backup scenario storage
stpolicylabremedy01             Policy remediation storage
```

### Networking

```text
vnet-fntech-vm-lab-eus-core     Lab virtual network (East US)
vnet-fntech-wus2-lab-dr         DR virtual network (West US 2)
snet-app                        Application tier subnet
pip-fntech-eus-lab-vm           Lab VM public IP
nsg-fntech-wus2-lab-vm          DR environment NSG
```

### Recovery Services Vaults

```text
rsv-vmbackup-eus-lab-backup     VM backup vault
rsv-fntech-wus2-lab-dr          ASR target vault (West US 2)
```

### Monitoring

```text
law-governance                  Centralised governance Log Analytics workspace
```

### Managed Identities

```text
uami-{project}-{region}-{env}   User-assigned managed identity (referenced in Bicep)
```

System-assigned managed identities are named automatically by Azure and follow the parent resource name.

### Entra ID accounts

| Pattern | Use |
| --- | --- |
| `{firstname}.{lastname}@{domain}` | Standard lab user accounts |
| `emergency-admin-{number}@{tenant}.onmicrosoft.com` | Break-glass accounts |

---

## Policy and lock names

Policy assignments and resource locks use descriptive names without abbreviation prefixes:

```text
Enforce Secure Transfer on Storage Accounts    DeployIfNotExists custom policy
audit-missing-environment-tag                  Audit tag-compliance policy
rg-delete-lock                                 Delete lock on a Resource Group
sa-readonly-lock                               Read-only lock on a Storage Account
```

---

[← Back to README](./README.md)
