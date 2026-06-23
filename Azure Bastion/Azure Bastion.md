# Azure Bastion — Secure VM Access (No Public IP)

Azure Bastion lets you RDP/SSH into a VM without exposing a public IP, using an in-browser session over TLS (port 443). It's the recommended enterprise pattern for secure VM access.

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Deploy Azure Bastion](#2-deploy-azure-bastion-if-not-already-deployed)
- [Connect to the VM](#3-connect-to-the-vm-using-bastion)
- [Troubleshooting](#4-troubleshooting-real-world-fixes)
- [Why Bastion Matters](#5-why-bastion-matters-engineering-justification)
- [Password from Key Vault](#6-password-from-azure-key-vault-secretless-access-pattern)
- [Bastion Access Diagram](#7-bastion-access-diagram)
- [Bastion + JIT Lab](#8-bastion--just-in-time-jit-vm-access-lab)
- [Bastion vs Jumpbox vs Private Endpoint](#9-bastion-vs-jumpbox-vs-private-endpoint--comparison)

---

## 1. Prerequisites

Before connecting, ensure:

- The VM is deployed in a VNet
- The VNet has a subnet named exactly: `AzureBastionSubnet`
- A Bastion resource exists in the same VNet
- The VM has:
  - A NIC
  - A private IP
  - RDP/SSH enabled in the OS
- NSG allows:
  - Inbound RDP (`3389`) or SSH (`22`) from `VirtualNetwork`
  - Outbound `443`

---

## 2. Deploy Azure Bastion (If Not Already Deployed)

1. Go to **Azure Portal**
2. Search: **Bastion**
3. Click **Create**
4. Configure:
   - **Resource group:** same as VM
   - **Name:** `bastion-host-RG`
   - **Region:** same as VM
   - **VNet:** same as VM
   - **Subnet:** must be `AzureBastionSubnet`
5. **Public IP:** create new
6. Click **Review + Create** → **Create**

> **Note:** Deployment takes approximately 5 minutes.

---

## 3. Connect to the VM Using Bastion

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

### Method B — From the Bastion Resource

1. Open **Bastion**
2. Select **Connect**
3. Choose the VM
4. Enter credentials
5. Click **Connect**

---

## 4. Troubleshooting (Real World Fixes)

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

---

## 5. Why Bastion Matters (Engineering Justification)

- No public IP exposure
- No inbound NSG rules from the Internet
- No jumpbox VM required
- Works over HTTPS (`443`)
- Fully audited in Azure Activity Logs
- Enterprise-grade secure access pattern

> This is the recommended access method for production workloads.

---

## 6. Password from Azure Key Vault (Secretless Access Pattern)

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

## 7. Bastion Access Diagram

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

## 8. Bastion + Just-In-Time (JIT) VM Access Lab

Just-In-Time access adds a time-limited, on-demand approval layer on top of Bastion. It is managed through Microsoft Defender for Cloud.

### How It Works

1. By default, inbound RDP/SSH ports are blocked by NSG
2. A user requests access via Microsoft Defender for Cloud
3. Defender temporarily opens the NSG rule for a defined time window (e.g., 1–3 hours)
4. The session is logged and the rule automatically closes after the window expires

### Enable JIT on a VM

1. Go to **Microsoft Defender for Cloud** → **Workload Protections**
2. Select **Just-in-time VM access**
3. Find your VM → Click **Enable JIT on 1 VM**
4. Configure allowed ports: `3389` (RDP) or `22` (SSH)
5. Set max request time (e.g., 3 hours)
6. Click **Save**

### Request JIT Access

1. Go to **Defender for Cloud** → **JIT VM Access**
2. Select your VM → Click **Request Access**
3. Enter justification, IP range, and time window
4. Click **Open Ports**

### Combined Pattern — Bastion + JIT

- JIT controls **when** the port is open (time-boxed)
- Bastion controls **how** you connect (no public IP, browser-based)
- Together they eliminate standing access and reduce the attack surface to near zero

---

## 9. Bastion vs Jumpbox vs Private Endpoint — Comparison

| Feature | Azure Bastion | Jumpbox VM | Private Endpoint |
| --- | --- | --- | --- | --- |
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
