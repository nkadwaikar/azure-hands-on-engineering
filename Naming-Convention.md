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
| `app` | App Service |
| `asp` | App Service Plan |
| `fd` | Azure Front Door profile |
| `fde` | Azure Front Door endpoint |
| `ogrp` | Front Door origin group |
| `waf` | WAF policy |
| `bas` | Azure Bastion host |
| `peer` | VNet Peering |
| `gal` | Azure Compute Gallery (Shared Image Gallery) |
| `imgdef` | Gallery image definition |
| `imgver` | Gallery image version (semver `major.minor.patch`) |
| `arcm` | Azure Arc-enabled Server (Connected Machine) |
| `aa` | Automation Account |
| `avset` | Availability Set |
| `mg` | Management Group |
| `dcr` | Data Collection Rule |
| `pls` | Private Link Scope (Azure Monitor / Arc) |
| `sc` | Azure DevOps Service Connection |

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
rg-bastion-eus-lab              Azure Bastion lab (East US)
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

VNet Peering names use a descriptive `{source}-to-{destination}` pattern rather than the standard type prefix, as they exist within the context of a VNet:

```text
hub-to-spoke                    Hub VNet → Spoke VNet peering (Azure auto-creates the reverse)
spoke-to-hub                    Reverse peering — auto-created by Azure in same-subscription/same-tenant scenarios
```

### Azure Bastion

```text
bas-{project}-{region}-{env}    Bastion host (one per VNet)
```

Example:

```text
bas-fntech-eus-lab              Bastion host for lab VNet (East US)
```

The `AzureBastionSubnet` name is fixed by Azure and is not subject to the project naming pattern.

The Bastion public IP follows the standard `pip-` prefix:

```text
pip-bas-{project}-{region}-{env}    e.g., pip-bas-fntech-eus-lab
```

> **Note:** Lab guides may use the shorthand `bastion-pip` for brevity — in production, use the full `pip-bas-` prefix.

---

### App Service

```text
app-{project}-{region}-{env}    App Service
asp-{project}-{region}-{env}    App Service Plan
```

Examples:

```text
app-appservice-wus2-lab         App Service for hands-on lab (West US 2)
asp-appservice-wus2-lab         App Service Plan (S1 SKU) for hands-on lab
```

Deployment slot names are short, lowercase identifiers appended automatically to the parent App Service hostname:

```text
staging    app-appservice-wus2-lab-staging.azurewebsites.net
```

---

### Azure Front Door

```text
fd-{project}-{env}              Front Door profile
fde-{project}-{env}             Endpoint (auto-generates <name>.z01.azurefd.net)
ogrp-{project}-{env}            Origin group
waf-{project}-{env}             WAF policy linked to the Front Door profile
```

Examples:

```text
fd-fntech-lab                   Front Door profile for lab static hosting
fde-fntech-lab                  Endpoint — resolves to fde-fntech-lab.z01.azurefd.net
ogrp-fntech-lab                 Origin group pointing at the Storage static website
waf-fntech-lab                  WAF policy (Standard/Premium tier required)
```

---

### Azure Compute Gallery (Shared Image Gallery)

```text
gal-{project}-{region}-{env}              Gallery
imgdef-{os}-{project}-{env}              Image definition (OS type + workload)
```

Image versions use semver — no prefix:

```text
1.0.0    Initial golden image
1.0.1    Patch (security updates)
1.1.0    Minor (additional software)
```

Examples:

```text
gal-fntech-eus-lab                        Compute gallery for VMSS lab
imgdef-win2022-fntech-lab                 Windows Server 2022 image definition
1.0.0                                     First captured image version (IIS + baseline config)
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
| `emergency-admin-{number}@{tenant}.onmicrosoft.com` | Break-glass accounts — FIDO2 security key MFA (Lab 1) |
| `emergency-cba-{number}@{tenant}.onmicrosoft.com` | Break-glass accounts — Certificate-Based Authentication MFA (Lab 2) |

Both emergency account series follow the same role assignment pattern (Global Administrator, Active) and differ only in the phishing-resistant MFA credential type.

---

### Certificates

Certificates used in lab environments (self-signed via PowerShell) follow a descriptive Subject naming pattern:

```text
CN=EmergencyAccessRootCA, O=Lab, C=US    Self-signed root CA for CBA lab
CN=Emergency CBA Admin 01                User certificate — emergency-cba-01 account
CN=Emergency CBA Admin 02                User certificate — emergency-cba-02 account
```

The Subject Alternative Name (SAN) UPN field must match the Entra ID User Principal Name exactly:

```text
SAN UPN: emergency-cba-01@{tenant}.onmicrosoft.com
```

Exported file names follow the account short-name:

```text
RootCA.cer                  Root CA public certificate (uploaded to Entra ID)
EmergencyCBA01.pfx          User certificate + private key for device installation
EmergencyCBA02.pfx
```

---

## Policy and lock names

Policy assignments and resource locks use descriptive names without abbreviation prefixes:

```text
Enforce Secure Transfer on Storage Accounts    DeployIfNotExists custom policy
audit-missing-environment-tag                  Audit tag-compliance policy
Arc-Server-Baseline                            Policy initiative — AMA deployment, Guest Configuration, and mandatory tag enforcement for Arc-enabled servers
rg-delete-lock                                 Delete lock on a Resource Group
sa-readonly-lock                               Read-only lock on a Storage Account
```

### Entra ID — Authentication Strength policies

```text
Emergency Admin – Phishing Resistant Only      Allows FIDO2, CBA, Windows Hello (Lab 1)
Emergency Access – CBA Required                Allows CBA only (Lab 2)
```

### Entra ID — Conditional Access policies

```text
Emergency Admin – Phishing‑Resistant MFA Required     CA policy enforcing Authentication Strength for FIDO2 break-glass accounts (Lab 1)
Emergency CBA Admin – CBA Authentication Required     CA policy enforcing CBA Authentication Strength for CBA break-glass accounts (Lab 2)
```

Conditional Access policy names follow the pattern `{scope} – {control}` to make the intent readable directly in the CA policy list.

---

## Microsoft Defender for Cloud

### JIT VM Access policies

JIT policies are not separately named resources — they are scoped to the VM and managed internally by Defender for Cloud. No user-defined name is required.

### JIT NSG rules

NSG rules created by JIT are **auto-generated and ephemeral**. They are not subject to the project naming pattern:

| Pattern | Example | Notes |
| --- | --- | --- |
| `SecurityCenter-JITRule-{port}-{timestamp}` | `SecurityCenter-JITRule-3389-1234567890` | Auto-created on JIT approval |

These rules are automatically removed when the time window expires. Do not manually rename or modify them.

### JIT request justifications

Justification text entered when requesting JIT access should follow a descriptive pattern:

```text
{purpose} – {requester} – {date}
```

Example:

```text
Incident response – nkadwaikar – 2026-06-23
```

---

### Azure Arc Hybrid Servers

Arc-enabled server (Connected Machine) resources are named to match the on-prem hostname where possible — this makes cross-referencing straightforward in the portal and in KQL queries.

```text
arcm-{hostname}                 Connected Machine — name mirrors on-prem hostname
aa-{project}-{region}-{env}    Automation Account (Update Manager, runbooks)
mg-{name}                      Management Group (no type segment required — context is clear)
dcr-{project}-{region}-{env}   Data Collection Rule
pls-{project}-{env}            Private Link Scope for Arc / Azure Monitor
```

Examples:

```text
rg-arc-servers-prod             Arc landing zone (production)
rg-arc-servers-nonprod         Arc landing zone (non-production)
rg-arc-lab                      Arc lab resource group — disposable, isolated from prod/nonprod
law-hybrid-ops                  Central Log Analytics workspace for hybrid telemetry
law-arc-lab                     Lab-only workspace — keeps lab telemetry out of production dashboards
arcm-srv-dc01                   On-prem domain controller projected into Azure Arc
arcm-lab-lab-win01              Hyper-V lab VM (Windows) onboarded to Arc for lab validation
arcm-lab-lab-lnx01              Hyper-V lab VM (Linux) onboarded to Arc for lab validation
aa-arc-eus-prod                 Automation Account for Update Manager and runbooks
aa-arc-eus-nonprod              Non-prod Automation Account for staging runbook changes (never target prod)
mg-hybrid-servers               Management Group housing the Arc landing zone subscription
dcr-arc-eus-prod                Data Collection Rule — OS perf + events for Arc servers
pls-arc-hybrid                  Private Link Scope for Arc / Azure Monitor (‘hybrid’ used when env segment reflects mixed connectivity scope rather than a single deployment tier)
pls-arc-prod                    Private Link Scope — production-only variant
```

#### RBAC role names

Custom roles for the Arc landing zone follow a descriptive `{Scope}-{PermissionLevel}` pattern rather than the `{type}-` prefix convention used for Azure resources:

| Role name | Permissions |
| --- | --- |
| `Hybrid-Server-Reader` | Read-only view of Arc machines, no control-plane operations |
| `Hybrid-Server-Operator` | Restart, manage extensions — no policy changes |
| `Security-Operator` | Defender for Cloud, alerts, recommendations |

Assign at resource group or subscription scope. Avoid per-resource RBAC sprawl. In the lab, scope each role assignment to `rg-arc-lab` only — do not add the lab RG as an extra scope on existing production role assignments.

---

### Domain Controller (Active Directory DS)

Resources deployed for the Azure-hosted domain controller lab follow the standard pattern. Domain controller VMs use short, role-indicating hostnames (`dc01`, `dc02`) rather than the full `{type}-{project}-{region}-{env}` pattern — this mirrors on-premises DC naming conventions and prevents overly long computer names that can cause AD registration issues.

```text
rg-addc-{region}-{env}              Resource group scoping all DC lab resources
vnet-addc-{region}-{env}            Virtual network for the DC workload
snet-addc                           Subnet for domain controller VMs (no hyphens after the subnet type — role is self-describing)
nsg-addc-{region}-{env}             NSG attached to the DC subnet
bas-addc-{region}-{env}             Azure Bastion host (admin access — no public IPs on DCs)
pip-bas-addc-{region}-{env}         Public IP for the Bastion host
avset-addc-{region}-{env}           Availability Set distributing the two DCs across fault/update domains
dc01 / dc02                         Domain controller VM hostnames (short — matches AD computer account name)
kv-addc-{region}-{env}              Key Vault storing DSRM passwords and local admin credentials
```

Examples:

```text
rg-addc-eus-lab                     DC lab resource group (East US)
vnet-addc-eus-lab                   Lab VNet (10.0.0.0/16)
snet-addc                           DC subnet (/24)
nsg-addc-eus-lab                    NSG — AD DS port rules (VNet-scoped inbound only)
bas-addc-eus-lab                    Bastion host for RDP access to DCs
pip-bas-addc-eus-lab                Bastion public IP
avset-addc-eus-lab                  Availability Set (2 fault domains, 5 update domains)
dc01                                First domain controller VM (Primary DC / PDC Emulator)
dc02                                Second domain controller VM (Additional DC)
kv-addc-eus-lab                     Key Vault — DSRM passwords for dc01 and dc02
```

> **Note:** The data disk on each DC VM (for NTDS/SYSVOL) is not separately named — it is labelled `NTDS` at the OS level (volume label) and identified in the portal as `dc01-data-disk-01` / `dc02-data-disk-01` (portal auto-naming). Host caching must be set to **None**.

---

### Azure DevOps

Azure DevOps organizations and projects use existing business/tenant names and are not subject to the `{type}-{project}-{region}-{env}` pattern. Pipelines, service connections, and variable groups inside a project follow the convention below.

```text
sc-{project}-{env}          Service connection (ARM or workload-identity federation)
```

Examples:

```text
sc-appservice-lab           Service connection for the App Service deployment lab
sc-identity-lab             Service connection scoped to the Identity-First lab subscription
```

Pipeline YAML files are stored in the repository and named by workload:

```text
azure-pipelines.yml         Default pipeline file at repository root
azure-pipelines-{stage}.yml Stage-specific override (e.g., azure-pipelines-staging.yml)
```

Variable groups (Library) use a descriptive lowercase-hyphen name:

```text
{project}-{env}-vars        e.g., appservice-lab-vars
```

---

[← Back to Azure Hands-On Engineering](./README.md)
