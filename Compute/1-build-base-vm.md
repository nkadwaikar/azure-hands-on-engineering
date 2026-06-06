🖥️ Create a Virtual Machine in Azure (Portal Guide)
A reusable reference guide for creating a virtual machine in the Azure Portal using consistent naming, networking, and configuration standards.
---
🎯 Purpose
This guide helps you quickly create a VM in Azure using consistent steps and naming conventions.
Use it as a reference for labs, demos, or production‑aligned builds.
---
1. Create Resource Group
In Azure Portal, search Resource groups → Create
Configure:
Subscription: Your subscription
Resource group: rg-fntech-vm-lab-eus-core
Region: East US
Click Review + Create → Create
---
2. Create Virtual Machine
2.1 Basics Tab
Search Virtual machines → Create → Azure virtual machine
Configure:
Subscription: Your subscription
Resource group: rg-fntech-vm-lab-eus-core
Virtual machine name: vm-fntech-lab-eus-app01
Region: East US
Availability options:
➡️ No infrastructure redundancy required
Security type: Standard
Image: Windows Server 2022 / Ubuntu LTS
VM architecture: x64
Run with Azure Spot discount: Yes
Eviction type: Capacity only
Eviction policy: Stop / Deallocate
Size:
Standard_FX2mds_v2 — 2 vCPUs, 42 GiB RAM ($0.07682/hr)
Administrator account:
Username: your choice
Password or SSH key: set credentials
---
2.2 Disks Tab
OS disk type: Standard SSD (recommended for labs)
Encryption: Default
Leave other settings as default
Ensure Delete with VM checkbox is enabled
---
2.3 Networking Tab
Virtual network: Create new
Name: vnet-fntech-vm-lab-eus-core
Subnet: snet-app
Public IP: Create new
Name: pip-fntech-vm-lab-eus-app01
NIC network security group:
Select Basic
Allow RDP (Windows) or SSH (Linux)
Accelerated networking: Off (for B‑series)
Load balancing: None
Enable: Delete public IP and NIC when VM is deleted
---
2.4 Management Tab
Boot diagnostics: Enable with managed storage
Auto-shutdown: Optional
Monitoring: Enable default metrics
---
2.5 Advanced Tab
Leave defaults unless you need extensions or cloud‑init.
---
2.6 Review + Create
Validate configuration
Click Create
Wait for deployment to complete
Go to Resource → Virtual machine → Overview
---
3. Post‑Deployment Steps
3.1 Connect to VM
Windows: Use RDP → Download RDP file
Linux: Use SSH from terminal or Azure Cloud Shell
---
3.2 Add Inbound NSG Rules (Optional)
To allow HTTP (for IIS or web apps):
Go to VM → Networking → Network security group
Inbound security rules → Add
Configure:
Source: Any
Destination port: 80
Protocol: TCP
Action: Allow
Priority: 1000
Name: Allow-HTTP-80
---
4. Optional: Install IIS (Windows VM)
Run inside the VM (PowerShell as Administrator):
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
$indexPath = "C:\inetpub\wwwroot\index.html"
"Hello from Azure VM - $(Get-Date)" | Out-File -FilePath $indexPath -Encoding utf8

Browse to:
http://<public-ip>

---
5. Cleanup (Optional)
Delete VM
Delete NIC, disk, public IP
Delete resource group: rg-fntech-vm-lab-eus-core
---
✔️ Ready for GitHub
This .md file is clean, structured, and reusable — perfect for your Azure lab repo.
If you want, I can also create:
A Linux‑only version
A Spot‑VM comparison table
A Mermaid diagram showing VM + VNet + NSG
A VMSS version for scale sets

## 🎉 Base VM is ready for Sysprep

**Next step:**  
➡ [Sysprep VM](2-sysprep-vm.md)

