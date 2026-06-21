# Azure Policy Auto-Remediation Lab Guide

A portal-only lab covering custom Azure Policy creation, managed identity-backed remediation, and compliance validation using a DeployIfNotExists workflow.

Navigation: [Lab Guide](../README.md)

Last validated on: 2026-06-19
Portal experience note: Steps validated against Azure Portal as of June 2026; labels can vary slightly by region and feature rollout.

> **Note:** This lab uses a custom policy with the DeployIfNotExists effect to enforce secure transfer on Azure Storage accounts. The workflow is designed for learning and validation, not as a substitute for broader enterprise policy design, exemptions, or change control.

---

## Module Structure

```text
Azure Policy Auto‑Remediation/
`-- 1-Azure Policy Auto‑Remediation.md
```

This module is a focused single-lab guide for Policy DeployIfNotExists auto-remediation.

## Quick Navigation

- Module Structure
- Prerequisites
- Learning Objectives
- Scenario
- Lab Architecture
- Lab Steps
- Validation and Monitoring
- Cleanup

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Owner** or **Contributor + Policy Contributor** on the target subscription |
| Subscription | Pay-As-You-Go or Visual Studio subscription |
| Estimated Time | 45-60 minutes |
| Tools | Azure Portal only — no CLI, ARM, or Bicep required |

Naming reference: [README Naming Convention](../README.md#naming-convention)

### Assumptions and Scope Boundaries

- The lab uses a non-production resource group and storage account.
- The policy is scoped narrowly for demonstration and validation.
- Policy exemptions, initiative definitions, and multi-subscription rollout are out of scope.
- Monitoring integration is mentioned but not implemented in depth in this walkthrough.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- A custom Azure Policy using the **DeployIfNotExists (DINE)** effect
- A **System-Assigned Managed Identity** for remediation
- A **Remediation Task** that automatically fixes non-compliant resources
- A validated compliance lifecycle: **Assign → Detect → Remediate → Validate → Monitor**

This is the exact workflow used in enterprise governance baselines.

---

## 3. Scenario

**Ensure all Storage Accounts have Secure Transfer Enabled.**
If a storage account is non-compliant, Azure Policy will auto-remediate it by enabling secure transfer.
This is the most common real-world DINE example.

---

## 4. Lab Architecture

Components you will configure:

- Azure Policy Definition (DINE effect)
- Policy Assignment
- System-Assigned Managed Identity
- Role Assignment (Storage Account Contributor)
- Remediation Task
- Compliance Dashboard
- Monitor Alerts (optional)

---

## 5. Lab Steps

---

### Step 0 — Create a Resource Group

Before deploying resources, create a dedicated resource group for this lab.

1. Go to **Azure Portal → Resource Groups → Create**

2. Fill in:

- **Subscription:** Your target subscription
- **Resource Group Name:** `rg-policy-eus-lab-remedy` (or adjust region code as needed)
- **Region:** East US (or your preferred region)

1. Click **Review + Create → Create**

> **Expected state:** The resource group is created and visible in your subscription under **Resource Groups**.

---

### Step 1 — Create a Non-Compliant Resource

This gives you something to remediate.

1. Go to **Azure Portal → Storage Accounts → Create**
2. Fill in:
   - **Subscription:** Your target subscription
   - **Resource Group:** `rg-policy-eus-lab-remedy` (created in Step 0)
   - **Storage Account Name:** `stpolicylabremedy01` (must be globally unique; adjust as needed)
   - **Region:** Same as your resource group (East US)
   - **Primary service:** Azure Blob Storage or Azure Data Lake Storage
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
            "template": {
              "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
              "contentVersion": "1.0.0.0",
              "resources": [
                {
                  "type": "Microsoft.Storage/storageAccounts",
                  "apiVersion": "2022-09-01",
                  "name": "[field('name')]",
                  "location": "[field('location')]",
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

1. Under **Parameters**, leave the section empty for this lab
2. Under **Review + create**, confirm the definition details and click **Save**

The policy uses the built-in **Storage Account Contributor** role definition so the managed identity can update the target storage account during remediation.

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

> **Note:** Azure Policy evaluation runs on a schedule and can take up to **30 minutes** after assignment. Non-compliant resources may not appear immediately; this is expected behavior.

---

### Step 4 — Trigger a Remediation Task

1. Go to **Policy → Remediation**
2. Click **+ New Remediation Task**
3. Set:
   - **Policy assignment:** Your assignment
   - **Scope:** The resource group containing the non-compliant storage account
4. Click **Remediate**

Azure will:

- Detect non-compliant storage accounts in scope
- Deploy the remediation template via the managed identity
- Enable **Secure Transfer Required** on each non-compliant account

> **Expected state:** The remediation task status progresses from **Evaluating → Deploying → Succeeded**.

---

### Step 5 — Validate Auto-Remediation

**Check policy compliance:**

1. Go to **Policy → Compliance**
2. Open your policy assignment
3. The resource state should show: **Non-Compliant → Remediating → Compliant**

**Verify the storage account directly:**

1. Go to **Storage Accounts → [your account] → Configuration**
2. Confirm: **Secure transfer required = Enabled**

> **Expected state:** Both the policy compliance view and the storage account configuration confirm the setting is enabled.

---

## 6. What Makes This Lab Production-Ready

| Capability | Why It Matters |
| --- | --- |
| DeployIfNotExists effect | Real-world auto-remediation, not just audit |
| Managed Identity | No secrets or stored credentials |
| Parameterized deployment template | Correct resource targeting by name and location |
| Least-privilege role assignment | Follows Zero Trust principles |
| Remediation Tasks | Fixes existing non-compliant resources, not just new ones |

---

## 7. Cleanup

To avoid ongoing charges and clutter, remove resources after the lab:

1. **Policy → Assignments** — Delete the policy assignment
2. **Policy → Definitions** — Delete the custom policy definition
3. **Subscription → IAM** — Remove the Storage Account Contributor role assignment for the managed identity
4. **Storage Accounts** — Delete the storage account created in Step 1
5. **Resource Group** — Delete the resource group if it was created solely for this lab

---

## 8. Next Steps

- [Azure Monitor and Activity Logs](../Identity-First/06-azuremonitor-activity-logs.md) — Monitor policy and resource changes
- [Azure Locks and Resource Policies](../Identity-First/04-azurelocks-resource-policies.md) — Prevent accidental configuration drift
- [Bicep Deployment — Identity Stack](../Identity-First/07-bicep-deployment-identity-stack.md) — Automate governance baselines with Bicep
