# Recovery Services Vaults Track

Last validated on: July 2026

[![Duration](https://img.shields.io/badge/Duration-2--3%20hours-0A66C2?style=flat-square)](#lab-sequence)
[![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-0052CC?style=flat-square)](#lab-sequence)

This track covers the full Azure resilience stack — VM backup and restore, cross-region replication with Azure Site Recovery, and storage-level redundancy options.

## Track Structure

```text
Recovery Services vaults/
|-- 1-vm-backup-restore.md
|-- 2-azure-site-recovery.md
`-- 3-azure-storage-replication.md
```

Flow: configure VM backup → set up site recovery replication → validate storage replication tiers.

## Lab Sequence

1. [VM Backup and Restore](1-vm-backup-restore.md) — configure Enhanced backup policy, perform file-level recovery and full VM restore
2. [Azure Site Recovery](2-azure-site-recovery.md) — replicate a VM to a secondary region and validate failover readiness
3. [Azure Storage Replication](3-azure-storage-replication.md) — compare LRS, ZRS, GRS, and GZRS replication options

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- A running VM to protect (see [Compute track](../Compute/README.md))
- Recovery Services vault created in the target region

---

[← Back to Azure Hands-On Engineering](../README.md)
