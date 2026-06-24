# Azure Bastion Track

This track covers secure VM access using Azure Bastion — connecting to virtual machines over a browser-based RDP/SSH session without exposing public IPs, retrieving credentials from Azure Key Vault, and configuring VNet Peering for cross-VNet access.

## Track Structure

```text
Azure Bastion/
`-- 1-Azure Bastion.md
```

## Lab Sequence

1. [Azure Bastion — Secure VM Access](1-Azure%20Bastion.md)

   | Section | What It Covers |
   | --- | --- |
   | 1. Prerequisites | Subnet, NSG, VM, and Key Vault requirements |
   | 2. Deploy Azure Bastion | Create resource group, `AzureBastionSubnet`, Bastion resource, and required NSG rules |
   | 3. Connect to the VM | Browser-based RDP/SSH via the VM blade |
   | 4. Troubleshooting | Real-world fixes: missing button, black screen, permission errors, subnet sizing |
   | 5. Why Bastion Matters | Engineering justification: no public IP, no jumpbox, full audit trail |
   | 6. Key Vault Integration | Retrieve VM credentials from Key Vault (secretless access pattern) |
   | 7. Access Diagram | TLS flow: browser → Bastion public IP → VM private IP |
   | 8. Bastion vs Jumpbox vs Private Endpoint | Side-by-side comparison with cost, complexity, and use-case guidance |
   | 9. Cleanup / Teardown | Delete Bastion, public IP, subnet, and optionally the full resource group |
   | 10. VNet Peering | Hub-to-spoke peering for cross-VNet Bastion access; explains automatic reverse peering |

> **JIT VM Access** has moved to the [Microsoft Defender for Cloud track](../Microsoft%20Defender%20for%20Cloud/Readme.md).

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- An existing VM deployed in a VNet with a private IP (no public IP required)
- Azure Portal access
- A Key Vault instance (for the secretless access pattern)
- If attaching an NSG to `AzureBastionSubnet`: inbound rules for `Internet → 443`, `GatewayManager → 443`, `AzureLoadBalancer → 443`; outbound rules for `VirtualNetwork → 3389/22` and `AzureCloud → 443`

## Key Concepts Covered

| Concept | Description |
| --- | --- |
| Azure Bastion | Browser-based RDP/SSH proxy — no public IP on the VM required |
| AzureBastionSubnet | Dedicated `/26` subnet required; must be named exactly `AzureBastionSubnet` |
| Bastion Tiers | `Basic` for standard RDP/SSH; `Standard` for IP-based connection and tunneling |
| NSG Rules | Specific inbound/outbound rules required on the Bastion subnet if an NSG is attached |
| Key Vault Integration | Retrieve VM credentials from Key Vault instead of hardcoding them |
| Just-In-Time (JIT) Access | Time-boxed NSG rule opening via Microsoft Defender for Cloud |
| Bastion vs Jumpbox | Managed browser access vs self-managed VM proxy |
| Private Endpoint | Private PaaS connectivity — complementary but distinct from Bastion |
| VNet Peering | Hub-to-spoke peering required when Bastion and VM are in separate VNets |
| Automatic Reverse Peering | Azure creates the spoke→hub peering automatically when both VNets share the same subscription/tenant |

---

[← Back to Azure Hands-On Engineering](../README.md)
