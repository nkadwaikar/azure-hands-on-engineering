# On-Prem Hyper-V Lab Setup for Azure Arc

> **Companion to:** [Azure Arc Hybrid Server Architecture (with Defender for Servers)](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) — the production design guide this lab validates.
>
> This guide walks through building a disposable Hyper-V lab that behaves like an on-prem environment, so you can validate the full Arc onboarding flow before rolling out to production.

---

## Table of Contents

- [Why a Lab, Not Just Azure VMs](#why-a-lab-not-just-azure-vms)
- [Step 1: Hyper-V Host Prerequisites](#step-1-hyper-v-host-prerequisites)
- [Step 1a: Domain Controller or File Server?](#step-1a-do-you-need-a-domain-controller-or-file-server)
- [Step 2: Networking](#step-2-networking)
- [Step 3: Create the VMs](#step-3-create-the-vms)
- [Step 4: Prepare the Azure Side](#step-4-prepare-the-azure-side)
- [Step 5: Onboard the VMs](#step-5-onboard-the-vms)
- [Step 6: Verify](#step-6-verify)
- [Step 7: Wire Up Governance End-to-End](#step-7-wire-up-governance-end-to-end)
- [Step 8: What to Actually Test](#step-8-what-to-actually-test)
- [Step 9: Decommission](#step-9-decommission)
- [Notes](#notes)
- [Architecture Doc Reference Map](#architecture-doc-reference-map)

---

## Why a Lab, Not Just Azure VMs

Azure VMs are already native ARM resources with built-in ARM resource IDs and never go through the CMA onboarding flow. To actually exercise the Connected Machine Agent, the outbound-endpoint connectivity model, tagging-at-onboarding, and policy/Defender enrollment described in the architecture doc, you need machines that Azure does **not** already know about — that's what a Hyper-V lab gives you: disposable "on-prem" VMs.

---

## Step 1: Hyper-V Host Prerequisites

1. Windows Server (Datacenter/Standard)
2. Enable Hyper-V: **Control Panel → Programs → Turn Windows features on or off → Hyper-V** (or `Install-WindowsFeature -Name Hyper-V -IncludeManagementTools` on Windows Server), then reboot.
3. Confirm virtualization is enabled in host BIOS/UEFI (Intel VT-x / AMD-V).
4. Sizing: 2–4 VMs is enough to exercise Windows + Linux, Prod + Non-Prod tagging, and optionally the proxy/Private Link path. Budget roughly 2 vCPU / 4–8 GB RAM / 60 GB disk per VM.
5. The Hyper-V host itself needs outbound internet access — the VMs will inherit this via the virtual switch in Step 2. This is the single most common blocker in nested/isolated environments, so confirm it before building VMs.

---

## Step 1a: Do You Need a Domain Controller or File Server?

Not by default. Arc onboarding (CMA install + `azcmagent connect`) works fine on a plain workgroup VM — no domain membership required. Only build these if you're specifically testing one of the following:

| Extra VM | Only needed if... |
| --- | --- |
| **Domain Controller (AD DS)** | You want to test the **GPO bulk-onboarding method** — GPO deployment requires AD-joined machines. If you're only testing the custom script or SCCM methods, skip this. |
| **File Server** | You want a realistic file-share workload for **File Integrity Monitoring**. Monitoring `/etc` or `C:\Windows\System32` on any generic VM already exercises FIM — a dedicated file server is only useful if you specifically want to simulate shared-file paths. |

For everything else in this guide — onboarding, tagging, RBAC, policy, Defender, Automation, alerting — plain workgroup VMs are sufficient. If you do build a DC, budget an extra VM (2 vCPU / 4 GB RAM is enough for the AD DS role) and join the other VMs to the domain before testing the GPO onboarding path.

---

## Step 2: Networking

The VMs must be able to reach the required outbound HTTPS endpoints (see [Architecture Doc Reference Map](#architecture-doc-reference-map) → Section 3.2). No inbound access is ever required.

1. **Hyper-V Manager → Virtual Switch Manager → New virtual network switch.**
2. Choose one:
   - **External** — bridges lab VMs directly to your host's physical NIC; simplest option, VMs get real network-reachable addresses (via DHCP or static).
   - **Internal + NAT** — keeps lab VMs off your LAN; requires a NAT rule on the host (`New-NetNat` in PowerShell) so VMs can still reach the internet. Use this if you don't want the lab visible on your physical network.
3. **Optional — Private Link / HTTPS proxy path:** Stand up a small proxy VM (or a NAT rule with proxy software) in front of the subnet so the other VMs route through it, mirroring a restricted on-prem network.
4. Assign the virtual switch to each VM you create in Step 3.

---

## Step 3: Create the VMs

1. Download OS evaluation media — e.g. **Windows Server 2022 Evaluation** ISO, and/or **Ubuntu Server** (or another supported Linux distro).
2. **Hyper-V Manager → New → Virtual Machine.**
   - **Generation 2** recommended for Windows Server 2022 and modern Linux (Secure Boot may need disabling for some Linux distros — check the distro's Hyper-V Gen 2 guidance).
   - Attach the ISO under **Installation Options**.
   - Assign the virtual switch created in Step 2.
   - Allocate 2–4 vCPU, 4–8 GB RAM, 60 GB dynamic disk.
3. Install the OS. Set a hostname convention that reflects the environment and intended tags, e.g. `prod-win01`, `prod-lnx01`.
4. Confirm each VM has outbound internet: `Test-NetConnection management.azure.com -Port 443` (Windows) or `curl -Iv https://management.azure.com` (Linux).

---

## Step 4: Prepare the Azure Side

1. **Resource group:** Portal → **Resource groups → + Create** → name it `rg-arc-servers-prod`.
2. **(Optional) Dedicated Log Analytics workspace:** Portal → **Log Analytics workspaces → + Create** → `law-arc-servers-prod`, so telemetry is kept separate from other workspaces.
3. **Resource provider registration:** Confirm the following are registered on the subscription:
   - `Microsoft.HybridCompute`
   - `Microsoft.GuestConfiguration`
   - `Microsoft.HybridConnectivity`

   To register via the portal:

   1. Go to **Subscriptions** → select your subscription → **Resource providers** (under *Settings*).
   2. Search for each namespace, select it, then click **Register**:
      - `Microsoft.HybridCompute`
      - `Microsoft.GuestConfiguration`
      - `Microsoft.HybridConnectivity`
   3. Refresh the list — wait until each shows **Status: Registered** before proceeding (can take a few minutes).
4. **Tag:** Use `Environment: Prod` so resources are filterable and correctly scoped by policy initiatives.

---

## Step 5: Onboard the VMs

Follow the single-server onboarding flow from the architecture doc, targeting your resource group:

1. Portal → **Azure Arc → Machines → + Add/Create → Any environment → Generate script**.
2. Subscription = your subscription; Resource group = `rg-arc-servers-prod`; Region = your choice.
3. Connectivity method: **Public endpoint**, or **Proxy server** if you built the proxy path in Step 2.
4. **Arc gateway resource:** Create new.
5. **Authentication:** Authenticate machine automatically. This creates a new Azure Arc service principal for onboarding the machine.
6. **Tags:** Apply `Environment: Prod` plus any additional tags (e.g. `Criticality: Tier1`).
7. **Select deployment method:** Select Basic Script.
8. **Download** the script.
9. Get the script onto each VM — easiest options:
   - Windows VM: RDP in and copy-paste, or re-download the script directly inside the VM.
   - Validate `$ServicePrincipalId` and `$ServicePrincipalClientSecret` (create a new secret and update it in your script; otherwise it will fail).
10. Run it:
   - **Windows:** right-click → *Run with PowerShell* (as Administrator)
   if you get timeout error then
   Fix: Disable IPv6 on the VM NIC
This is the fastest and cleanest fix.

Run this inside the VM:

powershell
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
Then reboot:

powershell
Restart-Computer
After reboot, test again:

powershell
Test-NetConnection www.microsoft.com -Port 443
You should now see IPv4 addresses like:

Code
RemoteAddress : 23.45.xxx.xxx
TcpTestSucceeded : True
11.  Run Onboaring Script Again

---

## Step 6: Verify

1. **Azure Arc → Machines** — confirm **Status: Connected** for each VM within a few minutes.
2. Check **Tags**, **Resource Group**, and **Region** landed correctly.
3. **Extensions** tab — confirm AMA appears once policy assignment executes (if you've assigned a policy initiative to the RG).
4. **Microsoft Defender for Cloud → Inventory** — confirm the VMs appear (requires Defender for Servers plan to be enabled on the subscription).
5. **Troubleshooting:** If a VM doesn't connect, re-check outbound connectivity to the required Arc endpoints from inside the VM. This is the most common failure point, especially with Internal+NAT switches or a proxy in the path.

---

## Step 7: Wire Up Governance End-to-End

Exercise the same RBAC, policy, and automation patterns from the architecture doc, scoped to `rg-arc-servers-prod`.

### RBAC

1. Portal → `rg-arc-servers-prod` → **Access control (IAM)** → **+ Add role assignment**.
2. Assign `Hybrid-Server-Reader`, `Hybrid-Server-Operator`, and `Security-Operator` here, scoped to this resource group only.
3. Validate with a low-privilege account: confirm a `Hybrid-Server-Reader` can view but not restart a VM, and an `Operator` can restart/manage extensions but not touch policy.

### Policy Initiative

1. Portal → **Policy → Definitions** → find your `Arc-Server-Baseline` initiative (or the built-ins it's composed of).
2. **Assignments** → **Assign initiative** → scope = `rg-arc-servers-prod` (not subscription-wide, to prevent unintended cascade).
3. Confirm the AMA/Guest Configuration/tagging policies evaluate and remediate against your VMs: **Policy → Compliance**, filter to `rg-arc-servers-prod`.
4. Scope is the isolation boundary — not separate copies of the initiative.

### Automation / Runbooks

1. Use the **prod Automation Account** — point it at `rg-arc-servers-prod`.
2. Create/import runbooks (e.g. restart or tag-remediation) and target explicitly by resource group (`rg-arc-servers-prod`) or tag (`Environment: Prod`) — never by "all Arc machines in subscription."
3. Run against the VMs, confirm behavior, then check run history/logs.
4. Optionally test **Update Manager** patch assessment the same way — same resource-group scoping rule applies.

### Defender for Servers

1. To test Defender end-to-end, enable the plan at subscription level (note: it applies broadly and adds cost for the duration of the lab).
2. Confirm lab VMs pick up Secure Score recommendations, and optionally test JIT access against a lab VM specifically.
3. When you decommission in Step 9, remember Defender coverage disappears with the Arc resource, but the subscription-level plan itself stays enabled — disable it manually if no longer needed.

The isolation principle throughout: **scope, not separate copies** — every assignment above targets `rg-arc-servers-prod` (or a tag/RG filter) explicitly.

---

## Step 8: What to Actually Test

Use the lab to validate the parts of the architecture that are risky to get wrong in production:

 | What to test | Notes |
| --- | --- |
| Tagging and policy compliance | Tags set at onboarding drive policy scope and cost attribution |
| AMA data flow into Log Analytics | Confirms the monitoring pipeline is wired correctly |
| Defender for Cloud onboarding and Secure Score baseline | Validates enrollment and initial posture |
| Update Manager patch assessment | Confirms Arc machines surface in Update Manager |
| File Integrity Monitoring | Especially if you built a file server in Step 1a |
| Private Link / proxy connectivity | Only if you built the proxy path in Step 2 |
| RBAC role boundaries and policy remediation | Validates the real role definitions end-to-end (see [Step 7](#step-7-wire-up-governance-end-to-end)) |
| Automation runbook targeting and execution | Confirms runbooks target by RG/tag, not subscription-wide (see [Step 7](#step-7-wire-up-governance-end-to-end)) |
| The onboarding script and portal flow | So whoever runs the real rollout has already seen it work end-to-end |

---

## Step 9: Decommission

1. **Azure Arc → Machines** → select the machine(s) → **Delete** to remove the ARM resource.
2. Optionally uninstall the CMA inside each VM first (not required if you're deleting the VM entirely).
3. Delete the Hyper-V VMs (or keep a checkpoint/snapshot from before onboarding if you want to re-run without rebuilding from scratch).
4. Remove the RBAC role assignments and policy initiative assignment scoped to `rg-arc-servers-prod` ([Step 7](#step-7-wire-up-governance-end-to-end)) — these don't auto-delete with the resource group in all cases, so confirm they're gone.
5. Disable the Defender for Servers plan if it is no longer needed ([Step 7](#step-7-wire-up-governance-end-to-end)).
6. Delete `rg-arc-servers-prod` (and `law-arc-servers-prod` if created) — this removes the Log Analytics workspace and any remaining Defender enrollment tied to it.

---

## Notes

- The isolation boundary is **scope** (resource group and tag filters), not separate copies — Step 7 reuses your real RBAC roles, policy initiatives, and Automation account, narrowly scoped to `rg-arc-servers-prod`.
- To test **at-scale / bulk onboarding** rather than single-server, clone 5–10 VMs and run the "Add multiple servers" custom script method — Hyper-V checkpoints make this fast to reset between runs.
- Snapshot each VM immediately after OS install, before running the onboarding script — makes it trivial to reset and re-test without rebuilding from ISO.

---

## Architecture Doc Reference Map

All section references point to [Azure Arc Hybrid Server Architecture](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md).

| This guide | Architecture doc section |
| --- | --- |
| Prod scope / resource groups | Section 2.1 — Subscriptions and Resource Groups |
| RBAC model | Section 2.3 — RBAC Model |
| Required outbound endpoints | Section 3.2 — Network & Identity |
| Private Link / proxy path | Section 3.3 — Private Connectivity Options |
| Single-server onboarding flow | Section 3.5 — Onboarding a Single Server |
| Onboarding verification | Section 3.6 — Onboarding Verification |
| Monitoring pipeline (AMA) | Section 4.1 — Monitoring Pipeline |
| Update Management | Section 4.2 — Update Management |
| Policy initiative | Section 5.1 — Azure Policy for Arc Servers |
| Defender for Cloud integration | Section 6.1 — Defender for Cloud Integration |
| Secure Score | Section 6.3 — Secure Score & Recommendations |
| JIT Access | Section 6.5 — Just-in-Time (JIT) Admin Access |
| File Integrity Monitoring | Section 6.6 — File Integrity Monitoring (FIM) |
| Runbooks & workflows | Section 7.1 — Runbooks & Workflows |
| Bulk onboarding (GPO/script) | Section 7.2 — Onboarding Multiple Servers at Scale |
| Runbook version control & testing | Section 7.3 — Runbook Version Control & Testing |
| Decommissioning | Section 7.5 — Decommissioning |

---

## Related

- [Azure Arc Hybrid Server Architecture (with Defender for Servers)](1-Azure%20Arc%20Hybrid%20Server%20Architecture.md) — production design guide this lab validates
- [Azure Arc Track Overview](README.md)
- [Back to Azure Hands-On Engineering](../README.md)
