# Create a Virtual Machine in Azure (Portal Guide)

> **Why this matters:** Every higher-level Azure compute pattern — golden images, scale sets, web workloads — traces back to a single VM provisioned consistently; this lab establishes the baseline build with naming conventions, security settings, and post-deployment validation that all subsequent labs depend on.

This guide walks you through creating a VM in Azure with consistent steps and naming conventions, and establishes the baseline build that all subsequent compute labs depend on.

Last validated on: 2026-06-19  
Portal experience note: Steps validated against Azure Portal as of June 2026; labels can vary slightly by region and feature rollout.

> **Note:** All resources created in this lab feed into the Sysprep and VMSS track. Delete the resource group when the full Compute track is complete to avoid ongoing charges.

---

## Track Structure

```text
Compute/
|-- 1-build-base-vm.md
|-- 2-sysprep-vm.md
`-- 3-Install IIS.md
```

Flow: build base VM -> sysprep the image source -> install/validate IIS for web workload testing.

## Quick Navigation

- [Prerequisites](#prerequisites)
- [Create Resource Group](#1-create-resource-group)
- [Create Virtual Machine](#2-create-virtual-machine)
- [Post-Deployment Steps](#3-post-deployment-steps)
- [Optional: Install IIS](#4-optional-install-iis-windows-vm)
- [Cleanup](#5-cleanup-optional)

---

## Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Owner** or **Contributor** on the subscription |
| Subscription | Pay-As-You-Go or Visual Studio subscription |
| Estimated Time | 20–30 minutes |
| Tools | Azure Portal only |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- This VM is the starting point for the Sysprep and VMSS track.
- Lab uses Windows Server 2022; Linux steps differ and are not covered.
- Networking defaults (auto-created VNet/subnet) are used unless otherwise noted.

---

## Learning Objectives

By the end of this lab, you will have:

- A **Windows Server VM** created with consistent naming and region conventions
- **Post-deployment validation** completed (boot diagnostics, OS access confirmed)
- **IIS optionally installed** to provide a web workload for image capture and VMSS testing
- The VM ready for the **Sysprep** step that enables image capture

---

## Scenario

**Establish a consistent, repeatable VM baseline before any customization is applied.**

Skipping this step and jumping straight to custom images means baking untested configurations into every instance at scale. This lab provisions the source VM that becomes the golden image: same name pattern, same settings, same validation checklist — so every downstream lab starts from a known-good state.

---

## 1. Create Resource Group

In Azure Portal, search **Resource groups** → **Create**

Configure:

- **Subscription:** Your subscription
- **Resource group:** `rg-fntech-vm-lab-eus-core`
- **Region:** East US

Click **Review + Create** → **Create**

---

## 2. Create Virtual Machine

### 2.1 Basics Tab

Search **Virtual machines** → **Create** → **Azure virtual machine**

Configure:

- **Subscription:** Your subscription
- **Resource group:** `rg-fntech-vm-lab-eus-core`
- **Virtual machine name:** `vm-fntech-eus-lab-app01`
- **Region:** East US
- **Availability options:** No infrastructure redundancy required
- **Security type:** Standard
- **Image:** Windows Server 2022 / Ubuntu LTS
- **VM architecture:** x64
- **Run with Azure Spot discount:** No
- **Size:** Standard_B2s — 2 vCPUs, 4 GiB RAM
- **Administrator account:**
  - **Username:** your choice
  - **Password or SSH key:** set credentials

---

### 2.2 Disks Tab

- **OS disk type:** Standard SSD (recommended for labs)
- **Encryption:** Default
- Leave other settings as default
- Ensure **Delete with VM** checkbox is enabled

---

### 2.3 Networking Tab

- **Virtual network:** Create new
  - **Name:** `vnet-fntech-vm-lab-eus-core`
  - **Subnet:** `snet-app`
- **Public IP:** Create new
  - **Name:** `pip-fntech-eus-lab-vm`
- **NIC network security group:**
  - Select **Basic**
  - Allow RDP (Windows) or SSH (Linux)
- **Accelerated networking:** Off (for B-series)
- **Load balancing:** None
- Enable: **Delete public IP and NIC when VM is deleted**

---

### 2.4 Management Tab

- **Boot diagnostics:** Enable with managed storage
- **Auto-shutdown:** Optional
- **Monitoring:** Enable default metrics

---

### 2.5 Advanced Tab

Leave defaults unless you need extensions or cloud-init.

---

### 2.6 Review + Create

- Validate configuration
- Click **Create**
- Wait for deployment to complete
- Go to **Resource** → **Virtual machine** → **Overview**

---

## 3. Post-Deployment Steps

### 3.1 Connect to VM

- **Windows:** Use RDP → Download RDP file
- **Linux:** Use SSH from terminal or Azure Cloud Shell

---

### 3.2 Add Inbound NSG Rules (Optional)

To allow HTTP (for IIS or web apps):

1. Go to **VM** → **Networking** → **Network security group**
2. **Inbound security rules** → **Add**
3. Configure:
   - **Source:** Any
   - **Destination port:** 80
   - **Protocol:** TCP
   - **Action:** Allow
   - **Priority:** 1000
   - **Name:** `Allow-HTTP-80`

---

## 4. Optional: Install IIS (Windows VM)

Run inside the VM (PowerShell as Administrator):

```powershell
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

$indexPath = "C:\inetpub\wwwroot\index.html"
"Hello from Azure VM - $(Get-Date)" | Out-File -FilePath $indexPath -Encoding utf8
```

Browse to:

```text
http://<public-ip>
```

---

## 5. Cleanup (Optional)

- Delete VM
- Delete NIC, disk, public IP
- Delete resource group: `rg-fntech-vm-lab-eus-core`

---

> **Next step:** [Sysprep the VM](2-sysprep-vm.md)
