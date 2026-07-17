# Azure Locks + Resource Policies

> **Why this matters:** Without locks and policy, even a privileged identity can accidentally delete critical resources or deploy a non-compliant VM — this lab applies Delete locks, Read-only locks, a custom Audit policy, and a Deny policy so governance controls are proven before a production Landing Zone depends on them.

This lab introduces two foundational governance controls used in every enterprise Landing Zone: **Resource Locks** (Delete / Read-only) and **Azure Policy** (Deny / Audit / Modify). These controls enforce consistency, prevent accidental changes, and shape compliant deployments.

Last validated on: 2026-06-25
Portal experience note: Steps validated against Azure Portal as of June 2026; policy compliance evaluation can take up to 30 minutes after assignment.

> **Note:** Remove all locks and policy assignments before cleanup — attempting to delete a locked resource group will fail.

---

## Quick Navigation

- [Learning Objectives](#learning-objectives)
- [Create Resource Group](#1-create-a-test-resource-group)
- [Apply Delete Lock](#2-apply-a-delete-lock-at-resource-group-scope)
- [Test Delete Lock](#3-test-the-delete-lock)
- [Remove Delete Lock](#4-remove-the-delete-lock)
- [Apply Read-Only Lock](#5-apply-a-read-only-lock-at-resource-scope)
- [Remove Read-Only Lock](#6-remove-the-read-only-lock)
- [Assign Custom Audit Policy](#7-assign-a-custom-policy--audit-resource-groups-missing-a-tag)
- [Test the Custom Policy](#8-test-the-custom-policy)
- [View Compliance](#9-view-compliance)
- [Enforce VM SKU Governance](#10-enforce-vm-sku-governance-deny-policy)
- [Governance and Identity Interaction](#governance-and-identity-interaction)
- [Lessons Learned](#lessons-learned)
- [Cleanup](#cleanup)

---

## Learning Objectives

By the end of this lab, you will have:

- **Delete and Read-only locks** applied at both resource group and individual resource scope
- **Lock inheritance** observed: a lock at RG scope covers all child resources
- A **custom Audit policy** assigned to detect resource groups missing a required tag
- A **Deny policy** enforcing VM SKU restrictions on a specific resource group
- Experience comparing **policy-restricted** versus **policy-free** resource group behavior
- Compliance state validated in the Azure Policy portal

---

## 1. Create a Test Resource Group

### Azure Portal → Resource groups → Create

- Name: `rg-locks-demo`
- Region: any

---

## 2. Apply a Delete Lock at Resource Group Scope

### rg-locks-demo → Settings → Locks → Add

- Lock name: `rg-delete-lock`
- Lock type: Delete

### Expected Behavior

- RG cannot be deleted
- Resources inside cannot be deleted
- Resources **can still be modified**

---

## 3. Test the Delete Lock

Try deleting the RG → blocked
Try deleting a resource → blocked

---

## 4. Remove the Delete Lock

To test Read‑only behavior correctly:

### rg-locks-demo → Locks → Delete

---

## 5. Apply a Read-Only Lock at Resource Scope

Choose any resource (e.g., storage account):

### Storage account → Locks → Add

- Lock name: `sa-readonly-lock`
- Lock type: Read‑only

### Expected Behavior (Read‑Only)

- Cannot modify
- Cannot delete
- Can view settings
- Can read data (if RBAC allows)

---

## 6. Remove the Read-Only Lock

### Storage account → Locks → Delete

---

---

## 7. Assign a Custom Policy — Audit Resource Groups Missing a Tag

Azure does **not** provide a built‑in policy that enforces tags specifically on resource groups.
Therefore, we created a custom Audit policy.

### **Custom Policy JSON (Sanitized)**

```json
{
  "properties": {
    "displayName": "Custom Policy — Audit Resource Groups Missing a Tag",
    "policyType": "Custom",
    "mode": "All",
    "description": "Audits resource groups that do not contain a required tag.",
    "metadata": {
      "category": "Governance",
      "version": "1.0.0"
    },
    "parameters": {
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name",
          "description": "Name of the tag to audit for."
        }
      }
    },
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Resources/subscriptions/resourceGroups"
          },
          {
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "exists": false
          }
        ]
      },
      "then": {
        "effect": "audit"
      }
    }
  }
}
```

### 7.1 Assign the Custom Policy

**Azure Portal → Policy → Definitions → Select your custom policy → Assign**

- Scope: Subscription
- Assignment name: `audit-missing-environment-tag`
- Parameter:
  - Tag Name: `environment`

### Expected Behavior — Policy Assignment

- No deployments are blocked
- RGs missing the tag appear as Non‑compliant
- RGs with the tag appear as Compliant

---

## 8. Test the Custom Policy

Create:

- `rg-test-noncompliant` → no tag → **Non‑compliant**
- `rg-test-compliant` → tag `environment=dev` → **Compliant**

---

## 9. View Compliance

### Azure Portal → Policy → Compliance → Select your custom policy

Audit policies provide visibility without enforcement.

---

## 10. Enforce VM SKU Governance (Deny Policy)

Assign:

**Policy:** Allowed virtual machine size SKUs
**Scope:** `rg-test-compliant`

### Allowed SKUs (validated list)

```text
Standard_B1s
Standard_B1ms
Standard_B2s
Standard_B2ms
Standard_D2s_v3
Standard_D2s_v5
Standard_DS1_v2
```

### Test

In `rg-test-compliant`:

- Allowed SKUs → visible
- Disallowed SKUs → hidden or blocked

In `rg-identity-eus-lab-core` (no policy):

- All SKUs → visible
- No restrictions

---

## Governance and Identity Interaction

- **Locks override RBAC**
- **Policies override RBAC**
- Directory roles cannot bypass governance
- RBAC = *who* can act
- Policy + Locks = *what* is allowed

---

## Lessons Learned

### 1. Locks enforce operational safety

They prevent accidental changes and override RBAC.

### 2. Lock inheritance is absolute

A lock at RG or subscription scope applies to all child resources.

### 3. Read‑only lock testing must be isolated

Remove RG locks before testing resource‑level locks.

### 4. Azure Policy defines *what* can be deployed

Deny, Audit, Modify effects enforce compliance at scale.

### 5. Custom policies fill governance gaps

Your custom Audit policy provides visibility where no built‑in policy exists.

### 6. The Azure Portal becomes governance‑aware

VM size dropdowns automatically filter based on allowed SKUs.

### 7. SKU governance requires tuning

Default VM images often select SKUs not in your allowed list.

### 8. Policy‑free vs policy‑enforced RGs behave differently

Your A/B comparison (`rg-identity-eus-lab-core` vs `rg-test-compliant`) demonstrated real Landing Zone behavior.

---

## Cleanup

Perform these steps if you want to reset your environment before moving to Lab 5.

---

### 1. Remove Locks

Locks must be removed **before** deleting any resource groups.

#### Resource Group Locks

Azure Portal → Resource groups → rg-locks-demo → Locks → Delete all locks

#### Resource-Level Locks

If you added a Read‑only lock:

Storage account → Locks → Delete

---

### 2. Remove Policy Assignments

#### Custom Audit Policy

Azure Portal → Policy → Assignments → audit-missing-environment-tag → Delete

#### SKU Restriction Policy

Azure Portal → Policy → Assignments → Allowed virtual machine size SKUs → Delete

This ensures no Deny or Audit rules remain active.

---

### 3. Delete Test Resource Groups

Once locks and policies are removed:

- Delete `rg-locks-demo`
- Delete `rg-test-compliant`
- Delete `rg-test-noncompliant`
- Keep `rg-identity-eus-lab-core` if you plan to use it for future labs

---

### 4. Verify a Clean State

Optional but helpful:

- Open **Azure Policy → Compliance**
- Confirm no custom assignments remain
- Confirm no RGs are stuck in a locked state

---

## Lab Summary

In this lab you learned:

- How to apply **Delete** and **Read-only** locks at different scopes
- How **lock inheritance** works and why resource-level tests must be isolated
- How locks override RBAC and prevent accidental changes
- How to build and assign a **Custom Audit Policy** to detect missing tags on resource groups
- Why Azure does **not** provide a built-in "Require tag on resource groups" policy
- How Audit policies provide visibility without blocking deployments
- How to enforce VM governance using the **Allowed virtual machine size SKUs** policy
- How Azure Policy dynamically **filters the VM size dropdown** to show only compliant SKUs
- How to compare behavior between **policy-restricted** and **policy-free** resource groups
- How governance controls (Locks + Policy) work together with RBAC to form a complete governance model
- How SKU governance requires tuning because default images often select disallowed SKUs

---

## Next Lab

**Lab 5 — Access Validation (Portal + CLI)**
[05-access-validation.md](05-access-validation.md)

## Previous Lab

**Lab 3 — Azure AD Roles + RBAC Scopes**
[03-azuread-roles-rbac-scopes.md](03-azuread-roles-rbac-scopes.md)

---

## Related Resources

- **Lab 1 — Identity Fundamentals + RBAC Basics**
  [01-identity-fundamentals.md](01-identity-fundamentals.md)

- **Lab 2 — Managed Identity + Azure Key Vault**
  [02-managed-identity-keyvault-secretless-auth.md](02-managed-identity-keyvault-secretless-auth.md)
