
# 🛡️ Azure VM Backup & Restore File & Folder Level (Recovery Services Vault)

A complete hands-on lab demonstrating Enhanced VM backup, file-level recovery, full VM restore, and cleanup using the new Azure Backup experience.

> **Note:** This lab uses Azure Backup defaults. Adjust retention, encryption, and security settings based on your organization’s governance and compliance requirements.

---

## 🎯 Learning Objectives

By the end of this lab, you will:
- Deploy a Recovery Services Vault
- Configure Enhanced Backup for an Azure VM
- Perform file-level recovery using the downloadable recovery executable
- Perform a full VM restore from a backup point
- Validate the restored VM
- Clean up all resources (including stopping backup)

---

## 📋 Prerequisites

- Azure subscription with **Owner** or **Contributor** permissions
- Ability to create:
  - Resource groups
  - Virtual machines
  - Storage accounts
  - Recovery Services Vault

---

# 🧪 Lab Steps

---

## 1. Initial Setup

### 1.1 Create the Resource Group

1. In the Azure Portal, select **Create a resource** → **Resource group**
2. Name: `vmbackupandrestore-RG`
3. Choose your subscription and region
4. Click **Review + Create** → **Create**

---

### 1.2 Create a Storage Account

1. Go to **Create a resource** → **Storage account**
2. Name: `vmbackupandrestorestg`
3. Performance: Standard
4. Redundancy: Locally Redundant Storage (LRS)
5. Click **Review + Create** → **Create**

---

### 1.3 Deploy a Windows VM

1. Go to **Create a resource** → **Virtual machine**
2. Configure:
   - Name: `fntech-FS01`
   - Resource group: `vmbackupandrestore-RG`
   - Availability options: No infrastructure redundancy required
   - Security type: Standard
   - Image: Windows Server 2019 Datacenter – Gen2
   - Size: Standard_D2ds_v4 (2 vCPUs, 8 GiB RAM)
   - Configure admin credentials and networking
3. Click **Review + Create** → **Create**

---

### 1.4 Prepare the VM

1. Connect via RDP from the VM blade
2. Inside Windows:
   - Open File Explorer
   - Create folder: `C:\Data Files`
   - Add several files and subfolders (used later for recovery testing)

---

## 2. Configure Backup (New Azure Backup Experience)

Azure has redesigned the VM backup workflow. You now configure backup per VM, and during that process you either select an existing policy or create a new Enhanced policy.

> **Important:** You must select at least one VM before you can create or apply an Enhanced policy.

---

### 2.1 Start Backup from Backup Items

1. Open the **Recovery Services Vault**
2. Select **Backup items**
3. Click **Add**
4. You will enter the Configure Backup wizard

---

### 2.2 Select Backup Source

1. Where is your workload running? → **Azure**
2. What do you want to back up? → **Virtual machine**
3. Click **Backup**

---

### 2.3 Select Virtual Machines

1. Click **Add**
2. Select your VM: `fntech-FS01`
3. Click **Select**

> You cannot proceed without selecting at least one VM.

---

### 2.4 Create or Select a Backup Policy

**Create a New Enhanced Policy**

1. Under **Backup policy**, click **Create a new policy**
2. Choose **Enhanced**
3. Enter a name: `EnhancedPolicy-VMDaily`

**Configure Policy Details**

- Full Backup
  - Backup frequency: Daily
  - Time: 8:00 AM UTC
- Instant Restore
  - Retain instant recovery snapshots: 7 days
- Retention of Daily Backup Point
  - Retain daily backup: 30 days
  - Time: 8:00 AM
- Consistency Type
  - Application or file-system consistent
- Optional Settings
  - Enable tiering (if long retention is configured)
  - Crash-consistent only (not supported for some VMs)
- Azure Backup Resource Group name
  - Prefix: `fntechnotes`
  - Suffix: `BKP`

4. Click **OK** to create the policy

---

### 2.5 Selective Disk Backup

- Azure displays all disks attached to the VM:
  - OS disk cannot be excluded
  - Data disks can be included/excluded
  - “Include future disks” can be toggled
- For this lab:
  - Include all disks
  - Include future disks: **Enabled**

---

### 2.6 Enable Backup

1. Review the Enhanced policy warning:
   - Once enabled, switching to Standard policy is not possible
2. Click **Enable backup**
   - Azure will:
     - Register the VM
     - Apply the Enhanced policy
     - Schedule the first backup

---

### 2.7 Trigger the First Backup (Updated Method)

Azure has changed how manual backups are triggered.

1. Open the **Recovery Services Vault**
2. Go to **Backup items**
3. Select **Azure Virtual Machine**
4. Locate your VM (`fntech-FS01`)
5. Scroll horizontally to the right
6. Click the three‑dot **(…)** menu
7. Select **Backup now**
8. Choose a retention date
9. Click **OK**

---

## 3. File-Level Recovery Test

### 3.1 Delete Files in the VM

1. RDP into the VM
2. Delete several files/subfolders from `C:\Data Files`

---

### 3.2 Start File Recovery

1. Go to **Recovery Services Vault** → **Backup items** → **Azure Virtual Machine**
2. Select your VM
3. Click **File Recovery**
4. Select a restore point
5. Click **Download Executable** and copy the one-time password

---

### 3.3 Mount the Recovery Volume

1. Copy the `.exe` into the VM (or download directly inside the VM)
2. Run it as **Administrator**
3. Enter the password
4. Azure mounts the recovery snapshot as a read-only drive (e.g., `E:`)

---

### 3.4 Restore Deleted Files

1. Open the mounted drive
2. Navigate to: `E:\Data Files\`
3. Copy files back to: `C:\Data Files\`

---

### 3.5 Unmount the Recovery Volume

1. Return to the executable window
2. Click **Unmount Disks**
3. Close the tool and delete the EXE (optional)

---

### 3.6 Verify Recovery

- Confirm file structure and content
- Document any additional steps

---

## 4. Cleanup (Updated & Correct Order)

### 4.1 Stop Backup for the VM

1. Open the **Recovery Services Vault**
2. Go to **Backup items** → **Azure Virtual Machine**
3. Select the VM
4. Click **Stop backup**
5. Choose:
   - Stop backup and delete backup data
6. Confirm

---

### 4.2 Delete the Recovery Services Vault

1. Ensure **Backup items = 0**
2. Click **Delete**
3. Confirm

---

### 4.3 Delete the Storage Account

- Delete: `vmbackupandrestorestg`

---

### 4.4 Delete the Resource Group

- Delete: `vmbackupandrestore-RG`
- Delete Resouce Group creared by azure for storing Restore Point Collection

---
