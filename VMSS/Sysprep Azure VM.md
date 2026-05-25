How to Sysprep Azure VM 
---
STEP 1 — Build and configure your base VM
Create a fresh Windows Server VM from Marketplace
Log in
Install IIS or any apps you need
Do NOT join domain
Do NOT AAD join
Do NOT Intune enroll
Do NOT enable BitLocker
---
STEP 2 — Make sure the VM is clean
Check pending reboot:
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"

If True → reboot.
Check Windows Update
Make sure no updates are pending.
Check BitLocker:
manage-bde -status

---
STEP 3 — Run Sysprep (correct Azure command)
Open elevated PowerShell:
cd C:\Windows\System32\Sysprep
.\sysprep.exe /generalize /oobe /shutdown /mode:vm

Why this is correct:
/generalize → resets SID
/oobe → Azure can specialize the VM
/shutdown → required for capture
/mode:vm → prevents the “Hi there” screen you saw
---
STEP 4 — WAIT until VM is fully OFF
In Azure Portal, the VM must show:
Stopped (deallocated)
If it says:
Stopping
Shutting down
Running
→ DO NOT capture yet.
---
STEP 5 — Capture the Image
Azure Portal → VM → Capture
Choose:
✔ Shared Image Gallery (recommended)
Create Image Definition (if needed)
Create Image Version (e.g., 1.0.0)
Do NOT start the VM again.
---
STEP 6 — Deploy a Test VM from the Image
This is the VM you should test.
If the test VM shows:
✔ Login screen → Image is good
 “Hi there” OOBE → You captured incorrectly
“Specializing…” → Sysprep failed
Black screen → RDP not enabled
---
⭐ STEP 7 — Use the Image for VMSS
Once the test VM works, you can safely use the image for VMSS.
---
🚫 Important: Do NOT delete Panther folder
That step is for VHD uploads, not Azure VMs.
Azure Guest Agent needs Panther logs to complete provisioning.
Deleting Panther can break the image.

