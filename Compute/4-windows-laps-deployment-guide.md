# Windows LAPS Deployment Guide (Hybrid AD + Azure Arc, No Intune)

> **Why this matters:** Local administrator accounts with static, shared passwords are a persistent lateral movement risk in enterprise AD environments — every server sharing the same local admin password becomes one compromised credential away from a domain-wide breach. Windows LAPS automatically rotates each machine's local administrator password on a configurable schedule, stores it encrypted in Active Directory, and enforces audit-controlled access — eliminating the shared-credential risk with no agent installation required on modern Windows Server builds.

**Scope:** Windows Server 2019, 2022, 2025
**Delivery:** Group Policy (AD DS) via GUI, with PowerShell used only where the GUI has no equivalent
**Password Storage:** Active Directory (Encrypted)

This guide walks through deployment end-to-end using the Group Policy Management Console (GPMC), Active Directory Users and Computers (ADUC), and PowerShell only for schema extension, validation, and rotation — all steps Windows GUI tools cannot perform.

Last validated on: August 2026
Portal experience note: Steps validated against Windows Server 2019/2022/2025 with GPMC and ADUC (RSAT) as of August 2026. PowerShell steps require execution on a Domain Controller or an RSAT-enabled admin workstation.

> **Note:** This lab covers **Windows LAPS** (the native Windows Server feature shipped in the April 2023 cumulative update), not the legacy MSI/CSE-based LAPS client. If any server in scope has previously run the legacy LAPS client, complete [5-windows-laps-risks-and-legacy-migration.md](5-windows-laps-risks-and-legacy-migration.md) before deploying.

---

## Module / Track Structure

```text
Compute/
├── README.md                                      ← Track entry point
├── 1-build-base-vm.md                             ← Lab 1: Build a Base VM
├── 3-install-iis.md                               ← Lab 2: Install IIS
├── 2-sysprep-vm.md                                ← Lab 3: Sysprep (Azure-safe)
├── 4-windows-laps-deployment-guide.md             ← Lab 4: Windows LAPS Deployment (you are here)
└── 5-windows-laps-risks-and-legacy-migration.md   ← Lab 5: LAPS Risks & Legacy Migration
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Extend the AD Schema](#step-1--extend-the-active-directory-schema-powershell-required)
- [Step 2 — Grant Computer Object Permissions](#step-2--grant-computer-object-permissions-gui)
- [Step 3 — Create the GPO](#step-3--create-the-gpo-gui)
- [Step 4 — Configure Core LAPS Settings](#step-4--configure-core-laps-settings-gui)
- [Step 5 — Optional Hardening Settings](#step-5--optional-hardening-settings-gui)
- [Step 6 — Link and Scope the GPO](#step-6--link-and-scope-the-gpo-gui)
- [Step 7 — Delegate Password Read/Reset Permissions](#step-7--delegate-password-readreset-permissions-gui)
- [Step 8 — Apply and Refresh Policy](#step-8--apply-and-refresh-policy)
- [Step 9 — Validate Deployment](#step-9--validate-deployment-powershell-required--no-gui-equivalent)
- [Step 10 — Azure Arc Considerations](#step-10--azure-arc-considerations)
- [Step 11 — Deployment Checklist](#step-11--deployment-checklist)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Domain Functional Level | **2016 or higher** (required for encrypted password storage) |
| Domain Controllers | Running **Windows Server 2019 or later** |
| Target Servers | **Windows Server 2019, 2022, or 2025** with the **April 2023** cumulative update or later |
| Rights | Domain Admin (or Schema Admin) for the one-time schema extension; GPO creation/link rights on the target OU |
| Estimated Time | 45–60 minutes |
| Tools | GPMC, ADUC, ADSI Edit (validation), PowerShell (schema extension and validation only) |

Naming reference: [Naming Convention](../Naming-Convention.md)

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Extended the Active Directory schema with Windows LAPS password attributes (`Update-LapsADSchema`)
- Configured a GPO that enforces encrypted password storage, rotation schedule, and post-authentication reset actions
- Granted computer objects self-write permission on the LAPS attributes at the OU level
- Delegated fine-grained read and reset rights to Helpdesk, Ops, and Security teams using the Delegation of Control Wizard
- Validated deployment using `Get-LapsADPassword` and confirmed password rotation via the LAPS Operational event log
- Understood how Azure Arc-managed servers integrate with AD-delivered LAPS policy (no Arc extension required)

---

## 3. Scenario

**A server estate managed through Group Policy (not Intune) requires automatic local administrator password rotation to pass a security audit.**

Intune licensing is not in scope — GPO is the policy delivery mechanism. Active Directory Domain Services is already deployed and functional. Azure Arc is in scope for lifecycle management and compliance auditing, but GPO remains the LAPS policy delivery path. This lab assumes a clean environment with no legacy LAPS client previously installed. If legacy LAPS is present anywhere in the target OU, see [5-windows-laps-risks-and-legacy-migration.md](5-windows-laps-risks-and-legacy-migration.md) before proceeding.

---

## Step 1 — Extend the Active Directory Schema (PowerShell required)

The GUI has no way to extend the AD schema — this is a one-time PowerShell step run from a Domain Controller or a management machine with RSAT installed.

1. Open **PowerShell as Administrator** on a Domain Controller (or RSAT-enabled admin workstation).
2. Run:
   ```powershell
   Update-LapsADSchema
   ```
3. Confirm the new LAPS attributes exist. Open **ADSI Edit** (GUI) → connect to the Schema naming context → search for:
   - `ms-LAPS-Password`
   - `ms-LAPS-EncryptedPassword`
   - `ms-LAPS-PasswordExpirationTime`

   If these attributes are present, the schema extension succeeded.

---

## Step 2 — Grant Computer Object Permissions (GUI)

LAPS needs permission to write the password attributes to each computer object.

1. Open **Active Directory Users and Computers** (`dsa.msc`).
2. Enable **Advanced Features** (View menu → Advanced Features).
3. Right-click the **OU containing your target servers** → **Properties** → **Security** tab → **Advanced**.
4. Click **Add** → select the computer objects' self-permission or use:
   ```powershell
   Set-LapsADComputerSelfPermission -Identity "OU=Servers,DC=yourdomain,DC=com"
   ```
   (This is the supported method — the GUI ACL editor doesn't expose the LAPS-specific attribute set cleanly, so run this one PowerShell command instead of hand-building ACEs.)

---

## Step 3 — Create the GPO (GUI)

1. Open **Group Policy Management Console** (`gpmc.msc`).
2. Right-click the OU containing your servers → **Create a GPO in this domain, and Link it here**.
3. Name it: `Windows LAPS – Server Local Admin Password Policy`.
4. Right-click the new GPO → **Edit**.

---

## Step 4 — Configure Core LAPS Settings (GUI)

Navigate to:

```
Computer Configuration → Policies → Administrative Templates → System → LAPS
```

Configure each setting below by double-clicking it, selecting **Enabled**, and entering the value shown.

| Policy | Setting | Value |
|---|---|---|
| Configure password backup directory | Enabled | Active Directory |
| Password Settings | Enabled | Length: **24**, Age: **30 days**, Complexity: **Large letters + small letters + numbers + special characters** |
| Name of administrator account to manage | Enabled | `Administrator` (or your custom local admin name) |
| Do not allow password expiration time longer than required by policy | Enabled | — |
| Configure authorized password decryptors (Windows Server 2019+ DCs only) | Enabled | Add: Helpdesk group, Tier 2 Ops, Security team |
| Post-authentication actions | Enabled | **Reset the password, logoff the managed account, and terminate all remaining processes** |
| Enable password encryption | Enabled | Requires DFL 2016+ (already confirmed in prerequisites) |

Click **Apply** → **OK** after each setting.

---

## Step 5 — Optional Hardening Settings (GUI)

Still inside the same GPO path:

| Policy | Setting | Value |
|---|---|---|
| Configure size of encrypted password history | Enabled | **5** |
| Enable DSRM password backup (DCs only) | Enabled | — |

For audit logging, no separate GPO toggle is needed — LAPS writes events automatically to:
```
Applications and Services Logs → Microsoft → Windows → LAPS → Operational
```
You can forward this log via **Event Viewer subscriptions** or your SIEM agent for centralized auditing.

---

## Step 6 — Link and Scope the GPO (GUI)

1. In GPMC, confirm the GPO is linked to the correct **server OU** (not the domain root, to avoid affecting workstations or DCs unintentionally).
2. Use **Security Filtering** in the GPO's scope tab to restrict application to a specific security group (e.g., `SG-LAPS-Servers`) if you want a staged rollout rather than OU-wide.
3. Optionally set **WMI Filtering** to target only Server OS (excludes any client machines accidentally in scope).

---

## Step 7 — Delegate Password Read/Reset Permissions (GUI)

1. In **ADUC**, right-click the server OU → **Delegate Control**.
2. Run the **Delegation of Control Wizard**:
   - **Helpdesk Tier 1** → delegate "Read ms-LAPS-Password / ms-LAPS-EncryptedPassword" (read-only)
   - **Tier 2/3 Ops** → delegate read + the ability to trigger `Reset-LapsPassword` (this is a PowerShell action, not an ACL — grant them RSAT + the read permission, and rely on your JIT/PAM tooling to gate who runs the reset command)
   - **Security Team** → read + audit log access
   - **Automation Account** (optional) → read-only, used by scripts/tools like Azure Arc extensions or SOAR playbooks

   The wizard doesn't list LAPS attributes by default — choose **"Create a custom task to delegate"** → **This folder, existing objects...** → check **Read/Write ms-LAPS-Password**, **ms-LAPS-EncryptedPassword**, and **ms-LAPS-PasswordExpirationTime** as needed per group.

---

## Step 8 — Apply and Refresh Policy

On a target server:

1. Open **Command Prompt or PowerShell** and run:
   ```powershell
   gpupdate /force
   ```
2. Reboot if prompted, or wait for the next policy refresh cycle (90 minutes by default).

---

## Step 9 — Validate Deployment (PowerShell required — no GUI equivalent)

**Check the current password:**
```powershell
Get-LapsADPassword -Identity SERVER01 -AsPlainText
```

**Force an immediate rotation (for testing):**
```powershell
Reset-LapsPassword -Identity SERVER01
```

**Confirm rotation via event logs** (can also be viewed in **Event Viewer** GUI under the LAPS Operational log path from Step 5):
```powershell
Get-WinEvent -LogName Microsoft-Windows-LAPS/Operational | Select-Object -First 10
```

**Confirm policy applied correctly on the client:**
```powershell
gpresult /r
```
or open **GUI: `rsop.msc`** to view Resultant Set of Policy and confirm the LAPS GPO is listed as applied.

---

## Step 10 — Azure Arc Considerations

Since Azure Arc is managing lifecycle/patching/compliance (not policy delivery) in this design:

- No LAPS-specific Arc extension is required — GPO remains the delivery mechanism.
- Ensure Arc-onboarded servers are joined to the same AD domain and placed in the correct OU so they receive the GPO.
- Arc's **Machine Configuration** feature can optionally be used to *audit* (not enforce) that LAPS registry keys are present, if you want an additional compliance dashboard view — this is supplementary, not a replacement for GPO.

---

## Step 11 — Deployment Checklist

- [ ] Schema extended (`Update-LapsADSchema` confirmed via ADSI Edit)
- [ ] Self-permission granted on server OU (`Set-LapsADComputerSelfPermission`)
- [ ] GPO created and linked to correct OU
- [ ] Core settings configured (backup, age, length, complexity, admin account name)
- [ ] Authorized decryptors group populated
- [ ] Post-authentication action set to reset-on-logoff
- [ ] Delegation completed for Helpdesk / Ops / Security / Automation
- [ ] `gpupdate /force` run and `rsop.msc` confirms application
- [ ] `Get-LapsADPassword` returns a valid password
- [ ] `Reset-LapsPassword` triggers rotation and appears in event log
- [ ] Legacy LAPS (the old CSE-based MSI product) uninstalled if previously present

---

## Notes

- If you previously ran legacy LAPS (Microsoft's original CSE/MSI-based product), uninstall the old client and remove its GPO before applying this one — running both concurrently causes conflicting password writes.
- Pilot on a small security-filtered group before expanding to the full server OU.
- Review the authorized decryptors group membership on a regular cadence as part of access reviews.

---

[← Back to Compute Track](README.md) | [Next: LAPS Risks & Legacy Migration →](5-windows-laps-risks-and-legacy-migration.md)
