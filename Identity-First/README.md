# Identity-First Track

Last validated on: July 2026

A portal-first, then Bicep-driven track that builds a secure, secretless, RBAC-governed Azure foundation from scratch — covering Entra ID fundamentals, Managed Identity, Key Vault integration, Resource Locks, Azure Policy, and observability. Labs 7, 8, and 11 continue in the `Bicep/` folder as the IaC capstone.

## Track Structure

```text
Identity-First/                    ← Portal-first foundation (Labs 1–6 + reference diagrams)
|—— 01-identity fundamentals.md
|—— 02-managed Identity + Azure Key Vault (Secretless Authentication).md
|—— 03-azuread-roles-rbac-scopes.md
|—— 04-azurelocks-resource-policies.md
|—— 05-access-validation.md
|—— 06-azuremonitor-activity-logs.md
|—— 09-governance-flow.md
|—— 10-identity-first-access-flow.md
`—— lessons-learned.md

Bicep/                             ← IaC capstone (Labs 7, 8, 11)
|—— 1-bicep-deployment-identity-stack.md
|—— 2-how-to-run-bicep-in-vscode.md
`—— 3-vscode-deployment-workflow.md
```

## Lab Sequence

1. [Identity Fundamentals](01-identity%20fundamentals.md)

   | Section | What It Covers |
   | --- | --- |
   | Prerequisites | Azure subscription, Azure CLI, and portal access requirements |
   | Learning Objectives | Entra ID identity structure, RBAC scopes, least-privilege model |
   | Create a Test User | Portal walkthrough — create an Entra ID user for RBAC validation |
   | Assign RBAC Roles | Assign Reader at resource group scope; observe inheritance |
   | Validate Access | Confirm the test user can view but not modify resources |

2. [Managed Identity + Azure Key Vault (Secretless Authentication)](02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md)

   | Section | What It Covers |
   | --- | --- |
   | Assign Managed Identity | Enable System-Assigned Managed Identity on a VM |
   | Grant Key Vault Access | Assign **Key Vault Secrets User** RBAC role to the VM identity |
   | Read a Secret Secretlessly | VM retrieves a Key Vault secret without any stored credential |
   | Validate Zero-Secret Pattern | Confirm no connection strings or keys exist in app settings |

3. [Azure AD Roles + RBAC Scopes](03-azuread-roles-rbac-scopes.md)

   | Section | What It Covers |
   | --- | --- |
   | Directory Roles vs Resource Roles | Entra directory roles vs Azure RBAC — boundaries and blast radius |
   | Assign Roles at Multiple Scopes | Subscription, resource group, and resource-level assignments |
   | Validate from User Perspective | Sign in as test user and confirm scoped access behavior |

4. [Azure Locks + Resource Policies](04-azurelocks-resource-policies.md)

   | Section | What It Covers |
   | --- | --- |
   | Delete Locks | Apply and test a Delete lock on a resource group |
   | Read-Only Locks | Apply a Read-only lock; observe write-block behavior |
   | Custom Audit Policy | Author and assign a custom Audit policy |
   | Deny Policy | Assign a Deny policy; validate non-compliant deployments are blocked |
   | Cleanup Notes | Remove locks and policy assignments before teardown |

5. [Access Validation (Portal + CLI)](05-access-validation.md)

   | Section | What It Covers |
   | --- | --- |
   | Validate RBAC | Prove role assignments permit and block correct operations |
   | Validate Locks | Confirm locked resources resist deletion and modification |
   | Validate Policy | Trigger a policy Deny and confirm the audit trail |
   | CLI Validation | Reproduce all validations using Azure CLI commands |

6. [Azure Monitor + Activity Logs](06-azuremonitor-activity-logs.md)

   | Section | What It Covers |
   | --- | --- |
   | Log Analytics Workspace | Create workspace; configure Activity Log diagnostic settings |
   | Key Vault Audit Events | Route Key Vault access logs into Log Analytics |
   | Query Governance Events | KQL queries for RBAC changes, policy denies, and lock operations |
   | Validate Observability | Confirm every identity access attempt is auditable |

7. [Bicep Deployment — Identity Stack (Capstone)](../Bicep/1-bicep-deployment-identity-stack.md)

   | Section | What It Covers |
   | --- | --- |
   | Stack Overview | Modular Bicep for identity, Key Vault, RBAC, and locks |
   | Module Walkthrough | Per-module breakdown: `create-uami.bicep`, `keyvault.bicep`, `rbac.bicep`, etc. |
   | Deploy the Stack | Single-command deployment via Azure CLI |
   | Validate Outputs | Confirm resources match the portal-built stack from Labs 1–6 |

8. [How to Deploy Bicep Files Using VS Code](../Bicep/2-how-to-run-bicep-in-vscode.md)

   | Section | What It Covers |
   | --- | --- |
   | Required Extensions | Bicep and Azure Resources extensions setup |
   | Right-Click Deploy | Deploy Bicep files without CLI or Portal |
   | Validate & Redeploy | Iterate inside VS Code — no context switching |

9. [Governance Flow](09-governance-flow.md)

   > Reference diagram — no resources created. Traces how a request flows from identity through RBAC to a locked resource.

10. [Identity-First Access Flow](10-identity-first-access-flow.md)

    > Reference diagram — no resources created. Maps the UAMI token flow from workload through Entra ID to Key Vault.

11. [VS Code Deployment Workflow](../Bicep/3-vscode-deployment-workflow.md)

    > Reference diagram — no resources created. Maps the right-click VS Code deploy to the identity stack in the `Bicep/` folder.

---

## Reference Files

| File | Purpose |
| --- | --- |
| [lessons-learned.md](lessons-learned.md) | Real-world gotchas, fixes, and notes captured during lab execution |
| [Bicep/main.bicep](../Bicep/main.bicep) | Main Bicep entry point for the identity stack |

## Prerequisites

- Azure subscription with **Owner** or **User Access Administrator** role
- Azure Portal access
- Azure CLI installed (optional for CLI validation steps)
- VS Code with the **Bicep** and **Azure Resources** extensions (for Bicep labs in the `Bicep/` folder)
- Estimated time: 6–8 hours across all 11 labs

---

[← Back to Azure Hands-On Engineering](../README.md)
