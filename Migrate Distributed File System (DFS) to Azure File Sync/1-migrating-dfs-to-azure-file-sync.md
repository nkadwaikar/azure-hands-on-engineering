# Migrating DFS to Azure File Sync

> **Why this matters:** DFS-R is a replication engine that breaks silently — split-brain conflicts, inconsistent folder targets, and bandwidth-saturating initial syncs are common in multi-site environments. Azure File Sync replaces DFS-R with a cloud-backed, multi-master sync model that is resilient by design, supports cloud tiering to reduce on-premises storage footprint, and integrates with Azure Monitor for health visibility. DFS Namespaces can stay in place, so users see no change to their UNC paths during or after the migration.

This guide walks through a production-aligned migration from DFS Namespaces and DFS-R replication to Azure File Sync — inventorying the existing topology, deploying Azure resources, syncing data, cutting over namespace referrals, and retiring DFS-R once sync is confirmed healthy.

Last validated on: August 2026
Portal experience note: Steps validated against Azure Portal and Windows Server 2016/2019/2022 as of August 2026. Azure File Sync agent installation requires local administrator rights on each DFS member server.

> **Note:** Azure File Sync is designed for user data volumes, not system data. Do not sync SYSVOL, DFS-R-replicated SYSVOL, or any folder used by Active Directory. Ensure each server endpoint path is on an NTFS-formatted volume.

---

## Module / Track Structure

```text
Migrate Distributed File System (DFS) to Azure File Sync/
├── README.md                              ← Track entry point
└── 1-migrating-dfs-to-azure-file-sync.md ← Lab: Migration walkthrough (you are here)
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Inventory Your DFS Environment](#step-1--inventory-your-dfs-environment)
- [Step 2 — Prepare Azure Resources](#step-2--prepare-azure-resources)
- [Step 3 — Install Azure File Sync Agent](#step-3--install-azure-file-sync-agent)
- [Step 4 — Create Sync Groups](#step-4--create-sync-groups)
- [Step 5 — Monitor Initial Sync](#step-5--monitor-initial-sync)
- [Step 6 — Cut Over DFS Namespace](#step-6--cut-over-dfs-namespace)
- [Step 7 — Enable Cloud Tiering (Optional)](#step-7--enable-cloud-tiering-optional)
- [Step 8 — Retire DFS-R](#step-8--retire-dfs-r)
- [Rollback Plan](#rollback-plan)
- [Validation Checklist](#validation-checklist)
- [Non-Obvious Insights](#non-obvious-insights)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Contributor** on the target subscription or resource group |
| DFS environment | Existing DFS Namespace and/or DFS-R replication topology documented (namespace structure, folder targets, replication groups) |
| Server OS | Windows Server 2016 or later on all DFS member servers (2019/2022 recommended) |
| Azure File Sync agent | Supported on Windows Server 2016, 2019, 2022, 2025 |
| Network | Sufficient outbound bandwidth for initial sync — estimate: data volume ÷ available WAN bandwidth |
| Permissions | Local administrator on each DFS server for agent install; Storage Account Contributor for Azure resource creation |
| Estimated Time | 2–4 hours (lab, small dataset); production migrations vary by data volume and site count |
| Tools | Azure Portal, PowerShell (server-side agent install and validation) |

Naming reference: [Naming Convention](../Naming-Convention.md)

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Inventoried an existing DFS Namespace and DFS-R replication topology
- Created the Azure resources required for Azure File Sync: Storage Account, File Share, Storage Sync Service, and Sync Group
- Registered DFS member servers as server endpoints and completed initial sync to the cloud endpoint
- Monitored sync health via the Azure Portal and the Azure File Sync Operational event log
- Cut over DFS Namespace referrals to Azure File Sync–enabled servers (with two options: keep or retire DFS Namespace)
- Optionally configured cloud tiering to reduce on-premises storage footprint
- Decommissioned DFS-R replication groups cleanly after confirming sync health

---

## 3. Scenario

**An enterprise file server estate using DFS Namespaces and DFS-R for multi-site replication needs to migrate to Azure File Sync to reduce on-premises storage overhead, improve resilience, and align with the organisation's cloud-first strategy.**

DFS-R is being retired as the replication mechanism. Azure File Sync replaces it while DFS Namespaces are retained to minimise user disruption — users continue to access files via `\\domain\dfsroot\share` while the backend is migrated to Azure. Cloud tiering is enabled after cutover to recover local disk space on file servers.

---

## Step 1 — Inventory Your DFS Environment

Before deploying anything, document the current topology. The number of Sync Groups you create maps directly to your DFS folder targets.

Capture the following:

| Item | Detail to record |
| --- | --- |
| DFS Namespace structure | Root namespace paths, folder names, folder target UNC paths |
| Folder targets per namespace | Which servers host each folder target; primary vs. secondary |
| DFS-R replication groups | Group names, member servers, replicated folders, bandwidth schedules |
| Server OS versions | Confirm all member servers meet the Azure File Sync agent OS requirement |
| Total data size | Per share/volume — drives bandwidth planning for initial sync |
| Bandwidth per site | Available WAN bandwidth for each DFS member site |

Use PowerShell to export the current namespace structure:

```powershell
# List all DFS namespaces
Get-DfsnRoot

# List folder targets for a specific namespace
Get-DfsnFolderTarget -Path "\\domain\dfsroot\*"

# List DFS-R replication groups
Get-DfsReplicationGroup
```

### Verify DFS-R Health Before Starting

Confirm DFS-R is in a consistent state before beginning. A replication backlog or conflict will be inherited by the initial sync and must be resolved before migration.

```powershell
# Check replication state for a specific group
dfsrdiag ReplicationState /rgname:"finance-replication-group"

# Check backlog between two replication members
dfsrdiag Backlog /rgname:"finance-replication-group" /rmem:"server01" /rmem:"server02"

# List any preserved (conflicted) files
Get-DfsrPreservedFiles -GroupName "finance-replication-group"
```

If there is a backlog, allow DFS-R to fully replicate before proceeding. Resolve any conflicts manually — Azure File Sync will not auto-resolve DFS-R conflict files.

---

## Step 2 — Prepare Azure Resources

Create the following in the Azure Portal:

1. **Resource Group** — scope all Azure File Sync resources together:
   ```text
   rg-filesync-{region}-{env}    e.g., rg-filesync-eus-lab
   ```

2. **Storage Account** — General Purpose v2, LRS for lab; ZRS or GRS for production. Storage account names cannot contain hyphens:
   ```text
   st{project}filesync{env}01    e.g., stfntechfilesynclablab01
   ```

3. **Azure File Share** — one per DFS folder or per logical grouping:
   - Quota: match current data volume plus growth headroom
   - Tier: Transaction-optimized for migration; Hot or Cool for steady-state

4. **Storage Sync Service** — one per environment:
   ```text
   Portal: search "Azure File Sync" → Create Storage Sync Service
   ```

5. **Configure Storage Account network access** — by default, Storage Accounts allow all networks. For production, restrict to the registered servers' public IPs or deploy a Private Endpoint. For lab, "Allow all networks" (Networking blade default) is acceptable.

6. **Outbound firewall requirements** — each registered server needs outbound HTTPS (port 443) to the following service endpoints:

   | Endpoint | Purpose |
   | --- | --- |
   | `*.afs.azure.net` | Azure File Sync service |
   | `*.core.windows.net` | Azure Storage (file share data) |
   | `login.microsoftonline.com` | Entra ID / Azure AD authentication |
   | `management.azure.com` | Azure Resource Manager |

   TLS 1.2 is enabled by default on Windows Server 2016 and later — no manual configuration required.

> **Note:** Each Storage Sync Service supports up to 30 Sync Groups. If your DFS topology spans multiple Azure regions, plan one Storage Sync Service per region.

---

## Step 3 — Install Azure File Sync Agent

Repeat on every DFS member server that will become a server endpoint.

1. Download the Azure File Sync agent (`StorageSyncAgent.msi`) from the Microsoft Download Center. Match the agent version to the server OS.

2. Run the installer as **local administrator**. Accept defaults.

3. After installation, the **Server Registration** wizard opens automatically:
   - Sign in with an account that has **Owner** or **Contributor** rights on the Storage Sync Service
   - Select **Subscription** → **Resource Group** → **Storage Sync Service** → **Register**

4. Confirm registration in the Portal: **Storage Sync Service** → **Registered servers** — the server should appear with status **Online**.

```powershell
# Verify the Azure File Sync agent service is running
Get-Service -Name FileSyncSvc
```

---

## Step 4 — Create Sync Groups

One Sync Group per DFS folder (or logical data grouping). Each Sync Group contains one **cloud endpoint** (the Azure File Share) and one or more **server endpoints** (local paths on registered servers).

1. In the Portal: **Storage Sync Service** → **Sync groups** → **Add sync group**.

2. Configure the **cloud endpoint**:
   - **Sync group name**: descriptive, matching the DFS folder (e.g., `sg-finance-share`)
   - **Storage account**: select the account from Step 2
   - **Azure file share**: select the corresponding share

3. Add **server endpoints**:
   - Click **Add server endpoint**
   - **Registered server**: select a DFS member server
   - **Path**: the local folder path hosting the DFS-R replicated data (e.g., `D:\shares\finance`)
   - **Cloud tiering**: leave **Disabled** for initial sync — enable after cutover (Step 7)
   - Repeat for each DFS member server in this replication group

Azure File Sync begins initial upload immediately after the server endpoint is saved.

### Large Dataset Pre-Seeding (Recommended for Datasets Over 1 TB)

For large file shares, pre-seeding data into the Azure File Share before creating server endpoints significantly reduces initial sync time and WAN bandwidth consumption. Azure File Sync detects the existing cloud data and performs a delta reconciliation instead of a full upload.

**Option A — Robocopy pre-seed (up to ~1 TB or fast WAN connection):**

1. Mount the Azure File Share on the source DFS server:
   ```powershell
   # Map the Azure File Share as a drive (use storage account key for initial seed)
   net use Z: \\storageaccount.file.core.windows.net\sharename `
       /user:AZURE\storageaccount <storagekey>
   ```

2. Copy data with full NTFS attribute and timestamp preservation:
   ```powershell
   robocopy D:\shares\finance Z:\ /E /COPYALL /DCOPY:DAT /R:3 /W:10 /LOG:C:\logs\preseed-finance.log
   ```

3. After robocopy completes, create the server endpoint (Step 4 above). Azure File Sync will reconcile the local data against the cloud endpoint rather than re-uploading everything.

**Option B — Azure Data Box (datasets over 1–2 TB or constrained WAN):**

Use Azure Data Box to physically ship data to Azure. After the import job completes, enable Azure File Sync on the seeded file share. The service performs a rapid namespace scan to identify differences rather than re-uploading all data.

> **When to choose:** Robocopy is sufficient for datasets under ~1 TB with adequate WAN throughput. Data Box is the right choice when the estimated robocopy transfer time exceeds your migration window.

---

## Step 5 — Monitor Initial Sync

Do not cut over namespace referrals until all server endpoints show healthy sync.

**In the Portal:** navigate to **Storage Sync Service** → **Sync groups** → select a group and check each endpoint's **Sync status**.

- Cloud endpoint: **Up to date**
- Server endpoints: **Healthy**, 0 files pending

**Via Event Viewer on each server:**

```text
Applications and Services Logs → Microsoft → StorageSync → Agent → Telemetry
```

| Event ID | Meaning |
| --- | --- |
| 9102 | Sync session completed — check `PerItemErrorCount` (target: 0) |
| 9121 | Per-item error — investigate the error code |
| 9302 | Sync progress update — shows files transferred |

---

## Step 6 — Cut Over DFS Namespace

Once all server endpoints report **Healthy**, update DFS Namespace referrals.

### Option A — Keep DFS Namespace (recommended)

Update folder target referrals to point to the Azure File Sync–enabled servers. Users continue using their existing `\\domain\dfsroot\share` path.

```powershell
# Remove old DFS-R folder target
Remove-DfsnFolderTarget -Path "\\domain\dfsroot\finance" `
    -TargetPath "\\oldserver\finance"

# Add new Azure File Sync-backed server as folder target
New-DfsnFolderTarget -Path "\\domain\dfsroot\finance" `
    -TargetPath "\\newserver\finance" `
    -State Online
```

### Option B — Retire DFS Namespace

Point users directly to the Azure File Share via SMB (requires network connectivity to the storage account — Private Endpoint or VPN):

```text
\\storageaccount.file.core.windows.net\sharename
```

Most enterprises choose Option A during migration to avoid disrupting mapped drives and application UNC paths.

---

## Step 7 — Enable Cloud Tiering (Optional)

Cloud tiering keeps hot files local and recalls cold files on demand from Azure. Enable per server endpoint after cutover is confirmed stable.

1. In the Portal: **Storage Sync Service** → **Sync groups** → server endpoint → **Properties** → enable **Cloud tiering**.

2. Configure the tiering policy:

| Setting | Recommended value |
| --- | --- |
| Volume free space policy | 20–30% (prevents the local volume from filling completely) |
| Date policy | 30–90 days depending on workload access patterns |

> **Note:** Cloud tiering requires NTFS — ReFS volumes are not supported. Tiered files appear as reparse points locally; opening them triggers a transparent recall from Azure.

---

## Step 8 — Retire DFS-R

Only perform this step after all server endpoints are healthy and namespace referrals have been updated.

1. Remove DFS-R replication group members:

```powershell
# List replication group members
Get-DfsrMember -GroupName "finance-replication-group"

# Remove a member
Remove-DfsrMember -GroupName "finance-replication-group" -ComputerName "oldserver01"
```

2. Delete the replication group once all members are removed:

```powershell
Remove-DfsReplicationGroup -GroupName "finance-replication-group" -RemoveReplicatedFolders
```

3. Remove any remaining legacy folder targets from the DFS Namespace.

4. Decommission old servers if they are no longer needed as sync endpoints or for other workloads.

---

## Rollback Plan

If cutover proves unstable or sync errors emerge after namespace referrals are updated, revert to DFS-R by reversing the cutover steps. The migration is fully reversible until DFS-R replication groups are removed in Step 8 — do not run Step 8 until the migration is confirmed stable.

1. **Re-point DFS Namespace folder targets** to the original DFS-R servers:

   ```powershell
   # Restore original DFS-R server as an active folder target
   New-DfsnFolderTarget -Path "\\domain\dfsroot\finance" `
       -TargetPath "\\originalserver\finance" `
       -State Online

   # Take the Azure File Sync-backed server offline
   Set-DfsnFolderTarget -Path "\\domain\dfsroot\finance" `
       -TargetPath "\\newserver\finance" `
       -State Offline
   ```

2. **Verify users can access files** via the restored DFS-R folder target before removing the Azure File Sync endpoint.

3. **Remove the server endpoint** from the Sync Group if the rollback is permanent (this does not delete data from the server or the cloud endpoint — it stops sync for that path):
   - Portal: **Storage Sync Service** → **Sync groups** → select group → server endpoint → **Delete**

4. **Investigate root cause** before retrying cutover: review Event IDs 9102/9121 on the affected server, check for per-item errors, confirm sufficient bandwidth was available during cutover.

> **Key principle:** DFS-R replication groups are the rollback safety net. Keep them intact and healthy until Step 8.

---

## Validation Checklist

- [ ] DFS-R health confirmed before starting: no backlog, no conflicts (`dfsrdiag ReplicationState`)
- [ ] Outbound firewall rules verified: port 443 open to `*.afs.azure.net`, `*.core.windows.net`, `login.microsoftonline.com`
- [ ] All server endpoints show **Healthy** in the Azure Portal with 0 files pending
- [ ] Cloud endpoint shows **Up to date**
- [ ] Event ID 9102 on each server confirms `PerItemErrorCount = 0`
- [ ] DFS Namespace referrals updated and confirmed: `dfsutil /root:\\domain\dfsroot /view`
- [ ] Users can access files normally via existing UNC paths
- [ ] ACLs and NTFS permissions verified on a sample of migrated files
- [ ] Azure Monitor alert rules configured for sync errors and server heartbeat
- [ ] DFS-R replication groups removed
- [ ] Legacy folder targets removed from DFS Namespace
- [ ] Backup strategy updated to target the Azure File Share
- [ ] Cloud tiering health confirmed (if enabled): tiered files recall successfully on access

---

## Non-Obvious Insights

- **Azure File Sync is multi-master.** Any registered server endpoint can write; changes replicate via the cloud endpoint to all other endpoints. This eliminates DFS-R's hub-spoke topology and its conflict resolution complexity.
- **Keep DFS Namespace.** Only DFS-R is replaced — DFS Namespaces are retained and re-pointed to Azure File Sync–enabled servers. This is the lowest-disruption migration path.
- **Cloud tiering dramatically reduces storage cost** for large, cold datasets. A server with 10 TB of data where only 500 GB is accessed regularly can run on a 1 TB local volume after tiering is enabled.
- **Azure File Sync respects NTFS ACLs, inheritance, and permissions** — no separate ACL migration step is required beyond post-cutover verification.
- **Never sync SYSVOL or system-critical paths.** Azure File Sync is a user data sync service — syncing SYSVOL or AD-managed paths will cause corruption or replication failures.
- **Per-item errors during initial sync are normal** for locked files (open PST files, shadow copy files). Investigate persistent errors via Event ID 9121; transient errors resolve on the next sync session.

---

[← Back to Azure Hands-On Engineering](../README.md)
