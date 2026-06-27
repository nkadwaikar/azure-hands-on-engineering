# Identity Fundamentals (Entra ID, RBAC Scopes, Least Privilege)

> **Why this matters:** Teams that bolt on identity controls after the fact end up with overprivileged service accounts, shared credentials, and no auditability — this lab builds the RBAC fundamentals (users, roles, scope inheritance, least privilege) that every subsequent governance control in this track depends on.
> **Note:** All user accounts in this lab use the placeholder domain `@contoso.com` to avoid exposing my real Azure AD tenant domain.  
> Steps **1**, **2**, and **3.2** are performed by administrators with elevated privileges.

Last validated on: 2026-06-25  
Portal experience note: Steps validated against Azure Portal as of June 2026; labels can vary slightly by region and feature rollout.

---

## Prerequisites

Before starting this lab, ensure you have:

- An **Azure Subscription** with Owner or User Access Administrator rights
- Permission to create **Azure AD users** (or admin assistance available)
- **Azure CLI** installed (optional, for CLI commands)
  - Installation guide: <https://learn.microsoft.com/cli/azure/install-azure-cli>
- Access to **Azure Portal**

**⏱️ Estimated Time:** 45–60 minutes

## Learning Objectives

By the end of this lab, you will:

- Understand Azure AD (Entra ID) identity structure  
- Understand RBAC scopes and inheritance  
- Create a test user for RBAC validation  
- Assign roles at Subscription, Resource Group, and Resource scopes  
- Validate least-privilege behavior from a test user's perspective  

---

## Lab Steps

---

## 1. Create BootCamp User (Admin)

### Admin Task

Create a non-admin user for RBAC testing:

- **User principal name:** `alex.james@contoso.com`  
- **Display name:** Alex James  
- **Role:** No admin roles  

This user will be used to validate RBAC behavior throughout this track.

### Using Azure Portal

1. Navigate to **Azure Active Directory → Users**
2. Click **New user → Create new user**
3. Fill in the details:
   - **User principal name:** `alex.james@contoso.com`
   - **Display name:** `Alex James`
   - **Auto-generate password:** Enabled (or set a secure password)
4. Click **Create**

### Using Azure CLI

```bash
az ad user create \
  --display-name "Alex James" \
  --user-principal-name alex.james@contoso.com \
  --password <SecurePassword123!> \
  --force-change-password-next-sign-in false
```

> 💡 **Tip:** Save the password securely — you'll need it to sign in as this user.

---

## 2. Create Resource Group

### Using the Azure Portal

1. Open **Azure Portal**  
2. Search for **Resource groups**  
3. Click **Create**  
4. Fill in the following:
   - **Subscription:** Select your subscription

- **Resource group:** `rg-identity-eus-lab-core`
- **Region:** Your preferred region (e.g., East US)

1. Click **Review + Create → Create**

### Using Azure CLI (Resource Group)

```bash
az group create \
  --name rg-identity-eus-lab-core \
  --location eastus
```

**Verify creation:**

```bash
az group show --name rg-identity-eus-lab-core --output table
```

---

## 3. Assign RBAC Roles at Different Scopes

Azure RBAC hierarchy operates in a top-down inheritance model:

```text
Subscription → Resource Group → Resource
```

### 3.1 Subscription Scope (Information Only)

- **Role:** Reader  
- **Scope:** Subscription  
- **Effect:** Would allow viewing all resources across the entire subscription  
- **Action:** **Do not assign this role** — included only for conceptual understanding of scope hierarchy.

---

### 3.2 Resource Group Scope - Actual Assignment

Assign Alex the **Contributor** role at the Resource Group scope.

#### Assign Role Using Azure Portal

1. Navigate to **Resource groups → rg-identity-eus-lab-core**
2. Click **Access control (IAM)** in the left menu
3. Click **Add → Add role assignment**
4. On the **Role** tab:
   - Select **Contributor**
   - Click **Next**
5. On the **Members** tab:
   - Click **Select members**
   - Search for `alex.james@contoso.com`
   - Click on the user
   - Click **Select**
6. Click **Review + assign** (twice)

#### Assign Role Using Azure CLI

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Assign Contributor role at Resource Group scope
az role assignment create \
  --assignee alex.james@contoso.com \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-identity-eus-lab-core
```

#### Verify the Assignment

```bash
az role assignment list \
  --assignee alex.james@contoso.com \
  --resource-group rg-identity-eus-lab-core \
  --output table
```

**Expected output:**

```table
Principal                    Role         Scope
---------------------------  -----------  -----------------------------------
alex.james@contoso.com       Contributor  /subscriptions/.../resourceGroups/rg-identity-eus-lab-core
```

---

#### Expected Behavior

When Alex signs in to Azure Portal:

- Only `rg-identity-eus-lab-core` is visible under Resource Groups  
- No other resource groups appear  
- Attempts to access or create resources outside this RG result in **Access denied**  

This validates **RBAC scoping** and **least-privilege** principles.

---

## 4. Validate RG-Level RBAC (Login as Test User)

**Sign in as:** `alex.james@contoso.com`

### Steps to Validate

1. Go to **Azure Portal → Resource Groups**  
2. Confirm that **only** `rg-identity-eus-lab-core` is visible  
3. Attempt the following (all should fail):  
   - View subscription-level settings  
   - Create a resource in a different resource group  
   - Access another resource group or resource  
   - Navigate to **Subscriptions** (no subscriptions visible)

### Expected Result

All attempts outside `rg-identity-eus-lab-core` should return:

```text
 Access denied
```

This confirms **correct RBAC enforcement** at the Resource Group scope.

---

## 5. Test RBAC Inheritance (Admin + Test User)

### Admin: Create a Test Resource

Create a Storage Account inside `rg-identity-eus-lab-core` to test inheritance.

#### Admin: Using Azure Portal

1. Navigate to **Storage accounts → Create**
2. Fill in:
   - **Subscription:** Your subscription
   - **Resource group:** `rg-identity-eus-lab-core`
   - **Storage account name:** `stidentitylabcore01` (must be globally unique in your tenant)
   - **Region:** Same as the resource group
   - **Performance:** Standard
   - **Redundancy:** Locally-redundant storage (LRS)
3. Click **Review + Create → Create**

#### Admin: Using Azure CLI

```bash
# Generate a unique storage account name
STORAGE_NAME="stidentitylabcore01"

az storage account create \
  --name $STORAGE_NAME \
  --resource-group rg-identity-eus-lab-core \
  --location eastus \
  --sku Standard_LRS
```

---

### Test User: Validate Inherited Permissions

Sign in as `alex.james@contoso.com` and navigate to the storage account.

#### Actions the User CAN Perform

- View the storage account details
- Modify storage account configuration (e.g., change access tier)
- Create blob containers
- Upload and manage blobs
- View metrics and logs

#### Actions the User CANNOT Perform

- Assign IAM roles on the storage account (requires Owner or User Access Administrator)
- Access resources outside `rg-identity-eus-lab-core`
- View or modify subscription-level settings

---

### Understanding RBAC Inheritance

This demonstrates how **RBAC permissions inherit down the scope hierarchy**:

```text
Contributor at RG → Contributor on ALL resources inside RG
```

The Contributor role assigned at the `rg-identity-eus-lab-core` scope automatically applies to:

- The storage account
- Any future resources created in this RG

---

## 6. RBAC Misconfigurations to Observe

Test these scenarios to understand RBAC behavior:

| Scenario | Expected Result | Reason |
| --------- | --------------- | -------- |
| User tries to access another RG | Access denied | No role assigned at that scope |
| User tries to assign IAM roles | Access denied | Contributor cannot manage IAM (requires Owner) |
| User tries to view subscription billing | Access denied | No subscription-level permissions |
| User tries to delete the RG | Allowed | Contributor can delete resource groups |
| User tries to create resources in the RG | Allowed | Contributor has full resource management rights |

This reinforces the importance of **proper scope selection** when assigning roles.

---

## 7. Troubleshooting RBAC

### Issue: User sees no resource groups  

**Cause:** No roles assigned to the user  
**Fix:** Assign Contributor at Resource Group scope

**Verify role assignment:**

```bash
az role assignment list \
  --assignee alex.james@contoso.com \
  --all \
  --output table
```

---

### Issue: User cannot modify resources  

**Cause:** Reader role assigned instead of Contributor  
**Fix:** Update the role assignment

**Check current role:**

```bash
az role assignment list \
  --assignee alex.james@contoso.com \
  --resource-group rg-identity-eus-lab-core \
  --query "[].roleDefinitionName" \
  --output tsv
```

**Remove Reader and assign Contributor:**

```bash
# Remove Reader role
az role assignment delete \
  --assignee alex.james@contoso.com \
  --role Reader \
  --resource-group rg-identity-eus-lab-core

# Assign Contributor role
az role assignment create \
  --assignee alex.james@contoso.com \
  --role Contributor \
  --resource-group rg-identity-eus-lab-core
```

---

### Issue: RBAC changes not applying immediately  

**Cause:** Role assignment propagation delay (typically 3–5 minutes)  
**Fix:** Wait, then re-test

**Force token refresh:**

1. Sign out of Azure Portal completely
2. Clear browser cache (optional but recommended)
3. Sign back in
4. Wait 5 minutes and retry

**Verify propagation status:**

```bash
az role assignment list \
  --assignee alex.james@contoso.com \
  --resource-group rg-identity-eus-lab-core
```

---

## 8. Clean Up (Optional)

### Admin Task: Clean Up Resources

### Delete the Resource Group

This will delete all resources inside it (including the storage account):

```bash
az group delete \
  --name rg-identity-eus-lab-core \
  --yes \
  --no-wait
```

### Delete the Test User

```bash
az ad user delete \
  --id alex.james@contoso.com
```

**Verify deletion:**

```bash
az group list --query "[?name=='rg-identity-eus-lab-core']" --output table
az ad user show --id alex.james@contoso.com 2>/dev/null || echo "User deleted"
```

---

## Lab Summary

In this lab you learned:

- How **Azure identity hierarchy** works (users → groups → service principals)
- How **RBAC scopes** and **inheritance** behave (Subscription → RG → Resource)
- How to assign roles using **Azure Portal** and **Azure CLI**
- How **least-privilege access** is enforced through scoping
- How to **validate and troubleshoot** RBAC assignments

---

## ▶️ Next Lab

**Lab 2 — Managed Identity + Azure Key Vault**  
[02-managed Identity + Azure Key Vault (Secretless Authentication).md](02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md)

---

## 🔗 Related Resources

- **Lab 3 — Azure AD Roles + RBAC Scopes**  
  [03-azuread-roles-rbac-scopes.md](03-azuread-roles-rbac-scopes.md)

- **Lab 4 — Azure Locks + Resource Policies**  
  [04-azurelocks-resource-policies.md](04-azurelocks-resource-policies.md)

---
