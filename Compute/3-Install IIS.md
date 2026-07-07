# Install IIS on the VM (Azure Portal + PowerShell)

> **Why this matters:** A VM without a web server role is just a running OS with no workload — this lab installs IIS and writes a test page so the custom image used in VMSS serves verifiable HTTP traffic rather than just powering on.

Last validated on: 2026-06-19
Portal experience note: Steps validated against Azure Portal as of June 2026.

> **Note:** This lab installs IIS on a Windows Server VM. Complete [Build Base VM](1-build-base-vm.md) first to have a running VM to connect to.

---

## Module / Track Structure

```text
Compute/
├── README.md                          ← Track entry point
├── 1-build-base-vm.md                 ← Lab 1: Build a Base VM
├── 2-sysprep-vm.md                    ← Lab 2: Sysprep (Azure-safe)
└── 3-Install IIS.md                   ← Lab 3: Install IIS (you are here)
```

---

## Prerequisites

| Requirement | Detail |
| --- | --- |
| Prior lab | VM created and running from [Build Base VM](1-build-base-vm.md) |
| Access | RDP session to the VM (Administrator credentials) |
| VM state | Running, reachable via RDP |
| Estimated Time | 10–15 minutes |

---

## Learning Objectives

By the end of this lab you will be able to:

- Install the IIS web server role and common HTTP features on a Windows Server VM using PowerShell
- Write a custom HTML index page to `C:\inetpub\wwwroot` so image validation serves identifiable content rather than the default IIS banner
- Verify IIS is serving traffic from both inside the VM (`localhost`) and optionally from a remote browser via the VM's public IP
- Diagnose common IIS connectivity failures (NSG port 80, Windows Firewall, IIS service state)
- Explain why IIS must be installed **before** Sysprep — installing software after generalization contaminates the golden image

---

## Quick Navigation

- [Connect to the VM](#1-connect-to-the-vm)
- [Open PowerShell](#2-open-powershell-as-administrator)
- [Install IIS](#3-install-iis--common-features--custom-test-page)
- [Verify IIS](#4-verify-iis)
- [Troubleshooting](#5-troubleshooting)
- [Cleanup](#6-cleanup)

---

## 1. Connect to the VM

### Portal Navigation

1. In Azure Portal, go to **Virtual Machines**.
2. Select your VM: `vm-fntech-eus-lab-app01`.
3. Click **Connect** → choose **RDP** (for Windows Server).
4. Download the `.rdp` file and sign in using the admin credentials you set during VM creation.

---

## 2. Open PowerShell as Administrator

Inside the VM:

1. Click **Start** → search **PowerShell**.
2. Right-click **Windows PowerShell** → **Run as Administrator**.

---

## 3. Install IIS + Common Features + Custom Test Page

Run the following script inside the VM:

```powershell
# Install IIS and management tools
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Optional: Install common IIS features
Install-WindowsFeature Web-Common-Http
Install-WindowsFeature Web-Default-Doc
Install-WindowsFeature Web-Static-Content
Install-WindowsFeature Web-Http-Errors
Install-WindowsFeature Web-Http-Logging
Install-WindowsFeature Web-Stat-Compression
Install-WindowsFeature Web-Mgmt-Console

# Path to default IIS site
$sitePath = "C:\inetpub\wwwroot"

# Create a simple Hello World page
$indexFile = Join-Path $sitePath "index.html"
@"
<!DOCTYPE html>
<html>
<head>
<title>Hello World</title>
</head>
<body style='font-family:Arial; text-align:center; margin-top:50px;'>
<h1>Hello World from IIS!</h1>
<p>This page was created automatically using PowerShell.</p>
</body>
</html>
"@ | Out-File -FilePath $indexFile -Encoding utf8 -Force

# Restart IIS to apply changes
iisreset

Write-Host "IIS installation and configuration complete. You can access the default page at http://localhost" -ForegroundColor Green
```

---

## 4. Verify IIS

### Option A — Inside the VM

1. Open **Microsoft Edge** inside the VM.
2. Go to: `http://localhost`

You should see:

- Your custom Hello World page, not the default IIS banner
- The HTML you created via PowerShell

### Option B — From Your Local Machine (Optional)

If your VM has a Public IP and NSG rule allowing port 80:

1. Go to **VM** → **Networking**.
2. Ensure inbound rule exists: Port 80, TCP, Allow.
3. Copy the VM's **Public IP** and browse to: `http://<public-ip>`

---

---

## 5. Troubleshooting

**If the page does NOT load:**

- Check NSG inbound rule for port 80.
- Check Windows Firewall inside the VM: **Control Panel** → **Windows Defender Firewall** → **Allow an app** → ensure **World Wide Web Services** is allowed.
- Restart IIS manually: `iisreset`
- Confirm the file exists: `C:\inetpub\wwwroot\index.html`

---

## 6. Cleanup

This lab does not require cleanup on its own — the VM should be kept running for the Sysprep step.

> When the full Compute track is complete, delete the resource group `rg-fntech-vm-lab-eus-core` to remove all resources.

---

## What I Learned

- The order matters: IIS must be installed and validated **before** Sysprep — reversing the order produces a generalized image with no web role, breaking every VMSS instance
- `Install-WindowsFeature -IncludeManagementTools` is the critical flag for IIS Manager access; skipping it means you can't troubleshoot IIS from within the VM after deployment
- A custom `index.html` is essential for VMSS validation — without it, you cannot distinguish a live VMSS instance from a freshly provisioned one with the default IIS page
- NSG rules for port 80 need to be opened at the **NIC-level NSG and the subnet-level NSG** — having only one of them is a common source of failed HTTP validation from outside the VM
- `iisreset` after writing the custom page is often needed; IIS caches the default page and won't serve the new file until the service refreshes

---

> **Next step:** [Sysprep the VM](2-sysprep-vm.md)
