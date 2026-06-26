
# **Azure AD Roles + RBAC Scopes (Hands‑On Lab)**  

> **Why this matters:** Assigning roles without understanding the boundary between Entra directory roles and Azure RBAC creates either access gaps or blast-radius that can't be cleanly audited — this lab maps both role systems, assigns roles at multiple scopes, and validates behavior from the user's perspective.

## *Directory roles vs resource roles. Control plane vs data plane. Identity clarity unlocked.*

> This lab builds on Day 1 (RBAC Basics) and Day 2 (Managed Identity + Key Vault).  
> All user accounts use the placeholder domain `@contoso.com` to avoid exposing my real Microsoft Entra ID tenant domain.  
> Steps requiring IAM changes must be performed by an administrator with elevated privileges.

## 🎯 Learning Objectives

By the end of this lab, you will:

- Understand the difference between **Microsoft Entra ID roles** and **Azure RBAC roles**
- Assign directory roles and resource roles to different users
- Validate permissions from the user's perspective
- Understand control‑plane vs data‑plane access
- Observe least‑privilege behavior in real time

---

## 🧪 Lab Steps

---

## **1. Create a Second Test User (Admin)**

This user will test Microsoft Entra ID directory roles.

- **User principal name:** `emma.lee@contoso.com`  
- **Display name:** Emma Lee  
- **Role:** No admin roles  

---

## **2. Assign a Microsoft Entra ID Role (Directory Role)**

Assign Emma the **User Administrator** role.

### Azure Portal → Microsoft Entra ID → Roles and administrators → User Administrator

Add assignment:

- **User:** `emma.lee@contoso.com`

### Expected Behavior

Emma can:

- Create users  
- Reset passwords for **standard users**  
- Manage groups  

Emma **cannot**:

- Reset passwords for privileged admin roles  
- Reset her own password  
- Reset passwords if **MFA is required but not configured**  
- Access Azure resources  
- Create VMs  
- Modify resource groups  
- Access Key Vault  

This demonstrates the separation between **identity management** and **resource management**.

---

## **3. Validate Microsoft Entra ID Role Permissions (Login as Emma)**

Sign in as: `emma.lee@contoso.com`

### ✔ Allowed Actions

1. Go to **Microsoft Entra ID → Users**
2. Create a new user (e.g., `test.user@contoso.com`)
3. Reset password for standard users (after MFA registration)
4. Add user to a group

### ❌ Denied Actions

Try to:

- Open **Subscriptions**
- Open **Resource groups**
- Create a VM
- Access Key Vault

Expected:  
`Access denied` — Emma has **no RBAC roles**.

---

## **4. Assign Azure RBAC Reader Role to Emma (Subscription Scope)**

Now add a resource role so Emma can view Azure resources without modifying them.

### Azure Portal → Subscriptions → Access control (IAM) → Add role assignment

Configure:

- **Role:** Reader
- **Assign access to:** User, group, or service principal
- **Member:** `emma.lee@contoso.com`

### Validate Reader Scope

Sign back in as: `emma.lee@contoso.com`

Emma can now:

- Open **Subscriptions**, **Resource Groups**, and resource blades
- View resources across subscription scope

Emma still cannot:

- Create, update, or delete resources
- Assign RBAC roles
- Read Key Vault secrets without a data-plane role

This demonstrates that **Reader adds visibility only**, while directory and data-plane permissions remain separate.

## **5. Compare Emma vs Alex (From Day 1)**

| User | Microsoft Entra ID Role | RBAC Role | What They Can Do |
| --- | --- | --- | --- |
| **Alex** | None | Contributor (Resource Group) | Full control **inside `rg-identity-eus-lab-core`** only |
| **Emma** | User Administrator | Reader (Subscription) | Manage users in Microsoft Entra ID, view all Azure resources but **cannot create or modify anything** |

### ✔ Correct Interpretation

**Emma (User Administrator + Reader)**  

- Can navigate across Azure  
- Can view all resources  
- Can manage users  
- Cannot create or modify Azure resources  
- Cannot read Key Vault secrets  
- Cannot assign RBAC roles  

**Alex (Contributor at RG)**  

- Can navigate Azure  
- Can create/modify/delete resources **inside `rg-identity-eus-lab-core`**  
- Cannot manage users  
- Cannot read Key Vault secrets  

### 🧠 Key Insight

- **Emma has broad visibility but zero resource power.**  
- **Alex has limited visibility but full power inside his RG.**  
- **Emma controls identities. Alex controls resources.**  
- **Neither can read Key Vault secrets without a data‑plane role.**

---

## 📌 Day 3 Summary

Today you learned:

- How **Microsoft Entra ID roles** and **Azure RBAC roles** differ
- How **directory roles** affect identity management
- How **RBAC roles** affect resource access
- How **scope inheritance** works across control and data planes
- How **control-plane and data-plane permissions** differ in Azure
- Why **least-privilege** requires both systems to be configured correctly
- How **User Administrator** can reset passwords for standard users (with MFA, non-admin targets, and non-self restrictions)

---
These nuances reflect real enterprise identity governance and are essential for AZ‑104, AZ‑305, and AZ‑500.

---

## ▶️ Next Lab

**Day 4 — Azure Locks + Resource Policies**  
[04-azurelocks-resource-policies.md](04-azurelocks-resource-policies.md)

## ⬅️ Previous Lab

**Day 2 — Managed Identity + Azure Key Vault**  
[02-managed Identity + Azure Key Vault (Secretless Authentication).md](02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md)

---

## 🔗 Related Resources

- **Day 1 — Identity Fundamentals + RBAC Basics**  
  [01-identity fundamentals.md](01-identity%20fundamentals.md)

- **Day 5 — Access Validation (Portal + CLI)**  
  [05-access-validation.md](05-access-validation.md)
