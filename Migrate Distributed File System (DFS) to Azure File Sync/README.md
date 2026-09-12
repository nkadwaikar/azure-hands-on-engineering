# Migrate DFS to Azure File Sync

Last validated on: August 2026

[![Duration](https://img.shields.io/badge/Duration-2--3%20hours-0A66C2?style=flat-square)](#lab-sequence)
[![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate%20to%20Advanced-0052CC?style=flat-square)](#lab-sequence)

This track covers migrating an enterprise DFS Namespace and DFS-R replication topology to Azure File Sync — replacing DFS-R as the replication mechanism while retaining DFS Namespaces to minimise user disruption. Cloud tiering is configured post-cutover to reduce on-premises storage footprint.

## Track Structure

```text
Migrate Distributed File System (DFS) to Azure File Sync/
├── README.md                              ← Track entry point (you are here)
└── 1-migrating-dfs-to-azure-file-sync.md ← Lab: End-to-end migration walkthrough
```

## Lab Sequence

1. [Migrating DFS to Azure File Sync](1-migrating-dfs-to-azure-file-sync.md) — inventory DFS topology, deploy Storage Sync Service and Sync Groups, sync data, cut over namespace referrals, enable cloud tiering, and retire DFS-R

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- Existing DFS Namespace and/or DFS-R replication topology to migrate
- Windows Server 2016 or later on all DFS member servers
- Documented namespace structure, folder targets, and replication groups before starting

## Related Tracks

- [Compute Track](../Compute/README.md) — Windows Server VM provisioning and lifecycle management
- [Azure Arc Track](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) — extend Azure management to on-premises file servers
- [Deploying a Domain Controller in Azure](../Deploying%20a%20Domain%20Controller%20in%20Azure/README.md) — Azure-hosted AD DS for DFS Namespace infrastructure

---

[← Back to Azure Hands-On Engineering](../README.md)
