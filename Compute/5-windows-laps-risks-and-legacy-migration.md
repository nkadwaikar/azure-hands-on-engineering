# Windows LAPS — Production Risk Notes & Legacy Migration

> **Why this matters:** A LAPS deployment that looks correctly configured in GPMC can silently fail to rotate passwords if legacy emulation mode takes over — there is no error, the server simply keeps following the old policy. This document covers the three irreversible steps in the main deployment guide, the clean-up sequence required when a legacy LAPS client was previously installed, and the event log evidence that confirms the transition actually happened.

This document supplements [4-windows-laps-deployment-guide.md](4-windows-laps-deployment-guide.md). It covers the irreversible and high-risk steps flagged during deployment review, and the legacy LAPS migration procedure for environments where the legacy MSI/CSE-based LAPS client was previously installed — the main guide assumes a clean environment, which is rarely true in production.

Last validated on: August 2026
Portal experience note: Registry paths and event log queries apply to Windows Server 2019/2022/2025. PowerShell steps require RSAT or execution on a Domain Controller.

> **Note:** If you are in a clean environment with no prior LAPS deployment, [4-windows-laps-deployment-guide.md](4-windows-laps-deployment-guide.md) is sufficient. Return here if any target server has previously run the legacy LAPS client or if deployment review flags steps for explicit sign-off.

---

## Module / Track Structure

```text
Compute/
├── README.md                                      ← Track entry point
├── 1-build-base-vm.md                             ← Lab 1: Build a Base VM
├── 3-install-iis.md                               ← Lab 2: Install IIS
├── 2-sysprep-vm.md                                ← Lab 3: Sysprep (Azure-safe)
├── 4-windows-laps-deployment-guide.md             ← Lab 4: Windows LAPS Deployment
└── 5-windows-laps-risks-and-legacy-migration.md   ← Lab 5: LAPS Risks & Legacy Migration (you are here)
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [High-Risk Steps](#high-risk-and-hard-to-reverse-steps)
  - [Schema Extension](#1-schema-extension-update-lapsadschema)
  - [OU Permission Changes](#2-ou-permission-changes-set-lapsadcomputerselfpermission)
  - [Delegation Wizard](#3-delegation-wizard--custom-attribute-selection-step-7)
- [Legacy LAPS Migration](#legacy-laps-migration)
  - [Migration Approach](#migration-approach--choose-one)
  - [Cleanup Steps](#cleanup-steps-do-not-skip)
  - [Verifying the Transition](#verifying-the-transition-actually-happened)
  - [Forcing Emulation Mode Off](#forcing-emulation-mode-off-edge-case)
- [Updated Deployment Checklist](#updated-deployment-checklist)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Prior lab | [4-windows-laps-deployment-guide.md](4-windows-laps-deployment-guide.md) completed or in progress |
| Context | Familiarity with the LAPS deployment steps (schema extension, OU permissions, GPO configuration) |
| Tools | PowerShell (Domain Controller or RSAT workstation), ADSI Edit, ADUC, GPMC |
| Estimated Time | 20–30 minutes (risk review); 30–60 minutes for legacy migration |

---

## 2. Learning Objectives

By the end of this document, you will be able to:

- Identify the three hard-to-reverse steps in the LAPS deployment and their specific failure modes
- Execute a clean legacy LAPS to Windows LAPS cutover (Option A) or a coexistence transition (Option B)
- Confirm Windows LAPS is in control using Event ID 10020 and 10029, not just "the GPO looks applied"
- Clean up the legacy LAPS MSI client, legacy AD attributes, admx/adml templates, and GPO object in the correct order
- Use the registry diagnostic override to confirm emulation mode is off on a specific test machine before committing to a broader rollout

---

## 3. Scenario

**The LAPS deployment guide covers a clean environment. This document applies when any target server has previously run the legacy LAPS CSE client, or when the deployment review flags irreversible steps that need explicit sign-off.**

A production AD environment with existing servers running the legacy LAPS client requires migration to Windows LAPS. Skipping the cleanup procedure results in servers that appear compliant in GPMC but are silently running in emulation mode — no error is raised, password rotation appears to succeed, but the old policy is still in control.

---

## High-Risk and Hard-to-Reverse Steps

### 1. Schema Extension (`Update-LapsADSchema`)

- Extends the **forest-wide** AD schema. Schema changes are additive and
  cannot be cleanly rolled back — removing schema attributes afterward is
  unsupported by Microsoft and generally not attempted in production.
- **Do this once, in a lab/test forest first**, before touching production,
  if you have never run it before.
- Requires Schema Admins (or Enterprise Admins) rights, and replicates to
  every DC in the forest — plan for replication convergence time in
  multi-site environments before assuming it's "done."

### 2. OU Permission Changes (`Set-LapsADComputerSelfPermission`)

- Grants computer objects self-write permission on the LAPS password
  attributes at the **OU level**. This is reversible in principle (permissions
  can be removed), but doing so incorrectly can silently break password
  rotation across every server in that OU with no obvious error — it just
  stops writing.
- Test on a small pilot OU with 1–2 non-critical servers before applying
  to the full server OU.
- Verify with `Get-Acl` or the ADUC Advanced Security dialog after applying,
  don't assume the cmdlet succeeded silently.

### 3. Delegation Wizard / Custom Attribute Selection (Step 7)

- The stock **Delegation of Control Wizard** doesn't list LAPS attributes in
  its common-task list — you must use **"Create a custom task to delegate"**
  and manually select the attributes.
- The exact attribute set depends on schema version and whether you're using
  encrypted vs. plaintext storage:
  - `ms-LAPS-Password` (plaintext, legacy Windows LAPS mode)
  - `ms-LAPS-EncryptedPassword` (encrypted mode — this is what this
    deployment uses)
  - `ms-LAPS-EncryptedPasswordHistory` (if password history is enabled)
  - `ms-LAPS-PasswordExpirationTime`
- **Double-check against your actual schema** (via ADSI Edit) rather than
  assuming the attribute list — Microsoft has changed attribute names between
  early previews and GA, and a custom admin account name doesn't change the
  attribute set (it's the same attributes regardless of which local account
  is targeted), but password history settings do add an extra attribute you
  may forget to delegate.

---

## Legacy LAPS Migration

If **any** server in scope has ever run the original Microsoft LAPS (the
MSI/CSE-based tool, sometimes called "legacy LAPS"), this section applies.
Skipping it is what causes the "silent password-write conflict" risk flagged
in review.

### Legacy Emulation Mode Risk

If a device meets Windows LAPS's minimum OS build and is joined to a domain
where a **legacy LAPS GPO is still linked**, Windows LAPS automatically enters
**legacy emulation mode** and honors the old policy instead of your new one —
even if your new Windows LAPS GPO is also linked and looks correctly
configured. This is silent: there's no error, the server just keeps behaving
like it's on the old policy.

Additionally, **Windows LAPS and legacy LAPS must never target the same local
account simultaneously** — doing so is unsupported and leads to inconsistent
or conflicting password rotation.

### Migration approach — choose one

**Option A: Immediate cutover (recommended for most server estates)**

1. Remove or unlink the legacy LAPS GPO from the server OU.
2. Link the new Windows LAPS GPO to the same OU (do this as close to
   simultaneously as practical — no need to be exact to the second, just
   don't leave a long gap).
3. Target the **same local admin account name** the legacy policy used, to
   avoid needing a second account.
4. Run `gpupdate /force` on a test server and confirm rotation via the event
   log (see validation section below).
5. Once confirmed across your pilot group, proceed to cleanup (below).

**Option B: Coexistence (only if you have unsupported/mixed OS versions in
the same OU)**

1. Configure a **second local admin account** on managed devices — Windows
   LAPS and legacy LAPS cannot target the same account during the
   transition period.
2. Apply the Windows LAPS policy to the new account while legacy LAPS
   continues managing the original account.
3. Once all devices are confirmed on Windows LAPS, decommission the
   original legacy-managed account and remove the legacy policy.

This path adds a second privileged local account to every server for the
duration of the migration — extra attack surface, so only use it if you
genuinely have unsupported OS versions mixed into the same OU and can't
separate them.

### Cleanup steps (do not skip)

Skipping these is exactly what causes "it looks migrated but isn't":

1. **Uninstall the legacy LAPS client** from each device:
   ```powershell
   MsiExec.exe /x {97E2CA7B-B657-4FF7-A6DB-30ECC73E1E28}
   ```
2. **Clear the legacy AD attributes** on computer objects no longer in
   emulation mode:
   ```powershell
   Set-ADComputer -Identity SERVER01 -Clear ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime
   ```
3. **Remove the legacy GPO and its admx/adml templates** (`AdmPwd.admx` /
   `AdmPwd.adml`) from your central policy store once no OU references them.
4. **Delete the legacy GPO object** in GPMC after confirming no devices
   depend on it.

### Verifying the transition actually happened

Don't rely on "the GPO looks applied" — confirm via event log evidence:

- **Event ID 10020** — LAPS successfully updated the local admin account
  password.
- **Event ID 10029** — LAPS successfully updated Azure AD/Entra with the new
  password (hybrid/Entra-joined devices only — not relevant if you're
  AD-only as in this deployment, but useful to know if scope expands later).

```powershell
Get-WinEvent -LogName Microsoft-Windows-LAPS/Operational |
  Where-Object { $_.Id -in 10020,10029 } |
  Select-Object -First 10 TimeCreated, Id, Message
```

If you still see legacy CSE-related events instead of these, the device is
likely still in emulation mode — check for a lingering legacy GPO link before
assuming the client itself is broken.

### Forcing emulation mode off (edge case)

If a legacy GPO can't be fully removed yet (e.g., shared OU with unsupported
devices) but you need to confirm Windows LAPS is truly in control on a
specific test machine, you can force emulation mode off locally:

```
Registry path: HKLM\Software\Microsoft\Windows\CurrentVersion\LAPS\Config
Value: BackupDirectory (REG_DWORD)
Set to: 0
```

This is a **diagnostic/testing override**, not a permanent fix — use it to
confirm Windows LAPS processes correctly on a machine, then resolve the
underlying GPO overlap rather than leaving this registry override in place
long-term.

---

## Updated Deployment Checklist

- [ ] Schema extension tested in lab before production (`Update-LapsADSchema`)
- [ ] OU self-permission tested on pilot OU before full rollout
- [ ] **Legacy LAPS presence confirmed/ruled out** across target OU
- [ ] If legacy LAPS present: migration approach chosen (cutover vs. coexistence)
- [ ] Legacy GPO unlinked at the same time new GPO is linked (cutover path)
- [ ] Legacy client uninstalled (`MsiExec.exe /x {97E2CA7B-B657-4FF7-A6DB-30ECC73E1E28}`)
- [ ] Legacy AD attributes cleared (`ms-Mcs-AdmPwd`, `ms-Mcs-AdmPwdExpirationTime`)
- [ ] Legacy admx/adml templates and GPO object removed
- [ ] Delegation attributes verified against actual schema (not assumed)
- [ ] Event IDs 10020 (and 10029 if applicable) confirmed in Operational log
- [ ] No lingering legacy GPO links anywhere in the target OU tree

---

[← Back to LAPS Deployment Guide](4-windows-laps-deployment-guide.md) | [← Back to Compute Track](README.md)
