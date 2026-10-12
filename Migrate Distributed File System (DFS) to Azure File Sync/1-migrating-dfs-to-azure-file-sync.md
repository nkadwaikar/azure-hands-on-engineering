# Migrating DFS to Azure File Sync

> **Why this matters:** DFS-R deployments can develop replication backlogs and conflict files that require operational monitoring and resolution. Azure File Sync provides a cloud-backed, multi-site sync model, optional cloud tiering to reduce on-premises storage needs, and Azure Monitor integration. DFS Namespaces can remain in place to preserve users' UNC paths during the migration.

This guide walks through a production-aligned migration from DFS Namespaces and DFS-R replication to Azure File Sync — inventorying the existing topology, deploying Azure resources, syncing data, cutting over namespace referrals, and retiring DFS-R once sync is confirmed healthy.

Last validated on: October 2026
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
| .NET Framework | Version 4.7.2 or later on Windows Server 2016; included by default on Windows Server 2019 and later |
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

Before deploying anything, document the current topology. Plan Sync Groups around Azure file shares: a share can map to one DFS folder or to a logical grouping of folders, subject to Azure File Sync scale limits.

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
dfsrdiag Backlog /rgname:"finance-replication-group" /rfname:"finance" /smem:"server01" /rmem:"server02"

# List conflicted/deleted files for a replicated folder
Get-DfsrPreservedFiles -Path 'D:\shares\finance\DfsrPrivate\ConflictAndDeletedManifest.xml'
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

5. **Configure Storage Account network access** — "Allow all networks" is acceptable for a lab. For production, use a supported firewall, virtual network, or Private Endpoint configuration. When restricting network access, allow the registered servers or their virtual network as appropriate, enable **Allow trusted Microsoft services to access this storage account**, and configure private DNS and routing for Private Endpoints.

6. **Outbound firewall requirements** — Azure File Sync initiates outbound connections and transfers sync data over HTTPS on port 443. The exact allowlist depends on the Azure cloud, service region, storage redundancy, and agent update configuration; this table is not a complete firewall allowlist. Use Microsoft's [current firewall and proxy requirements](https://learn.microsoft.com/en-us/azure/storage/file-sync/file-sync-firewall-and-proxy) for all required regional, authentication, certificate, and update endpoints.

   | Endpoint | Purpose |
   | --- | --- |
   | `*.afs.azure.net`, `*.one.microsoft.com` | Azure File Sync service |
   | `*.core.windows.net` | Azure Storage (file share data) |
   | `login.microsoftonline.com`, `login.windows.net`, `graph.microsoft.com` | Entra ID authentication and service principal |
   | `management.azure.com` | Azure Resource Manager |

   TLS 1.2 is enabled by default on Windows Server 2016 and later — no manual configuration required.

> **Note:** A Storage Sync Service supports up to 200 Sync Groups. A server supports up to 30 server endpoints. If your topology spans Azure regions, plan Storage Sync Services and Azure file shares in matching regions.
> **Important:** Azure File Sync requires **Allow storage account key access** to be enabled on the storage account. Avoid using account keys for routine user access; configure identity-based SMB authentication for direct share access.

After registration, validate connectivity with `Test-StorageSyncNetworkConnectivity` from the server.

---

## Step 3 — Install Azure File Sync Agent

Repeat on every DFS member server that will become a server endpoint.

1. Download the Azure File Sync agent (`StorageSyncAgent.msi`) from the Microsoft Download Center. Match the agent version to the server OS.

2. Run the installer as **local administrator**. Accept defaults.

3. After installation, the **Server Registration** wizard opens automatically:
   - Sign in with an account that has **Azure File Sync Administrator**, **Owner**, or **Contributor** rights on the Storage Sync Service
   - Select **Subscription** → **Resource Group** → **Storage Sync Service** → **Register**

4. Confirm registration in the Portal: **Storage Sync Service** → **Registered servers** — the server should appear with status **Online**.

```powershell
# Verify the Azure File Sync agent service is running
Get-Service -Name FileSyncSvc
```

---

## Step 4 — Create Sync Groups

One Sync Group per Azure file share (which may represent one DFS folder or a logical grouping). Each Sync Group contains one **cloud endpoint** and one or more **server endpoints**. Migrate one full-data server first; do not add the other DFS-R members as server endpoints until DFS-R is disabled.

> **Pre-seeding instead?** Complete the optional pre-seeding procedure below before adding the first server endpoint. It requires a write outage and replaces the normal initial-upload sequence.

1. In the Portal: **Storage Sync Service** → **Sync groups** → **Add sync group**.

2. Configure the **cloud endpoint**:
   - **Sync group name**: descriptive, matching the DFS folder (e.g., `sg-finance-share`)
   - **Storage account**: select the account from Step 2
   - **Azure file share**: select the corresponding share

3. For a normal initial upload, add a **server endpoint** for the DFS-R member that has the full, consistent dataset:
   - Click **Add server endpoint**
   - **Registered server**: select the member with the full dataset
   - **Path**: the local folder path hosting the DFS-R replicated data (e.g., `D:\shares\finance`)
   - **Cloud tiering**: leave **Disabled** during migration

4. Let the first server endpoint upload its data and confirm its sync is healthy before proceeding.

5. Disable DFS-R for the replication group before creating endpoints on the remaining DFS-R members. Coordinate this transition so changes are not being independently replicated by DFS-R while Azure File Sync establishes the remaining endpoints.

6. Add a server endpoint for each remaining DFS-R member, using the corresponding local data path. Keep cloud tiering disabled on all endpoints until DFS-R has been retired.

7. Let the endpoints reconcile and confirm that each is healthy before proceeding to cutover.

> **Important:** Microsoft supports only one Azure File Sync server endpoint overlapping a DFS-R location during migration. Disable DFS-R before adding the other server endpoints. Do not use DFS-R read-only replicated folders as server endpoints, and keep cloud tiering disabled on volumes containing DFS-R-replicated folders.

### Optional Pre-Seeding (Downtime Required)

Pre-seeding can reduce file-data transfer, but Azure File Sync still scans the cloud namespace and the overall onboarding can take longer. Microsoft recommends this approach only when you can accept downtime. Use it as an alternative to the normal initial-upload sequence: pause writes from all clients and disable DFS-R before copying data, then keep writes paused until the server endpoints have reconciled. Do not add the first server endpoint until the cloud share has been seeded.

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

3. After robocopy completes, return to Step 4 and add the first server endpoint. Keep DFS-R disabled and writes paused while Azure File Sync reconciles the data and until all endpoints are healthy.

**Option B — Azure Data Box (datasets over 1–2 TB or constrained WAN):**

Use Azure Data Box to physically ship data to Azure. After the import job completes, create the cloud endpoint and follow the same paused-write procedure: add the first server endpoint, let Azure File Sync scan and reconcile the seeded namespace, then add the remaining endpoints.

> **When to choose:** Use Robocopy or Data Box only when the required write outage is acceptable and the transfer method fits the migration window. Otherwise, use the normal initial-upload sequence.

---

## Step 5 — Monitor Initial Sync

Do not cut over namespace referrals until all server endpoints show healthy sync.

**In the Portal:** navigate to **Storage Sync Service** → **Sync groups** → select a group and check each endpoint's **Sync status**.
**In the Portal:** navigate to **Storage Sync Service** → **Sync groups** → select a group and check endpoint health, sync activity, and persistent/transient sync-error counts.

- Cloud endpoint: **Up to date**
- Server endpoints: **Healthy**, 0 files pending
- Server endpoints: **Healthy**, with no persistent or transient sync errors and no remaining migration backlog

**Via Event Viewer on each server:**

```text
Applications and Services Logs → Microsoft → FileSync → Agent → Telemetry
```

| Event ID | Meaning |
| --- | --- |
| 9102 | Sync session completed — check `HResult = 0` and `PerItemErrorCount = 0` |
| 9121 | Per-item error — investigate the error code |
| 9302 | Sync progress update — shows files transferred |

---

## Step 6 — Cut Over DFS Namespace

Once all server endpoints report **Healthy**, update DFS Namespace referrals. Add and validate the Azure File Sync-backed target first; remove the old target only after the new target is available to clients and referral caches have had time to update.

### Option A — Keep DFS Namespace (recommended)

Add and validate an Azure File Sync-backed folder target before removing the old DFS-R target. After the new target is available and referral caches have updated, users can continue using their existing `\\domain\dfsroot\share` path.

```powershell
# Add and validate the new Azure File Sync-backed server first
New-DfsnFolderTarget -Path "\\domain\dfsroot\finance" `
    -TargetPath "\\newserver\finance" `
    -State Online

# Remove the old DFS-R target after the new target is available
Remove-DfsnFolderTarget -Path "\\domain\dfsroot\finance" `
   -TargetPath "\\oldserver\finance"
```

### Option B — Retire DFS Namespace

Point users directly to the Azure File Share via SMB only after configuring an identity source (AD DS, Microsoft Entra Domain Services, or Microsoft Entra Kerberos), share-level permissions, and file/directory ACLs. Clients also need SMB network access to the share (typically TCP 445); use a Private Endpoint with VPN or ExpressRoute when required by the network design.

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

1. Delete the replication group once all members are removed:

```powershell
Remove-DfsReplicationGroup -GroupName "finance-replication-group" -RemoveReplicatedFolders
```

1. Remove any remaining legacy folder targets from the DFS Namespace.

1. Decommission old servers if they are no longer needed as sync endpoints or for other workloads.

---

## Rollback Plan

If cutover proves unstable or sync errors emerge after namespace referrals are updated, revert to DFS-R only after ensuring the original DFS-R servers contain a consistent copy of the latest data. DFS-R is disabled during migration, so do not simply re-enable it against stale copies. Keep the DFS-R replication groups and data until the migration is confirmed stable; do not run Step 8 before then.

1. **Pause writes and remove the Azure File Sync-backed targets from referrals** while you prepare the rollback. Identify the authoritative, current copy of the data.

2. **Reconcile the original DFS-R servers** with that current copy and verify that the data is consistent across all DFS-R members before re-enabling DFS-R.

3. **Re-point DFS Namespace folder targets** to the original DFS-R servers:

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

4. **Verify users can access files** via the restored DFS-R folder target before removing the Azure File Sync endpoint.

5. **Deprovision the server endpoint only if rollback is permanent.** Deleting an endpoint is destructive: unsynced changes or tiered files can be lost or become inaccessible. Follow Microsoft's [server endpoint deprovisioning procedure](https://learn.microsoft.com/en-us/azure/storage/file-sync/file-sync-server-endpoint-delete): stop writes and remove user access, complete and verify the final upload, and, if the server must retain a full local copy, disable cloud tiering and recall all tiered files before deletion. In the Portal, select **Storage Sync Service** → **Sync groups** → the server endpoint → **Delete**.

6. **Investigate root cause** before retrying cutover: review Event IDs 9102/9121 on the affected server, check for per-item errors, confirm sufficient bandwidth was available during cutover.

> **Key principle:** DFS-R replication groups are the rollback safety net. Keep them intact and healthy until Step 8.

---

## Validation Checklist

- [ ] DFS-R health confirmed before starting: no backlog, no conflicts (`dfsrdiag ReplicationState`)
- [ ] Outbound firewall rules verified against the current Azure File Sync firewall requirements; `Test-StorageSyncNetworkConnectivity` succeeds on each server
- [ ] All server endpoints show **Healthy**, with no persistent or transient errors and recent successful upload/download sessions
- [ ] Cloud endpoint shows **Up to date**
- [ ] Event ID 9102 on each server confirms `HResult = 0` and `PerItemErrorCount = 0` for the final upload/download sessions
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

- **Azure File Sync is multi-master, not conflict-free.** Any server endpoint can accept writes, but concurrent changes to the same file can create conflict copies. The latest write keeps the original name; the older version is renamed with the endpoint name. Monitor and resolve conflicts as part of normal operations.
- **Keep DFS Namespace.** Only DFS-R is replaced — DFS Namespaces are retained and re-pointed to Azure File Sync–enabled servers. This is the lowest-disruption migration path.
- **Cloud tiering dramatically reduces storage cost** for large, cold datasets. A server with 10 TB of data where only 500 GB is accessed regularly can run on a 1 TB local volume after tiering is enabled.
- **Azure File Sync respects NTFS ACLs, inheritance, and permissions** — no separate ACL migration step is required beyond post-cutover verification.
- **Never sync SYSVOL or system-critical paths.** Azure File Sync is a user data sync service — syncing SYSVOL or AD-managed paths will cause corruption or replication failures.
- **Open files can cause transient per-item errors.** Check Event ID 9121 and distinguish transient errors, which can clear on a later sync session, from persistent errors that need remediation.

---

[← Back to Azure Hands-On Engineering](../README.md)
