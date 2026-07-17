# Identity‑First Bicep Deployment — Identity Stack (Capstone)

> **Identity-First Track — Lab 7 of 11.** Continues from [06-azuremonitor-activity-logs.md](../Identity-First/06-azuremonitor-activity-logs.md). Returns to [09-governance-flow.md](../Identity-First/09-governance-flow.md) after completion.
> **Why this matters:** Deploying identity, Key Vault, RBAC, and locks as separate portal steps is error-prone and impossible to review or version — this lab assembles the same stack as modular Bicep so the entire foundation can be code-reviewed, diffed, and deployed in a single command.

Last validated on: 2026-06-25
Portal experience note: Steps validated against VS Code with the Bicep and Azure Resources extensions as of June 2026.

This lab brings together the full **identity‑first architecture** using modular Bicep.
It forms the foundation of a secure, secretless, RBAC-driven Azure environment.

This page outlines the architecture, the module responsibilities, and the deployment flow.

All Bicep files referenced here are located in:

```plaintext
bicep/
```

---

## Objective

Build a modular Bicep stack that deploys:

- A **User‑Assigned Managed Identity**
- A **Key Vault** configured for **RBAC**
- An **RBAC role assignment** granting the identity access to Key Vault
- A **resource lock** to protect the environment
- A clean **composition layer** (`main.bicep`)

This foundation carries forward into future capstones.

---

## Final Folder Structure

```plaintext
Bicep/
  main.bicep
  create-rg.bicep
  create-uami.bicep
  create-keyvault.bicep
  keyvault.bicep
  rbac.bicep
  locks.bicep
  resourceGroup.bicep
  storage.bicep
  vm.bicep
  Diagnostics.bicep
```

Each module is small, focused, and reusable — following enterprise IaC patterns.

---

## Identity‑First Architecture Diagram

```mermaid
flowchart TD

    subgraph RG["Resource Group (Identity Capstone)"]

        UAMI["User-Assigned Managed Identity<br/>create-uami.bicep"]
        KV["Azure Key Vault (RBAC Mode)<br/>keyvault.bicep"]
        RBAC["RBAC Assignment<br/>rbac.bicep"]
        LOCK["Resource Lock<br/>locks.bicep"]

    end

    UAMI -->|principalId| RBAC
    RBAC -->|Key Vault Secrets User| KV
    KV --> LOCK
```

This diagram shows the identity-first flow:
**Identity → RBAC → Key Vault → Governance Lock**

---

## Module Overview

### 1. create-uami.bicep

Creates a **User‑Assigned Managed Identity** and outputs:

- `principalId` — AAD Object ID used for RBAC
- `clientId` — Client ID for workload authentication

This identity becomes the root of the identity-first architecture.

---

### 2. keyvault.bicep

Deploys a **Key Vault in RBAC mode**, with:

- `enableRbacAuthorization: true`
- `tenantId` binding
- Standard SKU

Outputs:

- `kvId` — used as RBAC scope and for diagnostics

This ensures a modern, secretless, identity-first vault.

---

### 3. rbac.bicep

Assigns the **Key Vault Secrets User** role to the Managed Identity.

Key behaviors:

- Uses a deterministic `guid()` for idempotency
- Assigns at **resource group scope**
- Uses `principalType: ServicePrincipal`

This module enforces least privilege and repeatable deployments.

---

### 4. locks.bicep

Applies a **CanNotDelete** lock to protect critical identity resources.

This enforces governance and prevents accidental deletion.

---

## Composition Layer — main.bicep

The `main.bicep` file orchestrates the entire identity-first architecture:

- Deploys the Managed Identity
- Deploys the Key Vault
- Assigns RBAC permissions
- Applies a governance lock

The file references all modules in the `Bicep/` folder, keeping the composition layer clean and readable.

---

## What Happens When You Deploy

The deployment creates:

1. **User‑Assigned Managed Identity**
2. **Key Vault (RBAC mode)**
3. **RBAC assignment** (Key Vault Secrets User → Managed Identity)
4. **Resource lock** on the resource group

This completes the identity-first foundation.

---

## Deploy the Stack

> All commands are run from the `Bicep/` folder. Ensure you are logged in (`az login`) and have set the correct subscription (`az account set --subscription <id>`).

### Step 1 — Create the Resource Group

```bash
az deployment sub create \
  --location eastus \
  --template-file create-rg.bicep
```

### Step 2 — Deploy the Identity Stack

```bash
az deployment group create \
  --resource-group rg-fntech-identity-eus-core \
  --template-file main.bicep
```

**Expected output (abbreviated):**

```json
{
  "properties": {
    "provisioningState": "Succeeded",
    "outputs": {
      "uamiPrincipalId": { "value": "<guid>" },
      "kvId": { "value": "/subscriptions/.../resourceGroups/rg-fntech-identity-eus-core/providers/Microsoft.KeyVault/vaults/kv-fntech-eus-lab" }
    }
  }
}
```

### Step 3 — Validate Resources in Portal

After deployment succeeds, confirm in the Azure Portal:

1. **Resource group** `rg-fntech-identity-eus-core` contains:
   - User-Assigned Managed Identity
   - Key Vault (RBAC mode — confirm `Access configuration` shows **Azure role-based access control**)
   - Resource lock visible under `rg-fntech-identity-eus-core` → **Locks**
2. **Key Vault → Access control (IAM)** → confirm the UAMI appears as **Key Vault Secrets User**
3. **CLI validation:**

```bash
# Confirm RBAC assignment exists
az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-fntech-identity-eus-core \
  --query "[?roleDefinitionName=='Key Vault Secrets User']" \
  --output table

# Confirm lock exists
az lock list --resource-group rg-fntech-identity-eus-core --output table
```

---

## What I Learned

- Splitting subscription-scope deployment (`create-rg.bicep`) from resource-group-scope deployment (`main.bicep`) into two separate `az deployment` commands is required because Bicep cannot change scope mid-file; trying to do both in a single `az deployment group create` fails silently or throws a misleading error
- `principalType: ServicePrincipal` on the RBAC module is mandatory for managed identities — omitting it causes role assignments to apply correctly at the API level but show as "Unknown" in the portal IAM blade, creating false audit alerts
- Using `guid()` with deterministic inputs for role assignment names ensures idempotency — re-running `main.bicep` doesn't create duplicate assignments, which makes the stack safe to redeploy for updates
- `enableRbacAuthorization: true` on the Key Vault module disables the old access policy model entirely; access policies set before the flag was flipped become inaccessible and must be recreated as role assignments
- Modular Bicep is significantly easier to review in a pull request than a monolithic template — each module maps to a single responsibility and a single test scenario

---

## 🔗 Related Labs

- **Lab 1 — Identity Fundamentals + RBAC Basics**
  [01-identity-fundamentals.md](../Identity-First/01-identity-fundamentals.md)

- **Lab 2 — Managed Identity + Azure Key Vault**
  [02-managed-identity-keyvault-secretless-auth.md](../Identity-First/02-managed-identity-keyvault-secretless-auth.md)

- **Lab 3 — Azure AD Roles + RBAC Scopes**
  [03-azuread-roles-rbac-scopes.md](../Identity-First/03-azuread-roles-rbac-scopes.md)

- **Lab 4 — Azure Locks + Resource Policies**
  [04-azurelocks-resource-policies.md](../Identity-First/04-azurelocks-resource-policies.md)

- **Lab 5 — Access Validation (Portal + CLI)**
  [05-access-validation.md](../Identity-First/05-access-validation.md)

- **Lab 6 — Azure Monitor + Activity Logs**
  [06-azuremonitor-activity-logs.md](../Identity-First/06-azuremonitor-activity-logs.md)
