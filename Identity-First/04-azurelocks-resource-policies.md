# **Azure Locks + Resource Policies (Hands-On Lab)**  
### *Protect resources from accidental deletion and enforce governance at scale.*

Day 4 introduces two foundational governance controls used in every enterprise Landing Zone:  
**Resource Locks** (Delete / Read‑only) and **Azure Policy** (Deny / Audit / Modify).  
These controls enforce consistency, prevent accidental changes, and shape compliant deployments.

## 🎯 **Learning Objectives**

You will learn to:

- Apply **Delete** and **Read‑only** locks  
- Understand **lock inheritance**  
- Assign **custom and built‑in Azure Policies**  
- Enforce **tagging** and **SKU restrictions**  
- Validate compliance  
- Compare behavior between **policy‑restricted** and **policy‑free** resource groups  

---

# 🧪 **Lab Steps**

---

## **1. Create a Test Resource Group**

**Azure Portal → Resource groups → Create**

- Name: `rg-locks-demo`  
- Region: any  

---

## **2. Apply a Delete Lock at Resource Group Scope**

**rg-locks-demo → Settings → Locks → Add**

- Lock name: `rg-delete-lock`  
- Lock type: Delete  

### Expected Behavior
- RG cannot be deleted  
- Resources inside cannot be deleted  
- Resources **can still be modified**  

---

## **3. Test the Delete Lock**

Try deleting the RG → blocked  
Try deleting a resource → blocked  

---

## **4. Remove the Delete Lock (Important)**

To test Read‑only behavior correctly:

**rg-locks-demo → Locks → Delete**

---

## **5. Apply a Read‑Only Lock at Resource Scope**

Choose any resource (e.g., storage account):

**Storage account → Locks → Add**

- Lock name: `sa-readonly-lock`  
- Lock type: Read‑only  

### Expected Behavior
- Cannot modify  
- Cannot delete  
- Can view settings  
- Can read data (if RBAC allows)  

---

## **6. Remove the Read‑Only Lock**

**Storage account → Locks → Delete**

---

# **Azure Policy Section**

---

## **7. Assign a Custom Policy — Audit Resource Groups Missing a Tag**

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

### **Assign the Custom Policy**

**Azure Portal → Policy → Definitions → Select your custom policy → Assign**

- Scope: Subscription  
- Assignment name: `audit-missing-environment-tag`  
- Parameter:  
  - Tag Name: `environment`  

### Expected Behavior
- No deployments are blocked  
- RGs missing the tag appear as **Non‑compliant**  
- RGs with the tag appear as **Compliant**  

---

## **8. Test the Custom Policy**

Create:

- `rg-test-noncompliant` → no tag → **Non‑compliant**  
- `rg-test-compliant` → tag `environment=dev` → **Compliant**  

---

## **9. View Compliance**

**Azure Portal → Policy → Compliance**

Audit policies provide visibility without enforcement.

---

## **10. Enforce VM SKU Governance (Deny Policy)**

Assign:

**Policy:** Allowed virtual machine size SKUs  
**Scope:** `rg-test-compliant`

### Allowed SKUs (validated list)

```
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

# 🧩 **Governance + Identity Interaction**

- **Locks override RBAC**  
- **Policies override RBAC**  
- Directory roles cannot bypass governance  
- RBAC = *who* can act  
- Policy + Locks = *what* is allowed  

---

# 📘 **Lessons Learned — Day 4**

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

# 🧹 **Cleanup (Optional but Recommended)**

Perform these steps if you want to reset your environment before moving to Day 5.

---

## **1. Remove Locks**

Locks must be removed **before** deleting any resource groups.

### **Resource Group Locks**
**Azure Portal → Resource groups → rg-locks-demo → Locks → Delete all locks**

### **Resource-Level Locks**
If you added a Read‑only lock:

**Storage account → Locks → Delete**

---

## **2. Remove Policy Assignments**

### **Custom Audit Policy**
**Azure Portal → Policy → Assignments → audit-missing-environment-tag → Delete**

### **SKU Restriction Policy**
**Azure Portal → Policy → Assignments → Allowed virtual machine size SKUs → Delete**

This ensures no Deny or Audit rules remain active.

---

## **3. Delete Test Resource Groups**

Once locks and policies are removed:

- Delete `rg-locks-demo`  
- Delete `rg-test-compliant`  
- Delete `rg-test-noncompliant`  
- Keep `rg-identity-eus-lab-core` if you plan to use it for future labs  

---

## **4. Verify a Clean State**

Optional but helpful:

- Open **Azure Policy → Compliance**  
- Confirm no custom assignments remain  
- Confirm no RGs are stuck in a locked state  

---
## 📌 Day 4 Summary

Today you learned:

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

## ▶️ Next Lab

**Day 5 — Access Validation (Portal + CLI)**  
[05-access-validation.md](05-access-validation.md)

## ⬅️ Previous Lab

**Day 3 — Azure AD Roles + RBAC Scopes**  
[03-azuread-roles-rbac-scopes.md](03-azuread-roles-rbac-scopes.md)

---

## 🔗 Related Resources

- **Day 1 — Identity Fundamentals + RBAC Basics**  
  [01-identity fundamentals.md](01-identity%20fundamentals.md)

- **Day 2 — Managed Identity + Azure Key Vault**  
  [02-managed Identity + Azure Key Vault (Secretless Authentication).md](02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md)