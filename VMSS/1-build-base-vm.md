
# 🖥️ Build & Configure the Base VM (IIS + Custom Page)

This document covers building the base Windows Server VM and preparing it for Sysprep.

---

## 📘 1. Create the Base VM


**Portal Navigation:**
1. In the [Azure Portal](https://portal.azure.com), search for **Virtual Machines** in the top search bar.
2. Click **+ Create** and select **Virtual Machine**.
3. Choose a **Windows Server** image from the Marketplace (e.g., Windows Server 2022 Datacenter).
4. Fill in the required details (resource group, VM name, region, size, admin username/password, etc.).
5. Click **Review + Create** → **Create**.
6. Once deployment completes, go to the VM's overview page and use the **Connect** button to open an RDP session.

---

## 📘 2. Install IIS + Create a Custom Test Page

**Portal Navigation:**
1. In your RDP session to the VM, open **PowerShell as Administrator**.
2. Run the following script to install IIS and create a custom test page.

Run the following PowerShell script inside the VM:

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

## ✔ Verify IIS

- Open a browser and go to: [http://localhost](http://localhost)
- You should see your custom Hello World page.

---

## ❗ Important Notes

**Do NOT:**
- Domain join
- Azure AD join
- Intune enroll
- Enable BitLocker

These actions break Sysprep or image specialization.

---

## 🎉 Base VM is ready for Sysprep

**Next step:**  
➡ [Sysprep VM](2-sysprep-vm.md)

