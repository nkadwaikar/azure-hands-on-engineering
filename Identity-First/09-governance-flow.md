# Governance Flow

> **Why this matters:** RBAC and Resource Locks only work together correctly if their interaction is understood — this diagram traces exactly how a request flows from identity through RBAC to a locked resource so the governance model is visible, not implied.

This diagram highlights the governance controls applied in your Week 1 stack. It shows how **RBAC** and **Resource Locks** work together to enforce compliance, prevent accidental deletion, and preserve identity-first access.

Last validated on: 2026-06-25  
Portal experience note: Diagram reflects the Week 1 identity stack deployed via Bicep in [07-bicep-deployment-identity-stack.md](07-bicep-deployment-identity-stack.md).

> **Note:** This is a reference document, not a hands-on lab. No resources are created here.

---

## Governance Flow Diagram

```plaintext
                         ┌────────────────────────────────┐
                         │        Azure Subscription       │
                         │   (Governance Root Scope)       │
                         └───────────────┬────────────────┘
                                         │
                                         │ 1. Governance Baseline
                                         │    (RBAC + Deployment Scope)
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

## What This Diagram Shows

**✔ RBAC controls who can do what**  
Examples from your stack:

- Deployment identity → Contributor  
- UAMI → Key Vault Secrets User  
- You → Owner/Contributor  

**✔ Resource Locks protect critical assets**  
Your `wk1-lock` prevents accidental deletion of:

- Key Vault  
- Managed Identity  
- Any other protected resource  

**✔ Identity-first access is enforced by governance**  
RBAC + locks ensure:

- No secrets  
- No access policies  
- No bypassing identity controls  

**✔ Everything is deployed and validated through VS Code**  
Governance is not an afterthought — it's part of the IaC.

---

## Key Takeaways

This governance flow shows:

- **Policy-driven compliance** — centralized enforcement at subscription scope
- **RBAC-based authorization** — granular access control without secrets
- **Resource protection** — locks prevent accidental deletion
- **Infrastructure as Code** — governance defined and deployed through Bicep
