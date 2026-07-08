# Azure Infrastructure as Code — Bicep

Last validated on: July 2026

[![Bicep Validate](https://github.com/nkadwaikar/azure-hands-on-engineering/actions/workflows/bicep-lint.yml/badge.svg)](https://github.com/nkadwaikar/azure-hands-on-engineering/actions/workflows/bicep-lint.yml)

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

## CI — Automated Validation

Every PR touching `Bicep/**.bicep` runs two jobs via [`.github/workflows/bicep-lint.yml`](../.github/workflows/bicep-lint.yml):

| Job | What it checks |
| --- | --- |
| **Lint and build** | `az bicep lint` — linter rules (unused params, missing descriptions, etc.) · `az bicep build` — type and syntax errors. No Azure credentials required. |
| **What-if** | `az deployment group what-if` against a live CI resource group — catches runtime errors that compile-only checks miss: invalid role definition IDs, unsupported API versions, missing resource providers. Requires Azure credentials (OIDC). |

The `what-if` job runs only when `CI_RESOURCE_GROUP` is set — it skips automatically on forks and repos without credentials configured.

### One-Time Setup for the What-If Job

**1. Create the CI resource group and Log Analytics workspace**

```bash
az group create --name rg-bicep-ci --location eastus

az monitor log-analytics workspace create \
  --resource-group rg-bicep-ci \
  --workspace-name law-bicep-ci
```

**2. Create a service principal with federated credentials (OIDC — no stored secret)**

```bash
# Create the app registration
az ad app create --display-name "github-bicep-ci"

# Note the appId from the output, then create the service principal
az ad sp create --id <appId>

# Assign Owner on the CI resource group
# (Owner required — what-if validates role assignments which needs Microsoft.Authorization/write)
az role assignment create \
  --role Owner \
  --assignee <appId> \
  --scope $(az group show --name rg-bicep-ci --query id -o tsv)
```

**3. Add the federated credential for GitHub Actions**

In the Azure portal: **App registrations → github-bicep-ci → Certificates & secrets → Federated credentials → Add credential**

| Field | Value |
| --- | --- |
| Federated credential scenario | GitHub Actions |
| Organisation | `nkadwaikar` |
| Repository | `azure-hands-on-engineering` |
| Entity type | Branch |
| Branch | `main` |

Add a second credential with **Entity type: Pull request** to cover PR runs.

**4. Configure GitHub repository secrets and variables**

Go to **Settings → Secrets and variables → Actions**:

| Type | Name | Value |
| --- | --- | --- |
| Secret | `AZURE_CLIENT_ID` | App registration **Application (client) ID** |
| Secret | `AZURE_TENANT_ID` | Your Entra **Tenant ID** |
| Secret | `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| Variable | `CI_RESOURCE_GROUP` | `rg-bicep-ci` |
| Variable | `CI_WORKSPACE_ID` | Full resource ID of `law-bicep-ci` — copy from portal or run `az monitor log-analytics workspace show --resource-group rg-bicep-ci --workspace-name law-bicep-ci --query id -o tsv` |

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
