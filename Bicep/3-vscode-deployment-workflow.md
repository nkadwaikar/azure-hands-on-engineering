# VS Code Deployment Workflow

> **Why this matters:** Understanding how a right-click in VS Code translates to a subscription-scoped resource group creation followed by a resource-group-scoped module chain makes the Bicep deployment model concrete — and makes it reproducible without a CLI or Portal.

This diagram maps how the Identity-First lab stack is deployed using VS Code only, without Azure CLI or the Portal.

Last validated on: 2026-06-25  
Portal experience note: Diagram reflects the identity stack deployed via Bicep in [1-bicep-deployment-identity-stack.md](1-bicep-deployment-identity-stack.md).

> **Note:** This workflow uses the `create-rg.bicep`, `create-uami.bicep`, and `create-keyvault.bicep` modules in the `Bicep/` folder.

---

## Deployment Workflow Diagram

```plaintext
┌──────────────────────────────────────────────────────────────┐
│                      Visual Studio Code                       │
│        (Azure Account + Azure Resources + Bicep Extensions)   │
└───────────────┬──────────────────────────────────────────────┘
                │  Right-click → "Deploy Bicep File..."
                │
                ▼
        ┌──────────────────────────────────────────┐
        │        Azure Subscription Scope           │
        │   (Deployment of create-rg.bicep)            │
        └───────────────┬──────────────────────────┘
                        │
                        │  Creates Resource Group
                        ▼
              ┌──────────────────────────────┐
              │   Resource Group:            │
              │   rg-identity-capstone        │
              └───────────────┬─────────────┘
                              │
                              │  Deploy main.bicep
                              ▼
        ┌──────────────────────────────────────────────────────┐
        │                 Bicep Module Orchestration           │
        │                                                      │
        │   main.bicep → calls modules in sequence:            │
        │                                                      │
        │   1. create-rg.bicep     → Creates Resource Group    │
        │   2. create-uami.bicep   → Creates UAMI              │
        │   3. create-keyvault.bicep → Creates Key Vault       │
        └──────────────────────────────────────────────────────┘
                              │
                        │  Outputs surfaced in VS Code
                              ▼
                ┌──────────────────────────────────┐
                │   VS Code Output & Azure Explorer │
                │   (Validation + Logs + Resources) │
                └──────────────────────────────────┘
```

---

## What This Diagram Shows

**✔ VS Code is the control plane**  
All deployments start from your editor — no CLI, no Portal.

**✔ Subscription-level deployment**  
`create-rg.bicep` runs at subscription scope to create the Resource Group `rg-identity-capstone`.

**✔ Resource-group-level deployment**  
`main.bicep` deploys all modules into `rg-identity-capstone`.

**✔ Module orchestration**  
Each module is deployed in sequence with outputs feeding into the next:

- `create-rg.bicep` → outputs `rgName` and `location`
- `create-uami.bicep` → outputs `principalId`
- `create-keyvault.bicep` → uses UAMI principal ID for KV access policy

**✔ Validation happens inside VS Code**  
Azure Explorer shows:

- UAMI (`wk1-uami`)
- Key Vault (`wk1-kv`)
- Deployment logs

---

## Key Takeaways

This workflow shows:

- **Pure VS Code deployment** — no command-line tools required
- **Hierarchical deployment** — subscription → resource group → modules
- **Sequential orchestration** — modules depend on each other's outputs
- **Integrated validation** — all resources visible in Azure Explorer
