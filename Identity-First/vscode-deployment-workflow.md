# 🔄 How Bicep Deploys from VS Code → Subscription → Resource Group → Modules

*Visual Studio Code Deployment Workflow for Week 1 Capstone*

This diagram shows the exact flow of how your Week 1 capstone is deployed using VS Code only, without Azure CLI or Portal.

---

## 📐 Deployment Workflow Diagram

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
        │   (Deployment of create-rg.bicep)         │
        └───────────────┬──────────────────────────┘
                        │
                        │  Creates Resource Group
                        ▼
              ┌──────────────────────────────┐
              │   Resource Group:            │
              │   rg-identity-lab            │
              └───────────────┬─────────────┘
                              │
                              │  Deploy main.bicep
                              ▼
        ┌──────────────────────────────────────────────────────┐
        │                 Bicep Module Orchestration           │
        │                                                      │
        │   main.bicep → calls modules in sequence:            │
        │                                                      │
        │   1. identity.bicep      → Creates UAMI              │
        │   2. keyvault.bicep      → Creates Key Vault         │
        │   3. rbac.bicep          → Assigns KV RBAC           │
        │   4. locks.bicep         → Adds CanNotDelete lock    │
        │   5. diagnostics.bicep   → (Optional) Logging        │
        └──────────────────────────────────────────────────────┘
                              │
                              │  Outputs returned to VS Code
                              ▼
                ┌──────────────────────────────────┐
                │   VS Code Output & Azure Explorer │
                │   (Validation + Logs + Resources) │
                └──────────────────────────────────┘
```

---

## 🧠 What This Diagram Shows

**✔ VS Code is the control plane**  
All deployments start from your editor — no CLI, no Portal.

**✔ Subscription-level deployment**  
`create-rg.bicep` runs at subscription scope to create the Resource Group.

**✔ Resource-group-level deployment**  
`main.bicep` deploys all modules into `rg-identity-lab`.

**✔ Module orchestration**  
Each module is deployed in sequence with outputs feeding into the next.

**✔ Validation happens inside VS Code**  
Azure Explorer shows:

- UAMI
- Key Vault
- RBAC assignments
- Locks
- Deployment logs

---

## 🎉 Summary

This workflow demonstrates:

- **Pure VS Code deployment** — no command-line tools required
- **Hierarchical deployment** — subscription → resource group → modules
- **Sequential orchestration** — modules depend on each other's outputs
- **Integrated validation** — all resources visible in Azure Explorer