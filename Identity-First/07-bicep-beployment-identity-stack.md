# Day 7 — Identity‑First Bicep Deployment Identity Stack (Week 1 Capstone)

Day 7 delivers the full **identity‑first architecture** for Week 1 using modular Bicep.
This is the foundation of a secure, secretless, RBAC‑driven Azure environment.

This document explains the architecture, module responsibilities, and deployment flow.
All Bicep files referenced here are located in:

```
capstone/architecture/bicep/
```

---

## 🎯 Objective

Build a modular Bicep stack that deploys:

- A **User‑Assigned Managed Identity**
- A **Key Vault** configured for **RBAC**
- An **RBAC role assignment** granting the identity access to Key Vault
- A **resource lock** to protect the environment
- A clean **composition layer** (`main.bicep`)

This identity-first foundation will be reused across future capstones.

---

## 🧱 Final Folder Structure

```
capstone/
  architecture/
    bicep/
      main.bicep
      modules/
        identity.bicep
        keyvault.bicep
        rbac.bicep
        locks.bicep
```

Each module is small, focused, and reusable — following enterprise IaC patterns.

---

## 🗺️ Identity‑First Architecture Diagram

```mermaid
flowchart TD

    subgraph RG["Resource Group (Week 1 Capstone)"]
        
        UAMI["User-Assigned Managed Identity<br/>identity.bicep"]
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

## 🧩 Module Overview

### 1. identity.bicep  
Creates a **User‑Assigned Managed Identity** and outputs:

- `identityId` — full ARM resource ID  
- `identityPrincipalId` — AAD Object ID used for RBAC  

This identity becomes the root of the Week 1 architecture.

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

## 🧠 Composition Layer — main.bicep

The `main.bicep` file orchestrates the entire identity-first architecture:

- Deploys the Managed Identity  
- Deploys the Key Vault  
- Assigns RBAC permissions  
- Applies a governance lock  

The file references all modules inside the `modules/` folder, keeping the root clean and readable.

---

## 🧪 What Happens When You Deploy

The deployment creates:

1. **User‑Assigned Managed Identity**  
2. **Key Vault (RBAC mode)**  
3. **RBAC assignment** (Key Vault Secrets User → Managed Identity)  
4. **Resource lock** on the resource group  

This completes the identity-first foundation for Week 1.

---

## 🎉 Day 7 Complete

You now have:

- A fully modular identity-first Bicep stack  
- Clean, validated modules  
- A composition layer ready for deployment  
- Enterprise-grade RBAC and governance patterns  
- Documentation that is clean, readable, and recruiter-ready  

All code lives in the `capstone/architecture/bicep/` folder to avoid duplication and keep your repo maintainable.

---

## 🔗 Related Labs

- **Day 1 — Managed Identity Basics**  
  [01-managed-identity-basics.md](01-managed-identity-basics.md)

- **Day 2 — Key Vault RBAC Setup**  
  [02-key-vault-rbac-setup.md](02-key-vault-rbac-setup.md)

- **Day 3 — Bicep Modular Architecture**  
  [03-bicep-modular-architecture.md](03-bicep-modular-architecture.md)

- **Day 4 — Azure Locks + Resource Policies**  
  [04-locks-resource-policies.md](04-locks-resource-policies.md)

- **Day 5 — Access Validation (Portal + CLI)**  
  [05-access-validation.md](05-access-validation.md)

- **Day 6 — Azure Monitor + Activity Logs**  
  [06-azuremonitor-activity-logs.md](06-azuremonitor-activity-logs.md)