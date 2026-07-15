# Azure Update Manager — Arc Server Patch Verification Toolkit

A small set of PowerShell scripts for confirming that an Azure Arc-connected Windows server is actually being patched by **Azure Update Manager** - and only Azure Update Manager, not native Windows Update running independently in the background.

These came out of a real troubleshooting session where a server's assessment showed updates as "Pending" indefinitely, and it turned out the underlying patch job simply wasn't being triggered on a schedule. Along the way it became worth confirming, definitively, that once patching *did* work, it was Update Manager doing the installing and not Windows Update quietly doing its own thing.

## Prerequisites

| Requirement | Detail |
| --- | --- |
| **OS** | Windows Server, Arc-connected (`azcmagent show` returns `Connected`) |
| **Shell** | PowerShell run as Administrator |
| **Extension** | `Microsoft.CPlat.Core.WindowsPatchExtension` (Update Manager's patch extension) installed and healthy on the machine |

## Scripts

### 1. [Azure_Only_Patching_Mode.ps1](Azure_Only_Patching_Mode.ps1)

Locks a server into "Azure-only" patching by disabling native Windows Update auto-install. Run this once, typically as part of Arc onboarding.

**What it does:**

- Sets `NoAutoUpdate = 1` (blocks WU's own scan/download/install cycle)
- Sets `AUOptions = 2` (notify-only, no silent installs)
- Disables Automatic Maintenance (stops the classic silent 2 AM WU install path)
- Ensures the `wuauserv` service is running (Update Manager still needs it as the underlying install engine - it just shouldn't be self-triggering)
- Restarts the Arc extension services (`himds`, `ExtensionService`, `GCArcService`)

```powershell
.\Azure_Only_Patching_Mode.ps1
```

## 2. [Verifying_Azure-only_patching_mode.ps1](Verifying_Azure-only_patching_mode.ps1)

Read-only check that confirms the settings from script 1 are actually in place. Safe to run any time, including on a schedule.

```powershell
.\Verifying_Azure-only_patching_mode.ps1
```

Checks: `NoAutoUpdate`, `AUOptions`, Automatic Maintenance state, `wuauserv` status, and the two core Arc services (`himds`, `GCArcService`, `ExtensionService`). Every check prints `PASS` or `FAIL` - a clean run should be all green.

### 3. [Verify-AUM-Patch-Source.ps1](Verify-AUM-Patch-Source.ps1)

The main verification script. After a patch cycle completes, this confirms *which* KBs actually installed and whether they came in through Update Manager.

```powershell
.\Verify-AUM-Patch-Source.ps1
```

Edit the `$kbList` array at the top of the script to match the KBs you're checking (copy them from the "Updates summary" view in the Azure Portal for that machine).

It checks four things:

1. Orchestration mode (`NoAutoUpdate` still enforced)
2. Each KB's `Get-HotFix` record - specifically whether `InstalledBy` is `NT AUTHORITY\SYSTEM` (platform-driven) vs. blank or a named account
3. Correlates KBs against Update Manager's JSON event files (note: these are often cleaned up shortly after upload to Azure, so an empty result here isn't necessarily bad news - it just means the Portal's History tab is the better source for that particular KB)
4. Pending reboot state

**Important limitation:** `Get-HotFix` only reads `Win32_QuickFixEngineering`, which covers classic CBS-based patches (Security/Cumulative updates). It will *not* show Defender definition updates, Defender platform updates, or MSRT (Malicious Software Removal Tool) - those install via their own mechanisms. If those show as "NOT FOUND," that's expected, not a failure. For those, cross-check with:

```powershell
Get-MpComputerStatus | Select-Object AntivirusSignatureLastUpdated, AntivirusSignatureVersion
```

### 4. [Monitor_Azure_patching.ps1](Monitor_Azure_patching.ps1)

A live-tail style monitor for watching a patch job happen in real time. Useful for testing an on-demand run or watching a scheduled maintenance window.

```powershell
.\Monitor_Azure_patching.ps1
```

It polls every 5 seconds and only prints when something actually changes:

- `GCArcService` status transitions
- New lines appended to the extension log (`WindowsUpdateExtension.log`), tagged as activity, completion, or failure
- Reboot-pending flag transitions

Runs until you `Ctrl+C` out of it. On a quiet server it will print nothing after the initial baseline - that's expected, not a hang.

## License

MIT - use freely, no warranty.
