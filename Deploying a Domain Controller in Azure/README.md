# Deploying a Domain Controller in Azure

Last validated on: July 2026

This track covers deploying a production-ready Active Directory Domain Services (AD DS) environment in Azure — two domain controllers on Windows Server 2022, secured with Azure Bastion (no public IPs), resilient across an Availability Set, and integrated with Azure Key Vault, Azure Monitor, and Azure Backup.

## Track Structure

```text
Deploying a Domain Controller in Azure/
└── 1-deploying-domain-controller-in-azure.md
```

## Lab Sequence

1. [Deploying a Domain Controller in Azure](1-deploying-domain-controller-in-azure.md)

   | Step | What It Covers |
   | --- | --- |
   | 1. Create a Resource Group | Resource group scoped to the DC lab (`rg-addc-lab`) |
   | 2. Set Up Networking | VNet + subnet creation, Azure Bastion (no public IPs on DCs), NSG with AD DS port rules, optional VPN/ExpressRoute extension to on-prem |
   | 3. Availability Set / Zones | Fault tolerance options (Availability Set vs. Zones) for two domain controllers |
   | 4. Deploy Virtual Machines | Windows Server 2022 VMs, no public IP, dedicated data disk (host caching: None), static private IPs |
   | 5. Install AD DS Role | Server Manager role installation on both VMs |
   | 6. Promote First DC | New forest creation via wizard or PowerShell (`Install-ADDSForest`), DSRM password in Key Vault, paths on dedicated data disk, DNS configuration, Azure DNS conditional forwarder, VNet DNS server update |
   | 7. Promote Second DC | Add to existing domain, verify automatic AD DS replication with `repadmin`/`dcdiag`, DNS client settings, FSMO role distribution |
   | 8. Secure the Environment | Strong passwords, Bastion-only access, AV/Defender exclusions for NTDS and SYSVOL, Azure Key Vault for DSRM secrets |
   | 9. Test and Monitor | Replication validation, Azure Monitor / VM Insights, PerfMon AD DS counters, time sync, Azure Backup |
   | 10. Errors and Troubleshooting | Common failure table: DNS misconfiguration, `dcpromo` removal, dynamic IP change, host caching corruption, Kerberos clock skew |

## Prerequisites

- Azure subscription with **Owner** or **Contributor** rights on the target subscription
- Outbound HTTPS (port 443) from the deployment machine to Azure endpoints
- Azure Portal access and Azure CLI or PowerShell (Az module) installed

---

[← Back to Azure Hands-On Engineering](../README.md)
