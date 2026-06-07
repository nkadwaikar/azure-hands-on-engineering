## 🧼 Sysprep the Windows VM (Azure‑Safe Method)

This guide walks you through preparing the VM for image capture with the correct Sysprep command.

---

# 📘 **1. Clean the VM Before Sysprep**

**Portal Navigation:**
1. In the [Azure Portal](https://portal.azure.com), search for **Virtual Machines** in the top search bar.
2. Select your VM from the list to open its overview blade.
3. Use the **Connect** button to open an RDP session and perform the following checks inside the VM.

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

**Portal Navigation:**
1. In your RDP session to the VM, open **PowerShell as Administrator**.
2. Navigate to the Sysprep directory and run the command below.

Open **elevated PowerShell**:

```powershell
cd C:\Windows\System32\Sysprep
.\sysprep.exe /generalize /oobe /shutdown /mode:vm
```

### Why these switches matter
- **/generalize** → resets SID  
- **/oobe** → Azure can specialize the VM  
- **/shutdown** → required before capture  
- **/mode:vm** → prevents the “Hi there” OOBE loop  

---

# 📘 **3. Wait for VM to Fully Shut Down**

**Portal Navigation:**
1. In the [Azure Portal](https://portal.azure.com), go to your VM's overview page.
2. Wait until the **Status** shows **Stopped (deallocated)** before proceeding to image capture.

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
➡ [Capture & Test Image](../VMSS/1-capture-and-test-image.md)

---

