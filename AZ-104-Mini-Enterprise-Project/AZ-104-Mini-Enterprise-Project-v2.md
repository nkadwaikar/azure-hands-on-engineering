# Mini Enterprise: AZ-104 Hands-On Project (v2)

> **Why this matters:** Isolated demos do not build real Azure fluency — this project wires all five AZ-104 exam domains into one connected environment so every resource you deploy depends on what came before it, mirroring how production architectures actually work.

A single connected Azure build that exercises all five AZ-104 domains (April 2026 outline). Built as one environment so each layer depends on the one before it — governance first, monitoring last, tying everything together.

Last validated on: 2026-04-01
Portal experience note: Steps validated against Azure Portal as of April 2026; labels can vary slightly by region and feature rollout.

> **Note:** Complete phases in order — each phase deploys resources that later phases depend on. Estimated total hands-on time: 40–60 hours across multiple sessions. ⭐ marks items with a dedicated lab guide in this repo.

---

## Module / Track Structure

```text
AZ-104-Mini-Enterprise-Project/
└── AZ-104-Mini-Enterprise-Project-v2.md   ← Project checklist (you are here)
```

---

## Quick Navigation

- [Phase 1 — Identities & Governance](#phase-1--identities--governance-2025)
- [Phase 2 — Networking](#phase-2--networking-1520)
- [Phase 3 — Compute](#phase-3--compute-2025)
- [Phase 4 — Storage](#phase-4--storage-1520)
- [Phase 5 — Monitoring](#phase-5--monitoring-1015)

---

## Phase 1 — Identities & Governance (20–25%)

- [ ] Create/use a Microsoft Entra ID tenant; add 3–4 test users, 2 groups
- [ ] Assign Azure RBAC roles at subscription, resource-group, and resource scope — confirm you understand inheritance and how conflicting assignments resolve
- [ ] Build a management group hierarchy (2 levels)
- [ ] Create and assign an Azure Policy (e.g. "require a tag," "allowed locations"); check compliance state
- [ ] Set up a budget with a cost alert
- [ ] Enable MFA + a Conditional Access policy for one test user
- [ ] Create a custom RBAC role definition (JSON)
- [ ] **Apply resource locks** (CanNotDelete and ReadOnly) — test that they actually block the action
- [ ] Invite a guest/B2B user; explore administrative units
- [ ] Move a resource between resource groups (and note what can't be moved)

### Validation

- **RBAC inheritance:** Remove a role at RG scope — confirm the subscription-level assignment still appears under the user's Effective roles
- **Policy compliance:** After assignment, Policy → Compliance shows non-compliant resources within 30 minutes
- **Resource lock:** Attempt to delete a locked resource — portal returns a "scope is locked" error before the delete proceeds
- **Custom role:** Appears under Subscriptions → Access Control (IAM) → Roles with type `CustomRole`
- **MFA/CA:** Sign in as the test user in a private browser — MFA prompt fires or access is blocked per the CA condition you configured
- **Resource move:** `az resource move` succeeds (or returns a clear `MoveNotSupported` error for unsupported types)

---

## Phase 2 — Networking (15–20%)

- [ ] Build a hub-and-spoke VNet topology with peering
- [ ] Configure NSGs on subnets + a custom route table (UDR)
- [ ] ⭐ Deploy **Azure Bastion**; connect to a VM through it (no public IP)
- [ ] Deploy a Load Balancer and an Application Gateway in front of 2 VMs; understand when to use each
- [ ] ⭐ Run **Network Watcher**: IP flow verify + connection troubleshoot
- [ ] Configure a private DNS zone
- [ ] Configure a **public DNS zone** and delegate/verify a record
- [ ] Deploy a **Private Endpoint** for a PaaS resource (e.g. storage account) and compare against a Service Endpoint
- [ ] Stand up a quick **point-to-site VPN Gateway**; understand it conceptually vs. ExpressRoute
- [ ] Deploy a **NAT Gateway** for outbound-only internet access from a subnet

### Validation

- **Peering:** Both VNets show "Connected" status under Virtual Network → Peerings; ping across peered VNets succeeds
- **NSG + UDR:** Network Watcher → IP Flow Verify returns the expected Allow/Deny; `Get-NetRoute` on the VM shows the custom next-hop
- **Bastion:** VM has no public IP in the Networking blade; Bastion browser session connects without one
- **LB vs App Gateway:** LB backend pool shows healthy probes (L4); AGW backend health shows healthy (L7)
- **Private DNS zone:** `nslookup <record>` from a VM in the linked VNet resolves to the expected private IP
- **Private endpoint:** Storage account Networking blade shows an approved private IP; access from outside the VNet is blocked
- **NAT Gateway:** `curl ifconfig.me` from a VM on the subnet returns the NAT Gateway public IP

---

## Phase 3 — Compute (20–25%)

- [ ] Deploy VMs into an availability set; convert the pattern to a VM Scale Set
- [ ] Configure **autoscale rules** on the VM Scale Set (tie forward to Phase 5 monitoring)
- [ ] ⭐ Deploy the same VM using a **Bicep** file (not the portal) via `az deployment group create`
- [ ] ⭐ Deploy an **Azure Container App**; deploy a Container Instance for comparison — know when you'd pick each, and how both differ from AKS
- [ ] **Deploy an Azure App Service (Web App)**; configure a deployment slot and swap it; understand scale-up vs. scale-out
- [ ] Apply a **VM extension** (Custom Script Extension) to a VM
- [ ] Configure VM auto-shutdown and an Azure Backup policy
- [ ] Review **managed disk types** (Standard HDD/SSD, Premium SSD, Ultra) and enable disk encryption
- [ ] Set up **Azure Update Manager** for patch scheduling (distinct from backup)
- [ ] ⭐ Enable **Azure Arc** on a VM (even a local VM registered as "on-prem") — just enough to recognize its purpose

### Validation

- **Availability set:** Both VMs show different Fault Domains in the Availability Set blade
- **Bicep deployment:** `az deployment group show -g <rg> -n <name> --query properties.provisioningState` returns `"Succeeded"`
- **VMSS autoscale:** Trigger the scale condition (e.g. CPU stress); instance count increases under VMSS → Instances within the cooldown period
- **Container App vs ACI:** Container App shows Running under Revisions; ACI shows Running — confirm ACI has no built-in autoscale or ingress
- **App Service slot swap:** After swap, the production hostname serves the staged content; swap event appears in Activity Log
- **VM extension:** Extensions blade shows Custom Script Extension with status `Provisioning succeeded`
- **Backup:** VM → Backup shows “Protection enabled” with a scheduled next backup time
- **Disk encryption:** Disks blade shows the encryption state (PMK or CMK per your configuration)
- **Azure Arc:** VM shows “Connected” status in Azure Arc → Servers

---

## Phase 4 — Storage (15–20%)

- [ ] Create a storage account; configure blob lifecycle management + access tiers (hot/cool/archive)
- [ ] Create an Azure Files share; mount it on a VM
- [ ] Test soft delete and blob versioning
- [ ] (Stretch) Configure Azure File Sync between the share and a local folder
- [ ] Review redundancy options (LRS/ZRS/GRS/GZRS) and when each applies
- [ ] Generate a **Shared Access Signature (SAS)** token; scope it down and test access; rotate a storage account key
- [ ] Configure **storage account network rules** (firewall, private endpoint, allowed VNets)
- [ ] Move data with **AzCopy** or Storage Explorer

### Validation

- **Lifecycle policy:** Storage Account → Data Management → Lifecycle management shows the rule active; use a blob with a past `LastModified` date to trigger it immediately in a test container
- **Azure Files mount:** `net use Z: \\\\<storage>.file.core.windows.net\\<share>` returns “The command completed successfully”; `Z:\` is accessible from the VM
- **Soft delete:** Delete a blob, then restore it via Storage Browser → Deleted blobs — blob reappears with active status
- **SAS token:** Scoped URL returns `200`; modify the URL to access a resource outside the SAS scope — returns `403 AuthorizationFailure`
- **Storage network rules:** Remove your IP from the allowlist — portal and Storage Explorer return “This request is not authorized”
- **AzCopy:** Job log shows `Number of Transfers Completed: N`, `Number of Transfers Failed: 0`

---

## Phase 5 — Monitoring (10–15%)

- [ ] Enable Azure Monitor + a Log Analytics workspace across all resources above
- [ ] Configure **diagnostic settings** to send resource logs/metrics to the Log Analytics workspace (distinct from just enabling Monitor)
- [ ] Write a KQL query against VM performance logs
- [ ] Create an alert rule with an action group (email/SMS)
- [ ] Wire an alert into the **autoscale rule** from Phase 3
- [ ] Review Activity Log entries for changes made in Phases 1–4
- [ ] Check **Azure Advisor** recommendations across the environment
- [ ] Review **Service Health / Resource Health** for a deployed resource

### Validation

- **Log Analytics agents:** `Heartbeat | summarize max(TimeGenerated) by Computer` — all VMs appear with a timestamp within the last 5 minutes
- **Diagnostic settings:** `AzureDiagnostics | where ResourceType == "MICROSOFT.NETWORK/NETWORKSECURITYGROUPS" | take 5` returns rows
- **KQL query:** `Perf | where CounterName == "% Processor Time" | summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)` returns rows with VM names
- **Alert rule:** Send a test notification from the action group — email/SMS received; alert shows Fired state in Monitor → Alerts
- **Autoscale + alert:** Scale event appears in Monitor → Activity Log; connected alert fires to the action group
- **Azure Advisor:** At least one recommendation is visible — or resolve one and confirm it clears within 24 hours
- **Service Health vs Resource Health:** Service Health shows platform-level outages and planned maintenance; Resource Health shows the health state of your specific resource — note the distinction

---

## Cleanup

Delete resources in reverse phase order to avoid dependency errors.

| Step | What to delete | Notes |
| --- | --- | --- |
| 1 | Alert rules, action groups, diagnostic settings | Monitor → Alerts → Alert rules; each resource → Diagnostic settings |
| 2 | Log Analytics workspace | Deletion is soft-delete by default — purge explicitly if needed |
| 3 | Storage accounts, Azure Files shares | Unmount shares from VMs before deleting the storage account |
| 4 | Backup vault | Stop protection and delete backup data first — vault cannot be deleted while items are protected |
| 5 | Container Apps, Container Instances, App Service + Plan | Delete the App Service Plan after all apps are removed |
| 6 | VMs, VMSS, availability set | Disks and NICs must be deleted separately unless "Delete with VM" was enabled |
| 7 | Bastion, NAT Gateway, VPN Gateway, App Gateway, Load Balancer | Gateways take 5–10 minutes to deprovision; delete in this order |
| 8 | NSGs, route tables, VNets | Peerings are removed automatically when the VNet is deleted |
| 9 | Resource locks | Remove locks before attempting resource group deletion |
| 10 | Resource groups | Deletes all contained resources in one operation |

> **Important:** Entra ID objects (users, groups, CA policies, custom roles, guest users) are tenant-scoped and are not removed when resource groups are deleted. Delete them separately in the Entra ID portal.

---

## Changelog from v1

- Added: resource locks, guest/B2B users, resource move (Phase 1)
- Added: public DNS zone, Private Endpoint, point-to-site VPN Gateway, NAT Gateway (Phase 2)
- Added: App Service + deployment slots, VM extensions, managed disk types/encryption, Update Manager, VMSS autoscale (Phase 3)
- Added: SAS tokens/key rotation, storage network rules, AzCopy (Phase 4)
- Added: diagnostic settings, autoscale-alert integration, Azure Advisor, Service/Resource Health (Phase 5)
- Added: per-phase Validation subsections and Cleanup table (v2 formatting pass)