# Bastion + Just-In-Time (JIT) VM Access

Just-In-Time VM access adds a time-limited, on-demand approval layer on top of Azure Bastion. Port openings are temporary NSG rules managed by Microsoft Defender for Cloud — no standing inbound access exists between sessions.

Last validated on: 2026-06-19
Portal experience note: Steps validated against Microsoft Defender for Cloud as of June 2026; labels can vary slightly by subscription and feature rollout.

> **Note:** This lab requires Azure Bastion deployed and the Defender for Servers plan active on the subscription. Complete [Azure Bastion](../Azure%20Bastion/1-Azure%20Bastion.md) first.

---

## Module / Track Structure

```text
Microsoft Defender for Cloud/
├── README.md                          ← Track entry point
├── 1-JIT.md                           ← Lab 1: Bastion + JIT VM Access (you are here)
└── 2-Defender-for-Servers.md          ← Lab 2: Workload Protection
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Enable JIT on a VM](#step-1--enable-jit-on-a-vm)
- [Request JIT Access](#step-2--request-jit-access)
- [Verify the NSG Rule Was Opened](#step-3--verify-the-nsg-rule-was-opened)
- [Connect via Bastion After JIT Approval](#step-4--connect-via-bastion-after-jit-approval)
- [Verify JIT Rule Auto-Closes](#step-5--verify-jit-rule-auto-closes)
- [Combined Pattern](#combined-pattern--bastion--jit)
- [Troubleshooting](#troubleshooting)
- [Why JIT Matters](#why-jit-matters-engineering-justification)
- [Disable JIT / Cleanup](#disable-jit--cleanup)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Security Reader** + **Virtual Machine Contributor** on the target VM |
| Subscription | **Defender for Servers** plan active on the subscription |
| Dependency | Azure Bastion deployed — complete [Azure Bastion](../Azure%20Bastion/1-Azure%20Bastion.md) first |
| Estimated Time | 30–45 minutes |
| Tools | Azure Portal only — no CLI required |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- Lab assumes a running VM with Bastion deployed from the Azure Bastion track.
- JIT NSG rules are auto-named and ephemeral — do not rename or modify them.
- PIM-eligible roles may require just-in-time activation before making a JIT request — PIM is out of scope.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- **JIT VM access** enabled on a VM via Microsoft Defender for Cloud
- A **time-bounded NSG inbound rule** opened for a specific IP range and port
- A **Bastion session** established after JIT approval with no public IP on the VM
- Confirmed **automatic NSG rule removal** once the time window expires
- An understanding of how JIT and Bastion compose into a zero-standing-access pattern

---

## 3. Scenario

**Remove standing inbound access to your VM entirely, not just restrict it.**

Even with an NSG, an always-open RDP rule is a standing target. JIT closes the port by default and opens it only when an approved request is submitted — scoped to a specific IP, a specific port, and a specific time window. Combined with Bastion, you get browser-based access with no public IP and no permanent NSG rules.

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
3. Enter your credentials (or retrieve from Key Vault — see [1-Azure Bastion.md § Password from Key Vault](../Azure%20Bastion/1-Azure%20Bastion.md#8-password-from-azure-key-vault-secretless-access-pattern))
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

## Troubleshooting

### Issue: JIT option not available on the VM

- **Defender for Servers** plan is not enabled on the subscription — go to **Defender for Cloud** → **Environment settings** → confirm Defender for Servers is on
- VM is not yet onboarded to Defender for Cloud — wait up to 24 hours after enabling the plan
- VM must be running (deallocated VMs cannot be JIT-enabled)

### Issue: JIT request is stuck in "Pending"

- The requesting user is missing the **Security Reader** role on the VM or resource group
- The requesting user is missing the **Virtual Machine Contributor** role on the target VM
- Check role assignments via **VM** → **Access control (IAM)**

### Issue: NSG inbound rule not appearing after JIT approval

- Confirm the request shows **Approved** in **Defender for Cloud** → **JIT VM Access** → **Configured** tab
- NSG propagation can take 1–2 minutes — refresh the **Networking** blade
- If the VM has multiple NICs, check the NSG on the correct NIC

### Issue: Bastion session fails immediately after JIT approval

- JIT only opens the NSG rule — it does not start a Bastion session automatically; initiate the connection manually via **Connect** → **Bastion**
- Verify the approved IP range matches your current public IP (use `curl ifconfig.me` to check)
- If your IP changed between request and connection, submit a new JIT request

### Issue: JIT rule did not auto-close after the time window

- Check **Defender for Cloud** → **JIT VM Access** → confirm the request shows **Expired**
- NSG rule removal can lag a few minutes after expiry — refresh the **Inbound security rules** view
- If the rule persists beyond 10 minutes, manually delete it and re-check the Defender for Cloud plan health

### NSG rule naming

JIT rules are auto-generated and ephemeral — do not rename or modify them:

```text
SecurityCenter-JITRule-{port}-{timestamp}    e.g., SecurityCenter-JITRule-3389-1234567890
```

See [Naming Convention — JIT NSG Rules](../Naming-Convention.md#jit-nsg-rules) for the full reference.

---

## Why JIT Matters (Engineering Justification)

- **No standing inbound access** — RDP/SSH ports are closed by default; opened only on explicit request
- **Time-bounded** — port access expires automatically; no manual cleanup required
- **IP-scoped** — NSG rule restricts access to the requester's IP, not the open Internet
- **Fully audited** — all approvals and connections are logged in Azure Activity Logs and Defender for Cloud
- **Zero Trust aligned** — enforces least-privilege, just-in-time access without a VPN or jumpbox
- **Complements Bastion** — JIT controls *when* the port is open; Bastion controls *how* you connect

> This is the recommended access pattern for production VMs requiring interactive sessions.

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

[← Azure Bastion — Secure VM Access](../Azure%20Bastion/1-Azure%20Bastion.md) | [↑ Track README](README.md) | [↑ Repo README](../README.md)
