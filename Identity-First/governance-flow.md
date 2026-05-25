# 🛡️ Governance Flow Diagram  
*How Policies, RBAC, and Locks Enforce Safe Operations in the Landing Zone*

This diagram illustrates the governance controls applied in your Week 1 capstone. It shows how **Azure Policy**, **RBAC**, and **Resource Locks** work together to enforce compliance, prevent accidental deletion, and ensure identity-first access.

---

## 🧭 Governance Flow Diagram

```plaintext
                         ┌────────────────────────────────┐
                         │        Azure Subscription       │
                         │   (Governance Root Scope)       │
                         └───────────────┬────────────────┘
                                         │
                                         │ 1. Policy Assignments
                                         │    (Deny/Audit/DeployIfNotExists)
                                         ▼
                         ┌────────────────────────────────┐
                         │      Resource Group Level       │
                         │        rg-identity-lab          │
                         └───────────────┬────────────────┘
                                         │
                                         │ 2. RBAC Assignments
                                         │    - Contributor (deployment identity)
                                         │    - Key Vault Secrets User (UAMI)
                                         ▼
        ┌──────────────────────────────────────────────────────────────────┐
        │                          Resources                               │
        │                                                                  │
        │   ┌──────────────────────┐   ┌──────────────────────┐           │
        │   │  Managed Identity    │   │      Key Vault        │           │
        │   │      wk1-uami        │   │       wk1-kv          │           │
        │   └───────────┬──────────┘   └───────────┬──────────┘           │
        │               │                          │                       │
        │               │ 3. RBAC Enforced         │ 4. RBAC Enforced       │
        │               │    (principalId)         │    (Secrets User)      │
        │               ▼                          ▼                       │
        │   ┌──────────────────────┐   ┌──────────────────────┐           │
        │   │  Access Token Flow   │   │  Secretless Access    │           │
        │   │  via Azure AD        │   │  via RBAC             │           │
        │   └──────────────────────┘   └──────────────────────┘           │
        │                                                                  │
        └──────────────────────────────────────────────────────────────────┘
                                         │
                                         │ 5. Resource Lock
                                         │    (CanNotDelete)
                                         ▼
                         ┌────────────────────────────────┐
                         │   Protection Against Deletion   │
                         │   - Prevents accidental removal │
                         │   - Enforces governance intent  │
                         └────────────────────────────────┘
```

---

## 🧠 What This Diagram Shows

**✔ Azure Policy governs the environment from the top**  
Policies enforce:

- Allowed locations  
- Tag requirements  
- Diagnostic settings  
- Key Vault RBAC mode  
- Resource naming conventions (optional)

**✔ RBAC controls who can do what**  
Examples from your capstone:

- Deployment identity → Contributor  
- UAMI → Key Vault Secrets User  
- You → Owner/Contributor  

**✔ Resource Locks protect critical assets**  
Your `wk1-lock` prevents accidental deletion of:

- Key Vault  
- Managed Identity  
- Any other protected resource  

**✔ Identity-first access is enforced by governance**  
Policies + RBAC ensure:

- No secrets  
- No access policies  
- No bypassing identity controls  

**✔ Everything is deployed and validated through VS Code**  
Governance is not an afterthought — it's part of the IaC.

---

## 🎉 Summary

This governance flow demonstrates:

- **Policy-driven compliance** — centralized enforcement at subscription scope
- **RBAC-based authorization** — granular access control without secrets
- **Resource protection** — locks prevent accidental deletion
- **Infrastructure as Code** — governance defined and deployed through Bicep