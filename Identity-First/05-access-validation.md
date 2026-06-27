# **Access Validation (Portal + CLI)**

> **Why this matters:** Governance controls that have never been tested from the user's perspective — a different role, a different scope — provide a false sense of security; this lab proves the RBAC, lock, and policy stack actually blocks and permits the right operations before it goes anywhere near production.

## *Validate RBAC, Identity, Locks, and Policy Enforcement Across Real Access Paths*

Day 5 is where you **prove** that everything you built in Days 1–4 works exactly as intended.
This lab validates RBAC, Managed Identity, locks, and policies using both the **Azure Portal** and **Azure CLI** — the same way real cloud engineers test governance in production environments.

## 🔧 **Prerequisites (Rebuild Environment if Cleaned Up)**

If you removed resources after Day 4, recreate the following:

### **Resource Groups**

- `rg-identity-eus-lab-core` (policy-free sandbox)  
- `rg-test-compliant` (policy-restricted RG)

### **Policies**

- Assign your **Custom Audit Policy — Audit Resource Groups Missing a Tag** at subscription scope  
- Assign **Allowed VM Size SKUs** to `rg-test-compliant`

### **VM for Identity Tests**

Deploy a VM with:

- System-assigned managed identity  
- Ubuntu or Windows (your choice)  
- In `rg-identity-eus-lab-core` (no restrictions)

### **Optional**

- Create a Key Vault for MI access tests  

This ensures Day 5 starts with a clean, consistent environment.

---

## **Learning Objectives**

By the end of this lab, you will:

- Validate RBAC permissions using **Portal** and **CLI**  
- Confirm that **locks override RBAC**  
- Confirm that **policies override RBAC**  
- Validate **Managed Identity** access paths  
- Test **deny**, **audit**, and **read-only** behaviors  
- Compare **restricted** vs **unrestricted** environments  
- Validate governance across multiple identity types  

---

## **Lab Steps**

---

### **1. Validate RBAC in the Azure Portal**

#### **Test 1 — Reader Role**

Log in as a user with **Reader** on `rg-identity-eus-lab-core`.

Try the following:

- View resources →  Allowed  
- Modify a resource →  Denied  
- Delete a resource →  Denied  

This confirms Reader = view-only.

---

#### **Test 2 — Contributor Role**

Log in as a user with **Contributor** on `rg-identity-eus-lab-core`.

Try:

- Create a VM →  Allowed  
- Modify resources →  Allowed  
- Assign RBAC →  Denied  

Contributor cannot grant permissions — correct behavior.

---

#### **Test 3 — Owner Role**

Log in as **Owner** on `rg-locks-demo`.

Try:

- Delete a locked resource →  Denied  
- Modify a locked resource →  Denied (if Read-only lock applied)

This confirms:

> **Locks override RBAC — even Owner cannot bypass them.**

---

### **2. Validate RBAC Using Azure CLI**

Log in:

```bash
az login
az account show
```

---

#### **Test 1 — List Role Assignments**

```bash
az role assignment list --scope /subscriptions/<subId>/resourceGroups/rg-identity-eus-lab-core -o table
```

Expected:

- Reader → read-only  
- Contributor → full modify  
- Owner → full control  

---

#### **Test 2 — Try to Delete a Locked Resource Group**

```bash
az group delete -n rg-locks-demo
```

Expected:

```text
Operation failed due to a lock on the resource group.
```

This proves locks override CLI.

---

#### **Test 3 — Try to Deploy a VM with a Disallowed SKU**

```bash
az vm create \
  --resource-group rg-test-compliant \
  --name vm-deny-test \
  --image Ubuntu2204 \
  --size Standard_D4s_v3
```

Expected:

```text
The resource is disallowed by policy.
```

This proves policies override CLI.

---

### **3. Validate Managed Identity Access**

SSH into your VM:

```bash
az vm run-command invoke ...
```

Or use the Portal console.

---

#### **Test 1 — Managed Identity → Key Vault (Allowed)**

If MI has access:

```bash
curl 'http://169.254.169.254/metadata/identity/oauth2/token?...'
az keyvault secret show --vault-name <kv> --name <secret>
```

Expected:  Allowed

---

#### **Test 2 — Managed Identity → Storage (Denied)**

If MI has no access:

```bash
az storage blob list ...
```

Expected:  Access denied

This validates identity-first access.

---

### **4. Validate Policy Enforcement**

---

#### **Test 1 — SKU Restriction (Deny)**

Portal → Create VM → Choose disallowed SKU  
Expected:  Blocked

CLI → Same test  
Expected:  Blocked

ARM/Bicep → Same test  
Expected:  Blocked

---

#### **Test 2 — Custom Audit Policy**

Create RG without tag:

```bash
az group create -n rg-audit-test -l eastus
```

Expected:

- Created  
- Marked **Non-compliant**

Create RG with tag:

```bash
az group create -n rg-audit-pass -l eastus --tags environment=dev
```

Expected:  Compliant

---

### **5. Validate Lock Enforcement**

---

#### **Test 1 — Delete Lock**

Portal → Delete RG →  Blocked  
CLI → `az group delete` →  Blocked  

---

#### **Test 2 — Read-Only Lock**

Portal → Modify resource →  Blocked  
CLI → Update resource →  Blocked  
Portal → View settings →  Allowed  

This proves lock behavior is consistent across interfaces.

---

### **6. A/B Environment Validation**

Compare:

#### **`rg-test-compliant` (Restricted)**

- SKU restrictions  
- Tag audit  
- Policy enforcement  
- Lock behavior  

#### **`rg-identity-eus-lab-core` (Unrestricted)**

- No policies  
- No restrictions  
- Full freedom  

This mirrors real Landing Zone design.

---

## 🧹 **Cleanup (Optional)**

### **1. Remove Locks**

- Delete locks from `rg-locks-demo`  
- Delete resource-level locks  

### **2. Remove Policy Assignments**

- Custom Audit Policy  
- Allowed VM Size SKUs  

### **3. Delete Test Resource Groups**

- `rg-locks-demo`  
- `rg-test-compliant`  
- `rg-test-noncompliant`  
- `rg-audit-test`  
- `rg-audit-pass`  

### **4. Delete Test VMs**

- Any VM created for MI or SKU tests  

---

## Day 5 Summary

Today you learned:

- How to validate **RBAC** using Portal and CLI
- How **locks override RBAC** and block even Owners
- How **policies override RBAC** and block deployments
- How **Managed Identity** behaves across services
- How to test **deny, audit, and read-only** behaviors
- How to validate governance across multiple identity types
- How to compare **restricted vs unrestricted** environments
- How to test governance using real-world access paths
- How to confirm your **Landing Zone governance model** works end-to-end

---

## ▶️ Next Lab

**Day 6 — Azure Monitor + Activity Logs**  
[06-azuremonitor-activity-logs.md](06-azuremonitor-activity-logs.md)

## ⬅️ Previous Lab

**Day 4 — Azure Locks + Resource Policies**  
[04-azurelocks-resource-policies.md](04-azurelocks-resource-policies.md)

---

## 🔗 Related Resources

- **Day 1 — Identity Fundamentals + RBAC Basics**  
  [01-identity fundamentals.md](01-identity%20fundamentals.md)

- **Day 2 — Managed Identity + Azure Key Vault**  
  [02-managed Identity + Azure Key Vault (Secretless Authentication).md](02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md)

- **Day 3 — Azure AD Roles + RBAC Scopes**  
  [03-azuread-roles-rbac-scopes.md](03-azuread-roles-rbac-scopes.md)
