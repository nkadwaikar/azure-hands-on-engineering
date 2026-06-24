# Bastion + Just-In-Time (JIT) VM Access

Just-In-Time VM access adds a time-limited, on-demand approval layer on top of Azure Bastion. Port openings are temporary NSG rules managed by Microsoft Defender for Cloud — no standing inbound access exists between sessions.

## Quick Navigation

- [Prerequisites](#prerequisites)
- [Enable JIT on a VM](#step-1--enable-jit-on-a-vm)
- [Request JIT Access](#step-2--request-jit-access)
- [Verify the NSG Rule Was Opened](#step-3--verify-the-nsg-rule-was-opened)
- [Connect via Bastion After JIT Approval](#step-4--connect-via-bastion-after-jit-approval)
- [Verify JIT Rule Auto-Closes](#step-5--verify-jit-rule-auto-closes)
- [Combined Pattern](#combined-pattern--bastion--jit)
- [Disable JIT / Cleanup](#disable-jit--cleanup)

---

## Prerequisites

- Azure Bastion deployed and healthy — complete [1-Azure Bastion.md](../Azure%20Bastion/1-Azure%20Bastion.md) first
- **Microsoft Defender for Cloud** enabled with the **Defender for Servers** plan active on the subscription
- The requesting user must have both **Security Reader** and **Virtual Machine Contributor** roles on the target VM

---

## Step 1 — Enable JIT on a VM

1. Go to **Microsoft Defender for Cloud** → **Workload Protections**
2. Select **Just-in-time VM access**
3. Find your VM → Click **Enable JIT on 1 VM**
4. Configure allowed ports: `3389` (RDP) or `22` (SSH)
5. Set max request time (e.g., 3 hours)
6. Click **Save**

---

## Step 2 — Request JIT Access

1. Go to **Defender for Cloud** → **JIT VM Access**
2. Select your VM → Click **Request Access**
3. Enter justification, IP range, and time window
4. Click **Open Ports**

---

## Step 3 — Verify the NSG Rule Was Opened

1. Go to **Virtual Machines** → Select your VM
2. Click **Networking** → **Network Security Group**
3. Check **Inbound security rules** — you should see a temporary rule allowing RDP/SSH from your requested IP range with a high priority number (e.g., `100`)
4. Note the rule includes an expiry; it will be auto-removed after the time window

---

## Step 4 — Connect via Bastion After JIT Approval

1. Go to **Virtual Machines** → Select your VM
2. Click **Connect** → Choose **Bastion**
3. Enter your credentials (or retrieve from Key Vault — see [1-Azure Bastion.md § Password from Key Vault](../Azure%20Bastion/1-Azure%20Bastion.md#6-password-from-azure-key-vault-secretless-access-pattern))
4. Click **Connect** — a browser-based session opens
5. Confirm the session is active

---

## Step 5 — Verify JIT Rule Auto-Closes

After the time window expires:

1. Go back to **Networking** → **Network Security Group** → **Inbound security rules**
2. Confirm the temporary JIT rule has been removed automatically
3. Any new connection attempts will be blocked until JIT is requested again

---

## Combined Pattern — Bastion + JIT

- JIT controls **when** the port is open (time-boxed)
- Bastion controls **how** you connect (no public IP, browser-based)
- Together they eliminate standing access and reduce the attack surface to near zero

---

## Disable JIT / Cleanup

### Disable JIT on a VM

1. Go to **Microsoft Defender for Cloud** → **Just-in-time VM access**
2. Find your VM → Click the **...** menu → **Remove JIT**
3. Confirm — inbound NSG rules return to their default state

### Verify NSG Rules Are Restored

1. Go to **Virtual Machines** → Select your VM
2. Click **Networking** → **Network Security Group** → **Inbound security rules**
3. Confirm no temporary JIT rules remain
4. RDP/SSH traffic is now governed solely by your baseline NSG rules

---

[← Azure Bastion — Secure VM Access](../Azure%20Bastion/1-Azure%20Bastion.md) | [↑ Track README](Readme.md) | [↑ Repo README](../README.md)
