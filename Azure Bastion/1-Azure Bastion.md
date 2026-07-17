# Azure Bastion — Secure VM Access (No Public IP)

Azure Bastion lets you RDP/SSH into a VM without exposing a public IP, using an in-browser session over TLS (port 443). It's the recommended enterprise pattern for secure VM access.

Last validated on: 2026-06-19
Portal experience note: Steps validated against Azure Portal as of June 2026; labels can vary slightly by region and feature rollout.

> **Note:** The `AzureBastionSubnet` subnet (minimum `/26`) must exist in your VNet before deploying Bastion. The subnet name is case-sensitive and must be exact.

---

## Module / Track Structure

```text
Azure Bastion/
├── README.md                          ← Track entry point
└── 1-Azure Bastion.md                 ← Lab 1: Secure VM Access (you are here)
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Deploy Azure Bastion](#4-deploy-azure-bastion-if-not-already-deployed)
- [Connect to the VM](#5-connect-to-the-vm-using-bastion)
- [Troubleshooting](#6-troubleshooting-real-world-fixes)
- [Why Bastion Matters](#7-why-bastion-matters-engineering-justification)
- [Password from Key Vault](#8-password-from-azure-key-vault-secretless-access-pattern)
- [Bastion Access Diagram](#9-bastion-access-diagram)
- [Bastion vs Jumpbox vs Private Endpoint](#10-bastion-vs-jumpbox-vs-private-endpoint--comparison)
- [Cleanup / Teardown](#11-cleanup--teardown)
- [VNet Peering for Cross-VNet Bastion Access](#12-vnet-peering-for-cross-vnet-bastion-access)
- [Bastion + JIT Lab](../Defender%20for%20Servers/2-JIT.md)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Owner** or **Contributor** on the target resource group |
| Subscription | Pay-As-You-Go or Visual Studio subscription |
| Estimated Time | 30–60 minutes |
| VM | Deployed in a VNet with a private IP; no public IP required |
| Subnet | VNet contains a subnet named exactly `AzureBastionSubnet` (minimum `/26`) |
| NSG | If attached to `AzureBastionSubnet`, required inbound and outbound rules must be in place (see Section 4) |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- Lab uses a single-region VNet and one Bastion deployment.
- Cross-VNet (peered) access requires the Standard tier with IP-based connection enabled (covered in Section 12).
- Private endpoint architecture and custom DNS are out of scope.
- Lab steps use the Azure Portal only; Azure CLI equivalents are not covered.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- **Azure Bastion** deployed in a dedicated `/26` subnet with correct NSG rules
- A **browser-based RDP/SSH session** to a VM that has no public IP
- **VM credentials** retrieved from Azure Key Vault using the secretless access pattern
- An understanding of Bastion versus Jumpbox versus Private Endpoint trade-offs
- **VNet Peering** configured for cross-VNet Bastion access using the Standard tier

---

## 3. Scenario

**Eliminate the public IP and the jumpbox from your VM access architecture.**

Most teams expose RDP (port 3389) or SSH (port 22) directly to the internet to simplify access. This creates a standing attack surface that can't be audited cleanly. Azure Bastion removes the public IP entirely, routes all sessions over HTTPS (port 443), and logs every connection in Azure Activity Logs — without requiring a separate jumpbox VM.

---

## 4. Deploy Azure Bastion (If Not Already Deployed)

### Step 1 — Create the Resource Group

1. Go to **Azure Portal** → **Resource groups**
2. Click **+ Create**
3. Configure:
   - **Subscription:** your subscription
   - **Resource group name:** e.g., `rg-bastion-prod` *(follow your naming convention)*
   - **Region:** same region as your VM and VNet
4. Click **Review + Create** → **Create**

---

### Step 2 — Create the AzureBastionSubnet

The subnet must exist in your VNet **before** deploying Bastion.

1. Go to **Azure Portal** → **Virtual Networks**
2. Select your VNet
3. Click **Subnets** → **+ Subnet**
4. Configure:
   - **Name:** `AzureBastionSubnet` *(exact name — case-sensitive)*
   - **Address range:** minimum `/26` (e.g., `10.0.1.0/26`)
5. Click **Save**

### Step 3 — Deploy the Bastion Resource

1. Go to **Azure Portal**
2. Search: **Bastion**
3. Click **Create**
4. Under the **Basics** tab, configure:
   - **Subscription:** your subscription
   - **Name:** `bastion-prod` *(avoid the `-RG` suffix — that convention is for resource groups)*
   - **Region:** same as VM
   - **Tier:** `Basic` (sufficient for RDP/SSH; choose `Standard` for features like IP-based connection or tunneling)
   - **Virtual Network:** same as VM
   - **Subnet:** select `AzureBastionSubnet` (created above)
5. **Public IP address:** click **Create new** → configure:
   - **Name:** `bastion-pip`
   - **SKU:** `Standard` *(Basic SKU is retired — Standard is required)*
6. Click **Review + Create** → verify no validation errors → **Create**

> **Note:** Deployment takes approximately 5–10 minutes.
> **Scope:** Azure Bastion is a **VNet-level resource** — one deployment covers all VMs in that VNet. No per-VM enablement is required. For peered VNets, upgrade to the **Standard** tier and enable **IP-based connection**.
> **NSG on AzureBastionSubnet:** If you attach an NSG to the Bastion subnet, it must include these inbound rules or Bastion will fail:
>
> | Priority | Source | Port | Purpose |
> | --- | --- | --- | --- |
> | 100 | `Internet` | `443` | User browser → Bastion |
> | 110 | `GatewayManager` | `443` | Azure control plane |
> | 120 | `AzureLoadBalancer` | `443` | Health probes |
>
> And these outbound rules:
>
> | Priority | Destination | Port | Purpose |
> | --- | --- | --- | --- |
> | 100 | `VirtualNetwork` | `3389`, `22` | Bastion → VM |
> | 110 | `AzureCloud` | `443` | Bastion → Azure APIs |

### Step 4 — Verify Bastion Is Ready

1. Navigate to **Bastion** resource in the portal
2. Confirm **Provisioning state** shows `Succeeded`

---

## 5. Connect to the VM Using Bastion

### Method A — From the VM Blade (Recommended)

1. Go to **Virtual Machines**
2. Select your VM
3. Click **Connect**
4. Choose **Bastion**
5. Enter:
   - **Username**
   - **Password**
6. Click **Connect**

A browser-based RDP/SSH session opens instantly.

---

## 6. Troubleshooting (Real World Fixes)

### Issue: Bastion button missing

- Bastion not deployed
- Wrong region
- VM not in same VNet

### RDP/SSH fails to load

- NSG blocking port `3389`/`22`
- VM OS firewall blocking RDP/SSH
- VM not running

### Issue: "AzureBastionSubnet not found"

- Subnet name must be exact: `AzureBastionSubnet`
- Minimum subnet size: `/26`

### Issue: Bastion session connects but screen is black

- VM is still booting — wait 1–2 minutes and retry
- Remote Desktop Services (`TermService`) may be stopped — connect via Azure Serial Console and restart it
- Check if the VM has enough memory/CPU to render the desktop

### Issue: "You don't have permission to connect to this VM"

- Minimum required roles:
  - **Reader** on the target VM
  - **Reader** on the Bastion resource
- Check role assignments via **VM** → **Access control (IAM)** and **Bastion** → **Access control (IAM)**
- Note: Virtual Machine Contributor is not required — Reader is sufficient to initiate a Bastion session

### Issue: Bastion deployment fails with subnet error

- Subnet CIDR is too small — must be `/26` or larger
- Subnet already contains other resources — `AzureBastionSubnet` must be dedicated to Bastion only
- Address space conflicts with existing subnets in the VNet

### Issue: JIT request is stuck in "Pending"

- Microsoft Defender for Cloud plan may not be enabled on the subscription
- The requesting user must have the **Security Reader** + **Virtual Machine Contributor** roles
- Check **Defender for Cloud** → **Environment settings** → confirm Defender for Servers is on

---

## 7. Why Bastion Matters (Engineering Justification)

- No public IP exposure
- No inbound NSG rules from the Internet
- No jumpbox VM required
- Works over HTTPS (`443`)
- Fully audited in Azure Activity Logs
- Enterprise-grade secure access pattern

> This is the recommended access method for production workloads.

---

## 8. Password from Azure Key Vault (Secretless Access Pattern)

Instead of typing a password manually when connecting via Bastion, retrieve it securely from Azure Key Vault.

### Step 1 — Store the VM Password in Key Vault

1. Go to **Azure Portal** → **Key Vaults**
2. Open your Key Vault (e.g., `kv-identity-lab`)
3. Select **Secrets** → **Generate/Import**
4. Configure:
   - **Name:** `vm-admin-password`
   - **Value:** `<your VM admin password>`
5. Click **Create**

### Step 2 — Retrieve the Password Before Connecting

1. Go to **Key Vault** → **Secrets** → `vm-admin-password`
2. Click the current version
3. Click **Show Secret Value**
4. Copy the password to your clipboard

### Step 3 — Connect via Bastion Using the Retrieved Password

1. Go to **Virtual Machines** → Select your VM
2. Click **Connect** → Choose **Bastion**
3. Enter:
   - **Username:** (e.g., `azureadmin`)
   - **Password:** (paste from Key Vault)
4. Click **Connect**

**Why this matters:**

- No hardcoded credentials in scripts or docs
- Password access is fully audited in Key Vault logs
- Supports rotation — update the secret without changing Bastion config
- Aligns with Zero Trust and least-privilege principles

---

## 9. Bastion Access Diagram

The following describes the secure access flow when using Azure Bastion:

```text
  User Browser (HTTPS 443)
         |
         v
  Azure Bastion (Public IP — AzureBastionSubnet /26)
         |
         | Private Network (VNet)
         v
  Target VM (Private IP only — no public IP)
```

**Key points:**

- The user never connects directly to the VM
- Bastion acts as a TLS-terminated reverse proxy inside Azure
- The VM has no public IP and no open inbound NSG rules from the Internet
- All sessions are logged in Azure Activity Logs and Microsoft Defender for Cloud
- Bastion communicates with the VM over the private VNet using RDP (`3389`) or SSH (`22`) internally

---

## 10. Bastion vs Jumpbox vs Private Endpoint — Comparison

| Feature | Azure Bastion | Jumpbox VM | Private Endpoint |
| --- | --- | --- | --- |
| Public IP on target VM | Not required | Not required | Not required |
| Requires separate VM | No | Yes (jumpbox VM) | No |
| Browser-based access | Yes (HTML5 RDP/SSH) | No | No |
| OS patching required | No (managed by Azure) | Yes (you manage jumpbox) | No |
| Cost | Hourly (~$0.19/hr Basic) | VM compute + storage cost | Per endpoint + data cost |
| Use case | Secure VM RDP/SSH access | Legacy or custom tooling | Private access to PaaS (SQL, Storage, etc.) |
| Audit logging | Azure Activity Logs | Depends on config | Azure Monitor / NSG Flow Logs |
| Zero Trust alignment | High | Medium (if hardened) | High |
| Setup complexity | Low | Medium | Medium |

### When to Use Each

**Azure Bastion:**

- You need browser-based RDP/SSH to IaaS VMs
- You want zero public IP exposure with no additional VM overhead
- Best for: production VMs, dev/test VMs, regulated environments

**Jumpbox VM:**

- You need custom tooling or software on the access VM
- You require SSH agent forwarding or special protocols not supported by Bastion
- Best for: legacy environments, multi-hop scenarios

**Private Endpoint:**

- You need private access to PaaS services (Azure SQL, Storage, Key Vault, etc.)
- Not used for VM RDP/SSH — it connects your VNet to a specific PaaS resource
- Best for: securing backend services without exposing them to the public Internet

---

## 11. Cleanup / Teardown

When you are done with the lab, remove resources to avoid ongoing charges.

### Delete the Bastion Resource

1. Go to **Azure Portal** → **Bastion**
2. Select your Bastion resource (e.g., `bastion-prod`)
3. Click **Delete** → Confirm

> **Note:** Deleting Bastion does not affect the VM or VNet.

### Delete the Bastion Public IP

1. Go to **Public IP Addresses**
2. Find the IP created for Bastion (e.g., `bastion-pip`)
3. Confirm it shows **Not associated** (Bastion must be deleted first)
4. Click **Delete** → Confirm

### Remove the AzureBastionSubnet (Optional)

1. Go to **Virtual Networks** → Select your VNet
2. Click **Subnets**
3. Select `AzureBastionSubnet` → Click **Delete**
4. Confirm — only do this if no other resources depend on the subnet

### Disable JIT (If Enabled)

1. Go to **Microsoft Defender for Cloud** → **Just-in-time VM access**
2. Find your VM → Click the **...** menu → **Remove JIT**
3. Confirm — inbound NSG rules return to their default state

---

## 12. VNet Peering for Cross-VNet Bastion Access

If your `AzureBastionSubnet` (`10.0.1.0/26`) and your VM subnet (`172.16.0.0/24`) are in separate VNets, you must create VNet Peering so Bastion (in the hub VNet) can reach the VM (in the spoke VNet).

### Create VNet Peering (Hub → Spoke)

1. Go to **Azure Portal** → **Virtual Networks** → select your Bastion VNet
2. Click **Peerings** → **+ Add**
3. Configure:
   - **Peering name:** `hub-to-spoke`
   - **Remote VNet:** select the VNet that contains your VM
4. Enable:
   - ✔ **Allow virtual network access**
   - ✔ **Allow forwarded traffic**
   - Do **NOT** enable "Use remote gateway"
5. Click **Add**

### Why You Cannot Create the Spoke-to-Hub Peering

> Your VNets are already fully peered and synchronized — you did not make a mistake.

When you created the hub-to-spoke peering, Azure **automatically** created the reverse peering (spoke → hub) for you. This happens when:

- Both VNets are in the same subscription
- Both VNets are in the same tenant
- You selected the remote VNet from the dropdown

So when Azure says:

> *"Select a different virtual network. These virtual networks are already peered to each other."*

It means:

- ✔ The reverse peering already exists
- ✔ The connection is healthy
- ✔ You do **not** need to create another peering
- ✔ Bastion can now reach the VM (assuming NSG/UDR rules are correct)

---

### Full Resource Group Cleanup (If Lab-Only Environment)

If this was a dedicated lab resource group with no other resources you need to keep:

1. Go to **Resource Groups**
2. Select the lab resource group
3. Click **Delete resource group**
4. Type the resource group name to confirm → Click **Delete**
