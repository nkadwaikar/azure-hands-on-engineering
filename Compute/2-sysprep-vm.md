# Sysprep the Windows VM (Azure‑Safe Method)

> **Why this matters:** Manually built VMs carry machine-specific SIDs, hostname state, and stale OS configuration that break image reuse — Sysprep generalizes the Windows installation so every downstream scale-set instance starts from a clean, identical state.

This guide walks you through preparing the VM for image capture with the correct Sysprep command.

Last validated on: 2026-06-19  
Portal experience note: Steps validated against Azure Portal as of June 2026.

> **Note:** Run Sysprep only on a VM you intend to capture as an image. The process is irreversible on that instance — the VM cannot be restarted as a normal workload after generalization.

---

## Prerequisites

| Requirement | Detail |
| --- | --- |
| Prior lab | VM created and running from [Build Base VM](1-build-base-vm.md) |
| Access | RDP session to the VM (Administrator credentials) |
| VM state | Running, no pending Windows Updates, BitLocker Off |
| Estimated Time | 10–15 minutes |

---

## Quick Navigation

- [Clean the VM Before Sysprep](#1-clean-the-vm-before-sysprep)
- [Run Sysprep](#2-run-sysprep-correct-azure-command)
- [Wait for Shutdown](#3-wait-for-vm-to-fully-shut-down)
- [Generalize in Azure Portal](#4-generalize-the-vm-in-azure-portal)
- [Panther Folder Warning](#5-panther-folder--do-not-delete)

---

## 1. Clean the VM Before Sysprep

1. In the [Azure Portal](https://portal.azure.com), search for **Virtual Machines**.
2. Select your VM to open its overview blade.
3. Click **Connect** to open an RDP session and perform the following checks inside the VM.

### Check for pending reboot

```powershell
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
```

If **True**, reboot.

### Check Windows Updates

Ensure **no pending updates**.

### Check BitLocker status

```powershell
manage-bde -status
```

BitLocker must be **Off**.

---

## 2. Run Sysprep (Correct Azure Command)

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

## 3. Wait for VM to Fully Shut Down

1. In the [Azure Portal][portal], go to your VM's overview page.
2. Wait until the **Status** shows **Stopped (deallocated)** before proceeding to image capture.

> **Expected state:** VM status shows **Stopped (deallocated)**. Do not capture if it shows Stopping, Shutting down, or Running.

---

## 4. Generalize the VM in Azure Portal

After the VM reaches **Stopped (deallocated)** state, you must mark it as generalized in Azure before capture:

1. In the [Azure Portal][portal], go to your VM's overview page.
2. In the top menu, click **Capture**.
3. Azure will prompt you to confirm the VM will be generalized — confirm and proceed.

> **Note:** Skipping this step and attempting to create an image from a non-generalized VM will result in a failed or unusable image.

---

## 5. Panther Folder — Do Not Delete

Location: `C:\Windows\Panther`

The Panther folder is required by **Azure Guest Agent** during provisioning.

Deleting it causes:

- OOBE loops  
- Specialization failures  
- VMSS deployment failures  

---

> **Next step:** [Capture and Test Image](../VMSS/1-capture-and-test-image.md)

---

[portal]: https://portal.azure.com
