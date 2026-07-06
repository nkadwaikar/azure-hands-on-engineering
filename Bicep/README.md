# Azure Infrastructure as Code — Bicep

Last validated on: July 2026

This track covers modular Bicep deployments for identity-first Azure infrastructure. Every module is scoped to a single responsibility, composed through a root `main.bicep`, and aligned to production governance standards.

> **Identity-First Track connection:** The three lab guides in this folder are **Labs 7, 8, and 11** of the [Identity-First Track](../Identity-First/README.md). They form the IaC capstone that codifies the portal-built stack from Labs 1–6. Start at the [Identity-First README](../Identity-First/README.md) if you are following the track in sequence.

---

## Folder Structure

```tree
Bicep/
├── main.bicep                  # RG-scope orchestrator — wires identity, KV, RBAC, lock
│
├── create-rg.bicep             # Subscription-scope: create Resource Group
├── create-uami.bicep           # User-Assigned Managed Identity
├── create-keyvault.bicep       # Key Vault + inline RBAC (standalone use)
│
├── keyvault.bicep              # Key Vault (used by main.bicep)
├── rbac.bicep                  # Role assignment (least privilege, guid idempotency)
├── locks.bicep                 # Resource lock (CanNotDelete / ReadOnly)
├── resourceGroup.bicep         # RG-scope orchestration module
│
├── storage.bicep               # Storage Account (secure defaults, no public access)
├── vm.bicep                    # Virtual Machine (UAMI, Ubuntu 22.04, SSH-only)
└── Diagnostics.bicep           # Diagnostic settings → Log Analytics Workspace
```

---

## Modules

| File | Purpose |
| --- | --- |
| [`main.bicep`](main.bicep) | Orchestrates identity, Key Vault, RBAC, and lock at RG scope |
| [`create-rg.bicep`](create-rg.bicep) | Provisions a Resource Group at subscription scope |
| [`create-uami.bicep`](create-uami.bicep) | Creates a User-Assigned Managed Identity |
| [`create-keyvault.bicep`](create-keyvault.bicep) | Deploys Key Vault + inline RBAC assignment (standalone) |
| [`keyvault.bicep`](keyvault.bicep) | Deploys Key Vault (used as a module by `main.bicep`) |
| [`rbac.bicep`](rbac.bicep) | Assigns a role to a principal at resource scope |
| [`locks.bicep`](locks.bicep) | Applies a CanNotDelete or ReadOnly resource lock |
| [`resourceGroup.bicep`](resourceGroup.bicep) | RG-scope orchestration module (called from subscription-scope deployments) |
| [`storage.bicep`](storage.bicep) | Deploys a Storage Account with secure defaults |
| [`vm.bicep`](vm.bicep) | Provisions a Linux VM with UAMI and SSH-only authentication |
| [`diagnostics.bicep`](diagnostics.bicep) | Routes Key Vault audit logs to a Log Analytics Workspace |

---

## Identity Stack — What `main.bicep` Deploys

`main.bicep` wires together the foundational identity plane:

1. **User-Assigned Managed Identity** (`create-uami.bicep`) — secretless authentication principal
2. **Key Vault** (`keyvault.bicep`) — RBAC-enabled, no access policies
3. **Role Assignment** (`rbac.bicep`) — Key Vault Secrets User scoped to the UAMI
4. **Resource Lock** (`locks.bicep`) — CanNotDelete guard on the resource group

Run `create-rg.bicep` first to provision the Resource Group, then deploy `main.bicep` into it.

---

## How to Deploy

**Prerequisites:** [Bicep toolchain setup in VS Code](2-how-to-run-bicep-in-vscode.md)

```bash
# Login and set subscription
az login
az account set --subscription "<subscription-id>"

# Step 1 — Create the Resource Group (subscription scope)
az deployment sub create \
  --location eastus \
  --template-file create-rg.bicep

# Step 2 — Deploy identity stack into the Resource Group
az deployment group create \
  --resource-group rg-identity-lab \
  --template-file main.bicep
```

---

## Related Labs

| Topic | Link |
| --- | --- |
| Bicep Deployment — Identity Stack | [1-bicep-deployment-identity-stack.md](1-bicep-deployment-identity-stack.md) |
| Bicep Toolchain Setup in VS Code | [2-how-to-run-bicep-in-vscode.md](2-how-to-run-bicep-in-vscode.md) |
| VS Code Deployment Workflow | [3-vscode-deployment-workflow.md](3-vscode-deployment-workflow.md) |
| Naming Convention | [Naming-Convention.md](../Naming-Convention.md) |
| Governance Flow | [09-governance-flow.md](../Identity-First/09-governance-flow.md) |

---

## Naming Convention

All resources in this track follow the shared naming standard documented in [Naming-Convention.md](../Naming-Convention.md).

Key patterns used in Bicep modules:

| Resource | Pattern | Example |
| --- | --- | --- |
| Resource Group | `rg-<workload>-<env>` | `rg-identity-lab` |
| User-Assigned MI | `uami-<workload>-<env>` | `uami-identity-lab` |
| Key Vault | `kv-<workload>-<env>` | `kv-identity-lab` |
| Storage Account | `st<workload><env>` | `stidentitylab` |
| Virtual Machine | `vm-<workload>-<env>` | `vm-identity-lab` |

---

## Design Principles

- **Single-responsibility modules** — one resource per module, composed at the root
- **Secretless by default** — Managed Identity replaces all service principal credentials
- **RBAC over access policies** — Key Vault uses RBAC mode exclusively
- **Locks as guardrails** — critical resources protected against accidental deletion
- **Diagnostics wired in** — every compute and data resource routes to Log Analytics
