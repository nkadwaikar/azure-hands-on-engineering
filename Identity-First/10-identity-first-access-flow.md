# Identity-First Access Flow

> **Why this matters:** Teams that can't trace how a workload obtains a Key Vault secret end up reverting to stored credentials — this diagram makes the UAMI token flow explicit so the zero-secrets pattern is understood and reproducible, not just trusted.

This diagram illustrates the **end-to-end identity flow** used in your Week 1 stack. It shows how a workload uses a **User Assigned Managed Identity (UAMI)** to authenticate to Microsoft Entra ID and access Key Vault using RBAC — no secrets, no keys, no connection strings.

Last validated on: 2026-06-25  
Portal experience note: Diagram reflects the Week 1 identity stack deployed via Bicep in [07-bicep-deployment-identity-stack.md](07-bicep-deployment-identity-stack.md).

> **Note:** This is a reference document, not a hands-on lab. No resources are created here.

---

## Identity Flow Diagram

```plaintext
                         ┌──────────────────────────────┐
                         │      Workload / Service       │
                         │ (VM, Container, Function App) │
                         └───────────────┬──────────────┘
                                         │
                                         │ 1. Uses attached
                                         │    User Assigned
                                         │    Managed Identity
                                         ▼
                         ┌──────────────────────────────┐
                         │   User Assigned Managed ID    │
                         │          (wk1-uami)           │
                         └───────────────┬──────────────┘
                                         │
                                         │ 2. Requests token
                                         │    for Key Vault
                                         ▼
                         ┌──────────────────────────────┐
                         │        Azure AD (Entra)       │
                         └───────────────┬──────────────┘
                                         │
                                         │ 3. Issues OAuth2 token
                                         │    for Key Vault scope
                                         ▼
                         ┌──────────────────────────────┐
                         │        Key Vault (RBAC)       │
                         │           wk1-kv              │
                         └───────────────┬──────────────┘
                                         │
                                         │ 4. Evaluates RBAC:
                                         │    - UAMI → Secrets User
                                         │    - Scope: Key Vault
                                         ▼
                         ┌──────────────────────────────┐
                         │     Secrets / Keys / Certs    │
                         │     (Access granted via RBAC) │
                         └──────────────────────────────┘
```

---

## What This Diagram Shows

**✔ Identity-first authentication**  
The workload never uses:

- Secrets  
- Keys  
- Connection strings  
- Passwords  

Everything flows through the UAMI.

**✔ Microsoft Entra ID is the trust authority**  
Microsoft Entra ID issues the access token after validating the UAMI.

**✔ Key Vault uses RBAC, not Access Policies**  
Your design uses:

- **Key Vault Secrets User** role  
- Assigned directly to the UAMI  
- Scope = Key Vault resource  

**✔ Zero secrets architecture**  
This is the modern, recommended pattern for:

- Enterprise workloads  
- Regulated industries  
- Zero-trust environments

---

## Key Takeaways

This identity flow demonstrates:

- **No credential management** — workloads authenticate using managed identity
- **Azure AD as authorization** — centralized identity and access management
- **RBAC over access policies** — modern, granular permission model
- **Zero-trust architecture** — no secrets stored or transmitted
