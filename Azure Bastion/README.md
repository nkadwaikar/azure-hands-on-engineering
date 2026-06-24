# Azure Bastion Track

This track covers secure VM access using Azure Bastion — connecting to virtual machines over a browser-based RDP/SSH session without exposing public IPs, configuring Just-In-Time access, and retrieving credentials from Azure Key Vault.

## Track Structure

```text
Azure Bastion/
`-- 1-Azure Bastion.md
```

## Lab Sequence

1. [Azure Bastion — Secure VM Access](1-Azure%20Bastion.md) — deploy Bastion, connect to a VM without a public IP, integrate with Azure Key Vault for credential retrieval, compare Bastion against Jumpbox and Private Endpoint patterns, and configure VNet Peering for cross-VNet Bastion access

> **JIT VM Access** has moved to the [Microsoft Defender for Cloud track](../Microsoft%20Defender%20for%20Cloud/Readme.md).

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- An existing VM deployed in a VNet with a private IP
- Azure Portal access
- A Key Vault instance (for the secretless access pattern)

## Key Concepts Covered

| Concept | Description |
| --- | --- |
| Azure Bastion | Browser-based RDP/SSH proxy — no public IP on the VM required |
| AzureBastionSubnet | Dedicated `/26` subnet required for Bastion deployment |
| Key Vault Integration | Retrieve VM credentials from Key Vault instead of hardcoding them |
| Just-In-Time (JIT) Access | Time-boxed NSG rule opening via Microsoft Defender for Cloud |
| Bastion vs Jumpbox | Managed browser access vs self-managed VM proxy |
| Private Endpoint | Private PaaS connectivity — complementary but distinct from Bastion |
| VNet Peering | Hub-to-spoke peering required when Bastion and VM are in separate VNets |

---

[← Back to Azure Hands-On Engineering](../README.md)
