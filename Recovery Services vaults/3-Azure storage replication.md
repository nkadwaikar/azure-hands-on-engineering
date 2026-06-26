# Azure Storage Replication Lab — Step by Step

> **Why this matters:** Choosing the wrong replication tier means either overpaying for durability you don't need or losing data when a datacenter fails — this lab creates storage accounts at LRS, ZRS, GRS, and GZRS so the redundancy trade-offs are directly observable, not theoretical.

Last validated on: 2026-06-10  
Portal experience note: Steps validated against Azure Portal as of June 2026; ZRS, GRS, and GZRS availability varies by region.

> **Note:** Each storage account in this lab incurs separate charges. Delete all accounts when the lab is complete. ZRS, GRS, and GZRS cost more than LRS — this difference is visible in the pricing calculator.

---

## Track Structure

```text
Recovery Services vaults/
|-- 1-VM Backup and Restore Procedure.md
|-- 2-Azure Site Recovery.md
`-- 3-Azure storage replication.md
```

## Quick Navigation

- [Lab Prerequisites](#1-lab-prerequisites)
- [Create LRS Storage Account](#3-create-first-storage-account-lrs)
- [Create a Blob Container](#4-create-a-blob-container-and-upload-a-test-file)
- [Observe LRS Characteristics](#5-observe-lrs-characteristics)
- [Create ZRS Storage Account](#6-create-second-storage-account-zrs)
- [Change Replication Tier](#7-change-replication-tier)
- [Cleanup](#cleanup)

---

## 1. Lab Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Owner** or **Contributor** on the subscription |
| Subscription | Pay-As-You-Go or Visual Studio subscription |
| Estimated Time | 45–60 minutes |
| Tools | Azure Portal; Azure Storage Explorer (optional) |
| Region | Use a primary region that supports ZRS/GRS/GZRS (e.g., East US, West Europe) |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- Lab uses standard Blob storage accounts at different redundancy tiers.
- Object replication, immutability policies, and lifecycle management are out of scope.
- Cost comparison is conceptual; exact pricing varies by region and usage.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- **LRS, ZRS, GRS, and GZRS storage accounts** created and compared side by side
- An understanding of how each tier handles datacenter, zone, and regional failures
- Experience **changing the replication tier** on an existing storage account
- A documented decision framework for choosing the right tier per workload

---

## 3. Scenario

**Match your storage redundancy tier to your actual recovery requirements, not the cheapest default.**

Teams often provision LRS because it is the default, then discover their SLA requires GRS after an incident. This lab creates accounts at each tier, uploads test data, and observes the characteristics of each so the trade-off between cost and durability is concrete.

---

---

## 2. Create a Resource Group

1. Go to **Resource groups** → **+ Create**.
2. **Subscription:** your lab subscription.
3. **Resource group name:** `rg-fntech-eus-lab-repl`
4. **Region:** choose a primary region (e.g., East US).
5. Click **Review + create** → **Create**.

---

## 3. Create First Storage Account (LRS)

1. Search **Storage accounts** → **+ Create**.
2. **Subscription:** your lab subscription.
3. **Resource group:** `rg-fntech-eus-lab-repl`
4. **Storage account name:** `stfntechlabrepl01` (must be globally unique).
5. **Region:** same as RG (e.g., East US).
6. **Primary service:** Azure Blob Storage or Azure Data Lake Storage
7. **Performance:** Standard.
8. **Redundancy:** Locally redundant storage (LRS).
9. Leave other defaults, click **Review + create** → **Create**.

---

## 4. Create a Blob Container and Upload a Test File

1. Open `stfntechlabrepl01`.
2. In left menu, select **Containers** → **+ Container**.
3. **Name:** `testdata`
4. **Public access level:** Private (no anonymous access).
5. Click **Create**.
6. Open the `testdata` container → click **Upload**.
7. Upload a small file, e.g., `sample-lrs.txt` with text like "LRS test file".
8. Confirm the blob appears in the container.

---

## 5. Observe LRS Characteristics

1. In the storage account, go to **Data Management**.
2. Confirm **Redundancy = LRS**.
3. Note:
   - Data is replicated within a single datacenter in the region.
   - No secondary region, no read-access secondary endpoint.

> **LRS = cheapest, single datacenter durability, no cross-region protection.**

---

## 6. Create Second Storage Account (ZRS)

1. **Storage accounts** → **+ Create** again.
2. **Resource group:** `rg-fntech-eus-lab-repl`
3. **Storage account name:** `stfntechlabrepl02`
4. **Region:** choose a region that supports ZRS and GZRS (e.g., West Europe or East US 2, depending on availability).
5. **Performance:** Standard.
6. **Redundancy:** Zone redundant storage (ZRS).
7. Click **Review + create** → **Create**.

> This account will be used to explore ZRS → GZRS → RA GZRS (or ZRS → GRS → RA GRS, depending on region support).

---

## 7. Test ZRS Behavior

1. Open `stfntechlabrepl02`.
2. Go to **Data Management** and confirm **Redundancy = ZRS**.
3. Create a container `testzrs` and upload a file `sample-zrs.txt`.

> **ZRS = data replicated across availability zones in a region. Protects against zone failure, but not regional outage.**

---

## 8. Change Redundancy to GRS / GZRS

> **Note:** Not all transitions are allowed in all regions. If a specific path is blocked, document it as a "limitation observed."

1. In `stfntechlabrepl02`, go to **Configuration**.
2. Under **Redundancy**, click **Upgrade** (or change) if available.
3. Try changing:
   - From ZRS → GZRS (if supported), or
   - From ZRS → GRS (if that's the available path).
4. Click **Save** and wait for the change to complete.

**Document:**

- Which transitions were allowed (e.g., ZRS → GZRS).
- Which were blocked, including any error message shown (e.g., the ZRS → GRS option may be grayed out).

---

## 9. Create Third Storage Account and Enable Read Access (RA GZRS / RA GRS)

> **Note:** A third storage account (`stfntechlabrepl03`) is needed for this step, to keep the failover test in Step 11 independent.

### 9a. Create `stfntechlabrepl03`

1. **Storage accounts** → **+ Create**.
2. **Resource group:** `rg-fntech-eus-lab-repl`
3. **Storage account name:** `stfntechlabrepl03`
4. **Region:** same region used for `stfntechlabrepl02`.
5. **Performance:** Standard.
6. **Redundancy:** Zone redundant storage (ZRS) or GZRS if available.
7. Click **Review + create** → **Create**.

### 9b. Enable Read Access

1. In `stfntechlabrepl03`, go to **Configuration**.
2. Under **Redundancy**, click **Upgrade** (or change) to:
   - Read-access geo-zone-redundant storage (RA GZRS), or
   - Read-access geo-redundant storage (RA GRS) — depending on what's available.
3. Click **Save**.
4. After it completes, go to **Endpoints**.
5. Note both endpoints:
   - Primary: `https://stfntechlabrepl03.blob.core.windows.net`
   - Secondary: `https://stfntechlabrepl03-secondary.blob.core.windows.net`

---

## 10. Validate RA GRS / RA GZRS Read Access

### 10.1 Using Azure Storage Browser (Recommended)

1. Open **Azure Storage Browser**.
2. Sign in with your Azure account.
3. Expand **Storage Accounts** → `stfntechlabrepl03` → **Blob Containers**.
4. Locate the container created in `stfntechlabrepl03`.
5. In the account tree, you should see both (primary) and (secondary) endpoints.
6. Try browsing the container via the secondary endpoint.
7. Confirm you can read (download or open) the blob, but cannot write to it.

### 10.2 Using SAS URL (Optional)

1. Generate a read-only SAS for the blob.
2. Modify the URL to use the `-secondary` endpoint.
3. Access it in a browser and confirm it works.

> **RA GRS / RA GZRS = read-only access to the secondary region; useful for reporting, analytics, or DR testing.**

---

## 11. Trigger a Manual Geo-Failover (GRS / GZRS Only)

> ⚠️ **Warning:** Geo-failover is one-way and irreversible. Use only in a lab storage account with no important data.

1. In `stfntechlabrepl02`, go to **Geo-replication** (under Settings).
2. Review:
   - Primary region
   - Secondary region
   - Replication status
3. Click **Initiate account failover** (wording may vary).
4. Confirm the warning about data loss and irreversibility.
5. Proceed with the failover.

**Azure will:**

- Promote the secondary region to primary.
- Update endpoints so that the former secondary becomes the new primary.

---

## 12. Validate After Failover

1. After failover completes, go back to **Overview** and **Geo-replication**.
2. Confirm:
   - The primary region is now what used to be the secondary.
   - The old primary region is no longer active.
3. Go to **Containers** → `testzrs` and confirm the blob still exists.
4. Download the blob and verify its content.

> **Manual failover simulates a regional outage scenario. RPO depends on replication lag at the time of failover.**

---

## 13. Summary: When to Use Each Redundancy Type

| Type | Scope | Notes |
| ------ | ------- | ------- |
| **LRS** | Single region, single datacenter | Lowest cost; no cross-zone or cross-region protection. |
| **ZRS** | Single region, multi-zone | Protects against zone failure; no secondary region. |
| **GRS** | Cross-region | Asynchronous replication to secondary; no read access to secondary. |
| **RA GRS** | Cross-region + read | Same as GRS but secondary endpoint is readable. |
| **GZRS** | Zone + cross-region | Combines ZRS zone resilience with GRS regional protection. |
| **RA GZRS** | Zone + cross-region + read | Highest durability; secondary endpoint is readable. Best for critical workloads. |

---

## 14. Cleanup

1. Delete blobs to reduce any ongoing egress costs.
2. Delete storage accounts:
   - `stfntechlabrepl01`
   - `stfntechlabrepl02`
   - `stfntechlabrepl03`
3. Delete resource group: `rg-fntech-eus-lab-repl`
