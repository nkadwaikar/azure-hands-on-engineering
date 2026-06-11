# Azure Policy Auto-Remediation (Portal-Only)

**End-to-End Hands-On Lab for Real-World Auto-Remediation Pipelines**

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Azure Role | **Owner** or **Contributor + Policy Contributor** on the target subscription |
| Subscription | Pay-As-You-Go or Visual Studio subscription |
| Estimated Time | 45-60 minutes |
| Tools | Azure Portal only — no CLI, ARM, or Bicep required |

---

## Lab Outcome

By the end of this lab, you will have:

- A custom Azure Policy using the **DeployIfNotExists (DINE)** effect
- A **System-Assigned Managed Identity** for remediation
- A **Remediation Task** that automatically fixes non-compliant resources
- A validated compliance lifecycle: **Assign → Detect → Remediate → Validate → Monitor**

This is the exact workflow used in enterprise governance baselines.

---

## Scenario

**Ensure all Storage Accounts have Secure Transfer Enabled.**
If a storage account is non-compliant, Azure Policy will auto-remediate and enable it.
This is the most common real-world DINE example.

---

## Lab Architecture

Components you will configure:

- Azure Policy Definition (DINE effect)
- Policy Assignment
- System-Assigned Managed Identity
- Role Assignment (Storage Account Contributor)
- Remediation Task
- Compliance Dashboard
- Monitor Alerts (optional)

---

## Lab Steps

---

### Step 0 — Create a Resource Group

Before deploying resources, create a dedicated resource group for this lab.

1. Go to **Azure Portal → Resource Groups → Create**
2. Fill in:
   - **Subscription:** Your target subscription
   - **Resource Group Name:** `rg-policy-autoremedy-eus-lab` (or adjust region code as needed)
   - **Region:** East US (or your preferred region)
3. Click **Review + Create → Create**

> **Expected state:** The resource group is created and visible in your subscription under **Resource Groups**.

---

### Step 1 — Create a Non-Compliant Resource

This gives you something to remediate.

1. Go to **Azure Portal → Storage Accounts → Create**
2. Fill in:
   - **Subscription:** Your target subscription
   - **Resource Group:** `rg-policy-autoremedy-eus-lab` (created in Step 0)
   - **Storage Account Name:** `stpolicyremedy01` (must be globally unique; adjust as needed)
   - **Region:** Same as your resource group (East US)
3. Under the **Advanced** tab, set **Secure transfer required** = **Disabled**
4. Complete the remaining fields and click **Review + Create → Create**

> **Expected state:** The storage account is created with HTTPS enforcement off. It will show as **Non-Compliant** after policy evaluation (up to 30 minutes after assignment).

---

### Step 2 — Create a Custom Azure Policy (DeployIfNotExists)

1. Go to **Azure Portal → Policy → Definitions**
2. Click **+ Policy Definition**
3. Fill in:
   - **Definition Location:** Your subscription
   - **Name:** `Enforce Secure Transfer on Storage Accounts`
   - **Category:** Custom
4. Paste the following JSON into the **Policy Rule** box:

```json
{
  "mode": "All",
  "parameters": {
    "storageAccountName": {
      "type": "String",
      "metadata": { "displayName": "Storage Account Name" }
    },
    "storageAccountLocation": {
      "type": "String",
      "metadata": { "displayName": "Storage Account Location" }
    }
  },
  "policyRule": {
    "if": {
      "field": "type",
      "equals": "Microsoft.Storage/storageAccounts"
    },
    "then": {
      "effect": "DeployIfNotExists",
      "details": {
        "type": "Microsoft.Storage/storageAccounts",
        "existenceCondition": {
          "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
          "equals": true
        },
        "roleDefinitionIds": [
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"
        ],
        "deployment": {
          "properties": {
            "mode": "incremental",
            "parameters": {
              "storageAccountName": { "value": "[field('name')]" },
              "storageAccountLocation": { "value": "[field('location')]" }
            },
            "template": {
              "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
              "contentVersion": "1.0.0.0",
              "parameters": {
                "storageAccountName": { "type": "string" },
                "storageAccountLocation": { "type": "string" }
              },
              "resources": [
                {
                  "type": "Microsoft.Storage/storageAccounts",
                  "apiVersion": "2022-09-01",
                  "name": "[parameters('storageAccountName')]",
                  "location": "[parameters('storageAccountLocation')]",
                  "properties": {
                    "supportsHttpsTrafficOnly": true
                  }
                }
              ]
            }
          }
        }
      }
    }
  }
}
```

Click **Save**.

> **Expected state:** The policy definition appears under **Policy → Definitions** in your custom category.

---

### Step 3 — Assign the Policy

1. Go to **Policy → Assignments → Assign Policy**
2. Set:
   - **Scope:** Your subscription or resource group
   - **Policy definition:** Select the policy you just created
3. On the **Remediation** tab:
   - Check **Create a remediation task**
   - **Managed Identity type:** System assigned
   - **Location:** Same region as your storage account
4. Click **Review + Create → Create**

> **Note:** Azure Policy evaluation runs on a schedule (up to **30 minutes** after assignment). Non-compliant resources will not appear immediately — this is expected behaviour.

---

### Step 4 — Grant the Managed Identity Required Permissions

Azure creates the managed identity automatically, but you must verify the role assignment.

1. Go to **Subscription → Access Control (IAM)**
2. Click **Add → Add Role Assignment**
3. Set:
   - **Role:** Storage Account Contributor
   - **Assign access to:** Managed Identity
   - **Members:** Select the managed identity created by the policy assignment (named after the assignment)
4. Click **Review + Assign**

> This is required for DINE to modify storage accounts. Without this, remediation tasks will fail with an authorization error.

---

### Step 5 — Trigger a Remediation Task

1. Go to **Policy → Remediation**
2. Click **+ New Remediation Task**
3. Set:
   - **Policy assignment:** Your assignment
   - **Scope:** The resource group containing the non-compliant storage account
4. Click **Remediate**

Azure will:
- Detect non-compliant storage accounts in scope
- Deploy the ARM template via the managed identity
- Enable **Secure Transfer Required** on each non-compliant account

> **Expected state:** The remediation task status progresses from **Evaluating → Deploying → Succeeded**.

---

### Step 6 — Validate Auto-Remediation

**Check policy compliance:**

1. Go to **Policy → Compliance**
2. Open your policy assignment
3. The resource state should show: **Non-Compliant → Remediating → Compliant**

**Verify the storage account directly:**

1. Go to **Storage Accounts → [your account] → Configuration**
2. Confirm: **Secure transfer required = Enabled**

> **Expected state:** Both the policy compliance view and the storage account configuration confirm the setting is enabled.

---

### Step 7 — Add Monitoring and Alerts (Optional)

Track governance drift across your environment with alerts.

1. Go to **Monitor → Alerts → + Create Alert Rule**
2. Set:
   - **Scope:** Your subscription
   - **Signal:** `Policy State Changed` (under Azure Policy category)
   - **Condition:** Non-compliant count > 0
3. Create an **Action Group** with your email or a Teams webhook
4. Name the alert and click **Review + Create**

> **Expected state:** You receive a notification whenever a new non-compliant resource is detected in scope.

---

## What Makes This Lab Production-Ready

| Capability | Why It Matters |
|---|---|
| DeployIfNotExists effect | Real-world auto-remediation, not just audit |
| Managed Identity | No secrets or stored credentials |
| Parameterised ARM template | Correct resource targeting by name and location |
| Least-privilege role assignment | Follows Zero Trust principles |
| Remediation Tasks | Fixes existing non-compliant resources, not just new ones |
| Monitor Alerts | Enterprise-grade governance drift detection |

---

## Cleanup

To avoid ongoing charges and clutter, remove resources after the lab:

1. **Policy → Assignments** — Delete the policy assignment
2. **Policy → Definitions** — Delete the custom policy definition
3. **Subscription → IAM** — Remove the Storage Account Contributor role assignment for the managed identity
4. **Storage Accounts** — Delete the storage account created in Step 1
5. **Resource Group** — Delete the resource group if it was created solely for this lab

---

## Next Steps

- [Azure Monitor and Activity Logs](../Identity-First/06-azuremonitor-activity-logs.md) — Monitor policy and resource changes
- [Azure Locks and Resource Policies](../Identity-First/04-azurelocks-resource-policies.md) — Prevent accidental configuration drift
- [Bicep Deployment — Identity Stack](../Identity-First/07-bicep-deployment-identity-stack.md) — Automate governance baselines with Bicep