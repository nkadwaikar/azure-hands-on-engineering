## 🧼 Sysprep the Windows VM (Azure‑Safe Method)

This document covers preparing the VM for image capture using the correct Sysprep command.

---

# 📘 **1. Clean the VM Before Sysprep**

### ✔ Check for pending reboot
```powershell
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
```
If **True**, reboot.

### ✔ Check Windows Updates  
Ensure **no pending updates**.

### ✔ Check BitLocker status
```powershell
manage-bde -status
```
BitLocker must be **Off**.

---

# 📘 **2. Run Sysprep (Correct Azure Command)**

Open **elevated PowerShell**:

```powershell
cd C:\Windows\System32\Sysprep
.\sysprep.exe /generalize /oobe /shutdown /mode:vm
```

### Why these switches matter:
- **/generalize** → resets SID  
- **/oobe** → Azure can specialize the VM  
- **/shutdown** → required before capture  
- **/mode:vm** → prevents the “Hi there” OOBE loop  

---

# 📘 **3. Wait for VM to Fully Shut Down**

In Azure Portal, the VM must show:

### ✔ **Stopped (deallocated)**

If it shows:

- Stopping  
- Shutting down  
- Running  

➡️ **Do NOT capture yet.**

---

# 🚫 Do NOT Delete Panther Folder

The Panther folder is required by **Azure Guest Agent** during provisioning.

Deleting it causes:

- OOBE loops  
- Specialization failures  
- VMSS deployment failures  

---

# 🎉 Sysprep complete

Proceed to:  
➡ [3-capture-and-test-image.md](3-capture-and-test-image.md)

---

