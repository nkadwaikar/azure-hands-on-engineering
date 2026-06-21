# Create a Virtual Machine in Azure (Portal Guide)

## 🎯 Purpose

This guide walks you through creating a VM in Azure with consistent steps and naming conventions.
Use it as a reference for labs, demos, or production-aligned builds.

## Track Structure

```text
Compute/
|-- 1-build-base-vm.md
|-- 2-install-iis.md
`-- 3-sysprep-vm.md
```

Flow: build base VM -> install/validate IIS for web workload testing -> sysprep the image source.

## Quick Navigation

- Purpose
- Track Structure
- Create Resource Group
- Create Virtual Machine
- Post-Deployment Steps
- Optional IIS Installation
- Cleanup

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

## 🎉 Base VM is ready for IIS Installation

**Next step:**
➡ [Install IIS](2-install-iis.md)
