# On-Prem Hyper-V Lab Setup for Azure Arc

> Companion to *Azure Arc Hybrid Server Architecture (with Defender for Servers)*. This guide walks through building a disposable Hyper-V lab that behaves like an on-prem environment, so you can validate the real Arc onboarding flow (Section 3.5) before rolling out to production.

Last validated on: 2026-07-02

> **Note:** This is a lab setup guide, not a production pattern. Keep everything here isolated from `rg-arc-servers-prod`/`rg-arc-servers-nonprod` (Section 2.1) using a dedicated resource group and, ideally, a dedicated workspace.

---

## Quick Navigation

- [Why a Lab, Not Just Azure VMs](#why-a-lab-not-just-azure-vms)
- [Step 1: Hyper-V Host Prerequisites](#step-1-hyper-v-host-prerequisites)
- [Step 1a: Domain Controller or File Server?](#step-1a-do-you-need-a-domain-controller-or-file-server)
- [Step 2: Networking](#step-2-networking)
- [Step 3: Create the Lab VMs](#step-3-create-the-lab-vms)
- [Step 4: Prepare the Azure Side](#step-4-prepare-the-azure-side-isolated-lab-scope)
- [Step 5: Onboard the Lab VMs](#step-5-onboard-the-lab-vms)
- [Step 6: Verify](#step-6-verify)
- [Step 7: Wire Up Governance End-to-End](#step-7-wire-up-governance-end-to-end-lab-scoped)
- [Step 8: What to Actually Test](#step-8-what-to-actually-test)
- [Step 9: Teardown](#step-9-teardown)
- [Notes](#notes)

---

## Why a Lab, Not Just Azure VMs

Azure VMs are already native ARM resources with built-in ARM resource IDs and never go through the CMA onboarding flow. To actually exercise the Connected Machine Agent, the outbound-endpoint connectivity model, tagging-at-onboarding, and policy/Defender enrollment described in the architecture doc, you need machines that Azure does **not** already know about — that's what a Hyper-V lab gives you: disposable "on-prem" VMs.

---

## Step 1: Hyper-V Host Prerequisites

1. Windows Server (Datacenter/Standard)
2. Enable Hyper-V: **Control Panel → Programs → Turn Windows features on or off → Hyper-V** (or `Install-WindowsFeature -Name Hyper-V -IncludeManagementTools` on Windows Server), then reboot.
3. Confirm virtualization is enabled in host BIOS/UEFI (Intel VT-x / AMD-V).
4. Sizing for a Lab: 2–4 lab VMs is enough to exercise Windows + Linux, Prod + Non-Prod tagging, and optionally the proxy/Private Link path. Budget roughly 2 vCPU / 4–8 GB RAM / 60 GB disk per VM.
5. The Hyper-V host itself needs outbound internet access — the lab VMs will inherit this via the virtual switch in Step 2. This is the single most common blocker in nested/isolated lab environments, so confirm it before building VMs.

---

## Step 1a: Do You Need a Domain Controller or File Server?

Not by default. Arc onboarding (CMA install + `azcmagent connect`) works fine on a plain workgroup VM — no domain membership required. Only build these if you're specifically testing one of the following:

| Extra VM | Only needed if... |
| --- | --- |
| **Domain Controller (AD DS)** | You want to test the **Group Policy bulk-onboarding method** (Section 7.2) — GPO deployment requires AD-joined machines. If you're only testing the custom script or SCCM methods, skip this. |
| **File Server** | You want a realistic file-share workload for **File Integrity Monitoring** (Section 6.6). Monitoring `/etc` or `C:\Windows\System32` on any generic VM already exercises FIM — a dedicated file server is only useful if you specifically want to simulate shared-file paths. |

For everything else in this guide — onboarding, tagging, RBAC, policy, Defender, Automation, alerting — plain workgroup VMs are sufficient. If you do build a DC, budget an extra VM (2 vCPU / 4GB RAM is enough for a lab-scale AD DS role) and join the other lab VMs to the domain before testing the GPO onboarding path.

---

## Step 2: Networking

The lab VMs must be able to reach the same outbound HTTPS endpoints listed in Section 3.2 of the architecture doc. No inbound access is ever required.

1. **Hyper-V Manager → Virtual Switch Manager → New virtual network switch.**
2. Choose one:
   - **External** — bridges lab VMs directly to your host's physical NIC; simplest option, VMs get real network-reachable addresses (via DHCP or static).
   - **Internal + NAT** — keeps lab VMs off your LAN; requires a NAT rule on the host (`New-NetNat` in PowerShell) so VMs can still reach the internet. Use this if you don't want the lab visible on your physical network.
3. If you intend to test the **Private Link / HTTPS proxy** path from Section 3.3, this is the natural place to insert it — stand up a small proxy VM (or a NAT rule with proxy software) in front of the lab subnet so the other lab VMs route through it, mirroring a restricted on-prem network.
4. Assign the virtual switch to each VM you create in Step 3.

---

## Step 3: Create the Lab VMs

1. Download evaluation media matching the OS table in Section 0 of the architecture doc — e.g. **Windows Server 2022 Evaluation** ISO, and/or **Ubuntu Server** (or another supported Linux distro).
2. **Hyper-V Manager → New → Virtual Machine.**
   - **Generation 2** recommended for Windows Server 2022 and modern Linux (Secure Boot may need disabling for some Linux distros — check the distro's Hyper-V Gen 2 guidance).
   - Attach the ISO under **Installation Options**.
   - Assign the virtual switch created in Step 2.
   - Allocate 2–4 vCPU, 4–8 GB RAM, 60 GB dynamic disk.
3. Install the OS. Set a hostname convention that reflects the Lab and intended tags, e.g. `lab-lab-win01`, `lab-lab-lnx01`.
4. Confirm each VM has outbound internet: `Test-NetConnection management.azure.com -Port 443` (Windows) or `curl -Iv https://management.azure.com` (Linux).

---

## Step 4: Prepare the Azure Side (Isolated Lab Scope)

Keep this separate from production per Section 2.1's landing zone pattern.

1. **Resource group:** Portal → **Resource groups → + Create** → name it `rg-arc-lab` (or similar) — do **not** reuse `rg-arc-servers-prod`/`-nonprod`.
2. **(Optional) Dedicated Log Analytics workspace:** Portal → **Log Analytics workspaces → + Create** → `law-arc-lab`, so Lab telemetry doesn't mix into production dashboards (mirrors Section 0.2's workspace setup).
3. **Resource provider registration:** confirm `Microsoft.HybridCompute`, `Microsoft.GuestConfiguration`, and `Microsoft.HybridConnectivity` are registered on the subscription (Section 0.1) — same check applies regardless of Lab or prod.
4. Decide on a Lab-specific tag value, e.g. `Environment: Lab`, so these resources are trivially filterable and excluded from prod-scoped policy initiatives (Section 5.1) if those initiatives are scoped broadly.

---

## Step 5: Onboard the Lab VMs

Follow the same single-server flow as Section 3.5 of the architecture doc, targeting the Lab resource group:

1. Portal → **Azure Arc → Machines → + Add/Create → Add a single server → Generate script**.
2. Subscription = your subscription; Resource group = `rg-arc-lab`; Region = your choice.
3. Connectivity method: **Public endpoint**, or **Proxy server** if you built the proxy path in Step 2.
4. Tags: apply `Environment: Lab` plus whatever else you want to test (e.g. `Criticality: Tier3`).
5. **Download** the script.
6. Get the script onto each Hyper-V VM — easiest options:
   - Windows lab VM: RDP into it and copy-paste, or re-download the script directly inside the VM (it has internet access).
   - Linux lab VM: `scp` it in, or `curl`/`wget` it directly if you host it somewhere reachable.
7. Run it:
   - **Windows:** right-click → *Run with PowerShell* (as Administrator)
   - **Linux:** `sudo bash <script-name>.sh`

---

## Step 6: Verify

Same checks as Section 3.6 of the architecture doc:

1. **Azure Arc → Machines** — confirm **Status: Connected** for each lab VM within a few minutes.
2. Check **Tags**, **Resource Group**, and **Region** landed correctly.
3. **Extensions** tab — confirm AMA appears once policy assignment executes (if you've assigned a policy initiative to the Lab RG).
4. **Microsoft Defender for Cloud → Inventory** — confirm the lab VMs appear (only if Defender for Servers plan is enabled on this subscription; enabling it just for a Lab is optional and affects cost).
5. If a VM doesn't connect, re-check outbound connectivity to the endpoints in Section 3.2 from inside the VM — this is the most common lab-specific failure point, especially with Internal+NAT switches or a proxy in the path.

---

## Step 7: Wire Up Governance End-to-End (Lab-Scoped)

To make this a real end-to-end test, exercise the same RBAC, policy, and automation patterns from the architecture doc — just scoped to `rg-arc-lab` only, never by reusing the literal production role assignments, initiative assignments, or Automation account targets.

### RBAC (mirrors Section 2.3)

1. Portal → `rg-arc-lab` → **Access control (IAM)** → **+ Add role assignment**.
2. Assign `Hybrid-Server-Reader`, `Hybrid-Server-Operator`, and `Security-Operator` here, scoped to this resource group only — do **not** add `rg-arc-lab` as an extra scope on the existing production role assignments.
3. Test with a low-privilege test account: confirm a `Hybrid-Server-Reader` can view but not restart a lab VM, and an `Operator` can restart/manage extensions but not touch policy.

#### Policy initiative (mirrors Section 5.1)

1. Portal → **Policy → Definitions** → find your `Arc-Server-Baseline` initiative (or the built-ins it's composed of).
2. **Assignments** → **Assign initiative** → scope = `rg-arc-lab` specifically (not subscription-wide, so it can't cascade to prod RGs). This is a genuine assignment of the same initiative, just scoped narrowly — not a copy, but scoping prevents any spillover.
3. Confirm the AMA/Guest Configuration/tagging policies actually evaluate and remediate against your lab VMs: **Policy → Compliance**, filter to `rg-arc-lab`.
4. This validates the real initiative logic end-to-end without ever touching prod resources, since scope is the isolation boundary here — not a separate copy.

#### Automation / runbooks (mirrors Section 7.1, 4.2)

1. Use a **non-prod Automation Account** (Section 7.3 already recommends maintaining one for staging) — point it at `rg-arc-lab`, not the production account.
2. Create/import a test runbook (e.g. a simple restart or tag-remediation runbook) and target it explicitly by resource group (`rg-arc-lab`) or tag (`Environment: Lab`) — never by "all Arc machines in subscription," which is the mistake that would let a Lab test reach prod.
3. Run it against the lab VMs, confirm behavior, then check the run history/logs.
4. Optionally test **Update Manager** patch assessment against the lab VMs the same way (Section 4.2) — same resource-group scoping rule applies.

#### Defender for Servers (mirrors Section 6.1)

1. If you want to test Defender end-to-end too, enable the plan at subscription level (it applies broadly — there's no RG-level opt-in for the base plan), but note this does add cost for the duration of the Lab.
2. Confirm lab VMs pick up Secure Score recommendations and, if desired, test JIT access (Section 6.5) against a lab VM specifically.
3. When you tear down in Step 9, remember Defender coverage disappears with the Arc resource, but the subscription-level plan itself stays enabled — disable it manually if it was only turned on for this Lab.

The isolation principle throughout: **scope, not separate copies**, is what keeps this safe — every assignment above targets `rg-arc-lab` (or a tag/RG filter) explicitly, so nothing can reach production even though you're using the same initiatives, roles, and Automation patterns you'll rely on for real.

---

## Step 8: What to Actually Test

Use the lab to validate the parts of the architecture that are risky to get wrong in production:

- Tagging and policy compliance (Section 5)
- AMA data flow into Log Analytics (Section 4.1)
- Defender for Cloud onboarding and Secure Score baseline (Section 6.1, 6.3)
- Update Manager patch assessment (Section 4.2)
- Private Link / proxy connectivity, if built in Step 2 (Section 3.3)
- RBAC role boundaries and policy remediation, end-to-end (Step 7)
- Automation runbook targeting and execution against real Arc-registered machines (Step 7)
- The onboarding script and portal flow itself, so whoever runs the real rollout has already seen it work end-to-end

---

## Step 9: Teardown

Follow the same pattern as Section 7.5, adapted for a disposable lab:

1. **Azure Arc → Machines** → select the lab machine(s) → **Delete** to remove the ARM resource.
2. Optionally uninstall the CMA inside each VM first (not required if you're deleting the VM entirely).
3. Delete the Hyper-V VMs (or keep a checkpoint/snapshot from before onboarding if you want to re-run the Lab later without rebuilding from scratch).
4. Remove the RBAC role assignments and policy initiative assignment scoped to `rg-arc-lab` (Step 7) — these don't auto-delete with the resource group in all cases, so confirm they're gone.
5. Disable the Defender for Servers plan if it was only enabled for this Lab (Step 7).
6. Delete `rg-arc-lab` (and `law-arc-lab` if created) once you're done — this removes the Log Analytics workspace, any remaining Defender enrollment tied to it, and keeps Lab clutter out of your production subscription.

---

## Notes

- The isolation boundary in this lab is **scope** (resource group and tag filters), not separate copies of everything — Step 7 deliberately reuses your real RBAC roles, policy initiatives, and Automation account, narrowly scoped, so the Lab proves out the actual production configuration rather than a parallel approximation of it.
- If you want to test the **at-scale / bulk onboarding** flow (Section 7.2) rather than just single-server, clone 5–10 lab VMs instead of 2–4 and run the "Add multiple servers" custom script method against them — Hyper-V checkpoints make this fast to reset between test runs.
- Snapshot each lab VM immediately after OS install, before running the onboarding script — makes it trivial to reset and re-test the onboarding flow repeatedly without rebuilding VMs from ISO each time.

---

[← Back to Azure Arc Hybrid Server Architecture Track](./README.md)
