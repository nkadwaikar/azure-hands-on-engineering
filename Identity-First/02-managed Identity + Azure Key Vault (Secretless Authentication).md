# Managed Identity + Azure Key Vault (Secretless Authentication)

> **Prerequisites:** This lab continues from Day 1 (see `01-identity fundamentals.md`), using the same Resource Group (`rg-identity-eus-lab-core`).  
> **Note:** All user accounts use the placeholder domain `@contoso.com` to avoid exposing real Azure AD tenant domains.  
> **Admin Required:** Steps requiring IAM changes must be performed by an administrator with elevated privileges.

## 🎯 Learning Objectives

By the end of this lab, you will:

- Deploy a VM with a **system-assigned managed identity**
- Create an Azure Key Vault using **Azure RBAC**
- Store a secret securely in Key Vault
- Assign least-privilege RBAC roles to the VM identity
- Authenticate to Azure from the VM using its managed identity
- Retrieve a Key Vault secret **without any credentials**

This lab introduces the identity-first pattern used in modern cloud workloads.

---

# 🧪 Lab Steps

---

## 1. Prerequisites

Ensure you have completed:

- **Day 1 — Identity Fundamentals + RBAC Basics** (see `01-identity fundamentals.md`)
- Resource group: `rg-identity-eus-lab-core` (created in Day 1)

---

## 2. Deploy a VM with System-Assigned Managed Identity (Admin)

### 2.1 Create the VM

1. Go to **Azure Portal → Virtual machines**
2. Select **Create → Azure virtual machine**

**Configuration:**
- **Resource group:** `rg-identity-eus-lab-core`
- **VM name:** `vm-identity-eus-lab-app01`
- **Region:** Same as Resource Group
- **Image:** Ubuntu Server 22.04 LTS
- **Size:** Standard_B1s
- **Authentication type:** SSH public key
- **Username:** `azureuser`
- **SSH public key source:** Generate new key pair
- **Key pair name:** `bootcamp-key`

3. Click **Review + Create → Create**
4. Download the SSH key when prompted
5. Set proper permissions on the key:

```bash
chmod 400 ~/Downloads/bootcamp-key.pem
```

---

### 2.2 Enable Managed Identity

1. Navigate to **vm-identity-eus-lab-app01** in Azure Portal
2. In the left menu, select **Identity**
3. Under **System assigned** tab, switch Status to **On**
4. Click **Save**
5. Confirm the action

Azure automatically creates a service principal for the VM.

---

## 3. Create Azure Key Vault (Admin)

1. Go to **Azure Portal → Key Vaults**
2. Select **Create**
3. Configure the Key Vault:

**Basics:**
- **Resource group:** `rg-identity-eus-lab-core`
- **Key Vault name:** `kv-identity-eus-lab-core` (if unavailable, use your own globally unique suffix)
- **Region:** Same as Resource Group
- **Permission model:** Azure role-based access control (RBAC) ← **Important**

4. Click **Review + Create → Create**

---

## 4. Add a Secret to Key Vault

1. Open your Key Vault in Azure Portal
2. Navigate to **Objects → Secrets**
3. Click **Generate/Import**
4. Create a new secret:

- **Upload options:** Manual
- **Name:** `app-secret`
- **Secret value:** `SuperSecretValue123`

5. Click **Create**

---

## 5. Assign Key Vault RBAC Role to the VM Identity (Admin)

Grant the VM's managed identity permission to read secrets.

1. Open your **Key Vault**
2. Navigate to **Access Control (IAM)**
3. Click **Add → Add role assignment**
4. On the **Role** tab, select **Key Vault Secrets User**
5. Click **Next**
6. On the **Members** tab:
   - **Assign access to:** Managed identity
   - Click **Select members**
   - **Managed identity:** Virtual machine
  - Select **vm-identity-eus-lab-app01**
   - Click **Select**
7. Click **Review + assign**

### Expected Behavior

The VM identity now has permissions to:

✅ **Read** secrets  
❌ **Not** write or delete secrets  
❌ **Not** manage Key Vault settings  

This enforces the **principle of least privilege**.

---

## 6. Connect to the VM

1. Open **vm-identity-eus-lab-app01** in Azure Portal
2. Select **Connect → SSH**
3. Copy the connection command
4. In your local terminal, run:

```bash
ssh -i ~/Downloads/bootcamp-key.pem azureuser@<vm-public-ip>
```

Replace `<vm-public-ip>` with your VM's actual public IP address shown in the portal.

---

## 7. Install Azure CLI on the VM

Ubuntu VMs do not include Azure CLI by default. Install it on the VM:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

Verify the installation:

```bash
az version
```

---

## 8. Authenticate Using the VM's Managed Identity

Run the following command inside the VM:

```bash
az login --identity
```

### Expected Output

You should see a JSON response containing:

```json
{
  "environmentName": "AzureCloud",
  "homeTenantId": "...",
  "id": "...",
  "isDefault": true,
  "managedByTenants": [],
  "name": "systemAssignedIdentity",
  "state": "Enabled",
  "tenantId": "...",
  "user": {
    "assignedIdentityInfo": "MSI",
    "name": "systemAssignedIdentity",
    "type": "servicePrincipal"
  }
}
```

This confirms the VM successfully authenticated using its **system-assigned managed identity**.

---

## 9. Retrieve the Secret Using the VM Identity

Now retrieve the secret from Key Vault without any stored credentials:

```bash
az keyvault secret show \
  --vault-name kv-identity-eus-lab-core \
  --name app-secret \
  --query value -o tsv
```

**Important:** Replace `kv-identity-eus-lab-core` if you used a different globally unique Key Vault name.

### Expected Result

```
SuperSecretValue123
```

### ✅ What This Validates

- VM identity authentication
- RBAC permissions are correctly configured
- Key Vault access is working
- Zero credentials stored on the VM

---

# 🧠 Troubleshooting

### ❌ Error: `ForbiddenByRbac`

**Cause:** Missing or incorrect RBAC assignment  
**Fix:**  
1. Verify the role assignment in Key Vault → Access Control (IAM)
2. Ensure `Key Vault Secrets User` is assigned to `vm-identity-eus-lab-app01` managed identity
3. Wait 3-5 minutes for RBAC changes to propagate
4. Retry the command

---

### ❌ Error: `az: command not found`

**Cause:** Azure CLI not installed on the VM  
**Fix:** Install Azure CLI:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

Then verify:

```bash
az version
```

---

### ❌ Error: `ResourceNotFound`

**Cause:** Incorrect Key Vault name or the vault doesn't exist  
**Fix:**  
1. Verify the exact Key Vault name in Azure Portal (under Key Vaults)
2. Ensure the name includes any unique suffix you added
3. Use the exact name in the command

---

### ❌ Error: `Forbidden` or Permission Denied

**Cause:** RBAC propagation delay  
**Fix:**  
1. Wait 3-5 minutes after assigning the role
2. Try logging out and back in: `az logout && az login --identity`
3. Verify the role assignment in the portal

---

### ❌ SSH Connection Issues

**Cause:** Incorrect key permissions or incorrect path  
**Fix:**  

1. Set correct permissions:
```bash
chmod 400 ~/Downloads/bootcamp-key.pem
```

2. Verify the key path matches the download location

3. If you saved the key elsewhere, update the path accordingly

---

### ❌ Error: `The client with object id does not have authorization`

**Cause:** Role assignment not completed or propagated  
**Fix:**  
1. Confirm the managed identity is enabled on the VM
2. Re-verify the RBAC assignment
3. Ensure you selected the correct managed identity (VM, not user-assigned)

---

## 10. Clean Up (Optional)

To remove all resources created in this lab:

```bash
az group delete \
  --name rg-identity-eus-lab-core \
  --yes \
  --no-wait
```

**Warning:** This will delete the entire resource group and all resources within it, including resources from Day 1.

---

## 📌 Day 2 Summary

Today you learned:

- How **system-assigned managed identities** provide automatic identity management for Azure resources
- How **Azure Key Vault with RBAC** offers centralized secret management with granular access control
- How **RBAC role assignments** enable least-privilege access patterns
- How **secretless authentication** eliminates the need to store credentials in code or configuration
- How **OAuth token-based authentication** enables secure service-to-service communication

---
## ▶️ Next Lab

**Day 3 — Azure AD Roles + RBAC Scopes**  
[03-azuread-roles-rbac-scopes.md](03-azuread-roles-rbac-scopes.md)

## ⬅️ Previous Lab

**Day 1 — Identity Fundamentals + RBAC Basics**  
[01-identity fundamentals.md](01-identity%20fundamentals.md)

---

## 🔗 Related Resources

- **Day 4 — Azure Locks + Resource Policies**  
  [04-azurelocks-resource-policies.md](04-azurelocks-resource-policies.md)

- **Day 5 — Access Validation (Portal + CLI)**  
  [05-access-validation.md](05-access-validation.md)