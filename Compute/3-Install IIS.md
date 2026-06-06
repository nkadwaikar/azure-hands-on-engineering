🌐 Install IIS on the VM (Azure Portal + PowerShell)
1. Connect to the VM
Portal Navigation
In Azure Portal, go to Virtual Machines.
Select your VM: vm‑fntech‑lab‑eus‑app01.
Click Connect → choose RDP (for Windows Server).
Download the .rdp file and sign in using the admin credentials you set during VM creation.
---
1. Open PowerShell as Administrator
Inside the VM:
Click Start → search PowerShell.
Right‑click Windows PowerShell → Run as Administrator.
---
1. Install IIS + Common Features + Custom Test Page
Run the following script inside the VM:
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

---
✔ 4. Verify IIS
Option A — Inside the VM
Open Microsoft Edge inside the VM.
Go to:
http://localhost

You should see:
Your custom Hello World page, not the default IIS banner
The HTML you created via PowerShell
---
✔ 5. Verify from Your Local Machine (Optional)
If your VM has a Public IP and NSG rule allowing port 80:
Go to VM → Networking.
Ensure inbound rule exists:
Port: 80
Protocol: TCP
Action: Allow
Copy the VM’s Public IP.
Browse to:
http://<public-ip>

---
🛠 Troubleshooting
If the page does NOT load
Check NSG inbound rule for port 80.
Check Windows Firewall inside the VM:
Control Panel → Windows Defender Firewall → Allow an app → ensure World Wide Web Services is allowed.
Restart IIS manually:
iisreset

Confirm the file exists:
C:\inetpub\wwwroot\index.html
