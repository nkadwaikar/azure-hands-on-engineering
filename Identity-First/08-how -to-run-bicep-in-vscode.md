# 🚀 How to Deploy Bicep Files Using Visual Studio Code  
*A VS Code-Only Workflow for Azure Architects*

This guide shows you how to deploy Bicep templates **entirely inside Visual Studio Code**, using the Azure extensions. No Azure Portal. No CLI. No switching tools.  
Just VS Code — clean, simple, and architect-friendly.

---

## 🧩 Prerequisites

Before deploying Bicep files, make sure you have:

### 1. Visual Studio Code Installed  
<https://code.visualstudio.com/>

### 2. Required VS Code Extensions
Install these from the Extensions panel:

- **Azure Account**  
- **Azure Resources**  
- **Bicep**

### 3. Sign in to Azure
In VS Code:

1. Open the **Azure** panel (left sidebar)  
2. Click **Sign in to Azure**  
3. Complete the login flow  

You should now see your subscriptions under the Azure Explorer.

---

## 📁 Folder Structure (Example)

Your project may look like this:

```plaintext
/bicep
    create-rg.bicep
    main.bicep
    /modules
        identity.bicep
        keyvault.bicep
        rbac.bicep
        locks.bicep
```

---

## 🚀 Deploying a Bicep File from VS Code

VS Code allows you to deploy any Bicep file with a simple right-click.

---

### Step 1 — Open the Bicep File

Open the file you want to deploy:

- `create-rg.bicep` (subscription-level)
- `main.bicep` (resource-group-level)

---

### Step 2 — Right-Click → Deploy Bicep File

Inside the editor:

1. Right-click anywhere in the Bicep file  
2. Select **Deploy Bicep File…**

VS Code automatically detects the deployment scope based on:

- `targetScope = 'subscription'`  
- `targetScope = 'resourceGroup'`

---

### Step 3 — Select Your Subscription

VS Code will prompt you to choose:

- The Azure subscription  
- (If RG-level) the Resource Group  
- (If subscription-level) the deployment location  

---

### Step 4 — Provide Parameter Values (If Needed)

If your Bicep file contains parameters:

```bicep
param rgName string
param location string
```

VS Code will ask you to:

- Enter values manually  
**or**
- Select a `.parameters.json` file  

If your parameters have default values, VS Code will skip this step.

---

### Step 5 — Watch Deployment Logs

VS Code opens the **Output** panel and shows:

- Deployment start  
- ARM template compilation  
- Resource creation  
- Success or error messages  

This gives you real-time visibility without leaving the editor.

---

## 🧪 Validating the Deployment (Inside VS Code)

Open the **Azure** panel:

- Expand your subscription  
- Expand the Resource Group  
- Confirm resources such as:
  - Managed Identity  
  - Key Vault  
  - RBAC Assignments  
  - Locks  

Everything can be validated directly inside VS Code.

---

## 🔁 Redeploying or Updating

To redeploy:

- Open the Bicep file  
- Right-click → **Deploy Bicep File…**

To delete resources:

- Right-click the Resource Group in Azure Explorer  
- Select **Delete Resource Group**

---

## 🎉 Summary

Using VS Code, you can:

- Deploy Bicep files at subscription or resource-group scope  
- Provide parameters interactively  
- Validate deployments directly in Azure Explorer  
- Stay fully inside the VS Code ecosystem