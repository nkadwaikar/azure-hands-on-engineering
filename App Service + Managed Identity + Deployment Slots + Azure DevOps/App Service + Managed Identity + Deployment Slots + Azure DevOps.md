# App Service + Managed Identity + Deployment Slots + Azure DevOps

> **Why this matters:** Hardcoded secrets in app settings or pipeline variables are one leaked token away from a breach — this lab removes every credential from the deployment chain by binding App Service to Key Vault through per-slot Managed Identity, with a staged CI/CD pipeline and manual approval gate controlling production promotion.

A portal-first lab covering Azure App Service deployment with System-Assigned Managed Identity, deployment slots for blue-green deployments, Key Vault secret integration, and a full Azure DevOps CI/CD pipeline with manual approval gates.

Last validated on: 2026-06-24

> **Note:** This lab uses placeholder resource names such as `app-appservice-wus2-lab` and `kv-appservice-wus2-lab`. Substitute your own names following your naming convention.

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Lab Architecture](#4-lab-architecture)
- [Create the Key Vault](#5-create-the-key-vault)
- [Create the App Service](#6-create-the-app-service)
- [Create a Deployment Slot](#7-create-a-deployment-slot)
- [Enable Managed Identity](#8-enable-managed-identity)
- [Copy Managed Identity Object IDs](#9-copy-the-managed-identity-object-id-for-each-slot)
- [Grant Key Vault Access](#10-grant-key-vault-access-to-both-slots)
- [Add Key Vault References](#11-add-key-vault-references-in-app-service-configuration)
- [Azure DevOps Pipeline](#12-azure-devops-pipeline-setup)
- [Test Slot Swap](#13-test-slot-swap)
- [Add Manual Approval Gates](#14-add-manual-approval-gates-enterprise-pattern)
- [Cleanup](#15-cleanup--teardown)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Owner** or **Contributor** on the target subscription |
| Subscription | Pay-As-You-Go or Visual Studio subscription |
| Estimated Time | 60–90 minutes |
| Tools | Azure Portal + Azure DevOps (dev.azure.com) |
| Azure DevOps | An Azure DevOps **organization** and **project** — create one at [dev.azure.com](https://dev.azure.com) if you don't have one |
| Repository | A Git repository inside that project (Azure Repos) or a connected GitHub repo with at least a placeholder app file committed |
| Key Vault | An existing Key Vault with at least one secret (e.g., `app-secret`) |

---

## 2. Learning Objectives

By the end of this lab, you will have:

- An App Service with a **staging deployment slot**
- **System-Assigned Managed Identity** enabled on both the production and staging slots
- A **Key Vault RBAC role assignment** granting both identities secret read access
- **Key Vault references** in App Service configuration (secretless authentication)
- A **multi-stage Azure DevOps YAML pipeline** that builds, deploys to staging, and swaps to production
- A **manual approval gate** controlling the production swap

---

## 3. Scenario

**Deploy a web application with zero secrets in code or pipelines.**

The App Service reads secrets from Key Vault via Managed Identity. A CI/CD pipeline deploys to a staging slot first, and a manual approval gate controls the promotion to production. This is the standard enterprise deployment pattern for regulated environments.

---

## 4. Lab Architecture

```text
Azure DevOps Pipeline
        |
        v
  [Build Stage]
        |
        v
  [Deploy to Staging Slot]  ---- Managed Identity ---- Key Vault
        |
        v  (Manual Approval Gate)
  [Swap: Staging to Production]
        |
        v
  App Service (Production)  ---- Managed Identity ---- Key Vault
```

**Resources created in this lab:**

| Resource | Name |
| --- | --- |
| Resource Group | `rg-appservice-wus2-lab` |
| App Service Plan | `asp-appservice-wus2-lab` (S1) |
| App Service | `app-appservice-wus2-lab` |
| Deployment Slot | `app-appservice-wus2-lab/staging` |
| Key Vault | `kv-appservice-wus2-lab` (pre-existing or create new) |
| DevOps Service Connection | `sc-appservice-lab` |

---

## 5. Create the Key Vault

A Key Vault stores and protects application secrets. If you already have a Key Vault in `rg-appservice-wus2-lab`, skip to [Grant Key Vault Access](#10-grant-key-vault-access-to-both-slots).

### Step 1 — Create the Key Vault Resource

1. Go to **Azure Portal** → **Key Vaults**
2. Click **+ Create**
3. Fill in the **Basics** tab:

| Field | Value |
| --- | --- |
| Resource Group | `rg-appservice-wus2-lab` |
| Key vault name | `kv-appservice-wus2-lab` |
| Region | `West US 2` (match your App Service region) |
| Pricing tier | `Standard` |

4. Click **Next: Access configuration**

### Step 2 — Set the Permission Model

5. Under **Permission model**, select **Azure role-based access control**
6. Leave all other settings as default
7. Click **Review + Create** → **Create**

> **Why RBAC:** The Azure RBAC model lets you assign Key Vault permissions using standard IAM role assignments, which is required for Managed Identity access in this lab. Selecting this now avoids having to switch the model later.

### Step 3 — Assign Yourself the Key Vault Administrator Role

You must have the **Key Vault Administrator** role to create and manage secrets.

1. Once deployment completes, click **Go to resource**
2. In the left menu, select **Access control (IAM)**
3. Click **+ Add** → **Add role assignment**
4. **Role tab:** search for and select **Key Vault Administrator** → click **Next**
5. **Members tab:** click **+ Select members** → search for your user account → select it
6. Click **Review + Assign** → **Assign**

> **Note:** Role assignment propagation can take up to 5 minutes. Wait before proceeding to the next step.

### Step 4 — Create the Secret

1. In the left menu, select **Objects** → **Secrets**
2. Click **+ Generate/Import**
3. Fill in:
   - **Upload options:** `Manual`
   - **Name:** `app-secret`
   - **Secret value:** enter any value (e.g., `MySuperSecretValue123!`)
   - Leave all other fields as default
4. Click **Create**

> **Note:** The secret name `app-secret` is what you reference in the Key Vault URI. The App Service config key (`MySecret`) is a separate name used inside your application code to read the value.

### Step 5 — Copy the Vault URI

1. In the left menu, select **Overview**
2. Confirm the Key Vault shows **Active**
3. Copy the **Vault URI** (e.g., `https://kv-appservice-wus2-lab.vault.azure.net`) — you will need it when adding Key Vault references in [section 11](#11-add-key-vault-references-in-app-service-configuration)

---

## 6. Create the App Service

### Step 1 — Open App Services

1. Go to **Azure Portal** → **App Services**
2. Click **+ Create**

### Step 2 — Fill in the Basics

Configure the following:

| Field | Value |
| --- | --- |
| Resource Group | `rg-appservice-wus2-lab` (create new if needed) |
| Name | `app-appservice-wus2-lab` |
| Publish | `Code` |
| Runtime stack | `.NET`, `Node`, or `Python` (any) |
| Region | `West US 2` (or your preferred region) |
| App Service Plan | Create new → `asp-appservice-wus2-lab` |
| Pricing plan | Standard S1 or higher (e.g., S1: 1.75 GB memory, 1 vCPU) |

Click **Review + Create** → **Create**

> **Note:** Deployment slots are available on **Standard (S1) tier and above**. They are not available on the Free or Shared tiers.

---

## 7. Create a Deployment Slot

1. Open **App Services** → **app-appservice-wus2-lab**
2. In the left menu, select **Deployment slots**
3. Click **+ Add Slot**
4. Configure:
   - **Name:** `staging`
   - **Clone settings from:** Do not clone
5. Click **Add**

You now have two slots:

- **Production:** `https://app-appservice-wus2-lab.azurewebsites.net`
- **Staging:** `https://app-appservice-wus2-lab-staging.azurewebsites.net`

---

## 8. Enable Managed Identity

Each deployment slot has its own identity in Azure AD. Enable Managed Identity on both slots separately.

### Step 1 — Enable on the Production Slot

1. Open **App Services** → **app-appservice-wus2-lab**
2. In the left menu, select **Identity**
3. Under **System assigned**, set **Status** to **On**
4. Click **Save** → confirm when prompted

### Step 2 — Enable on the Staging Slot

1. Go to **App Services** → **app-appservice-wus2-lab** → **Deployment slots**
2. Click the **staging** slot (this opens a separate blade)
3. In the left menu of the staging blade, select **Identity**
4. Under **System assigned**, set **Status** to **On**
5. Click **Save** → confirm when prompted

---

## 9. Copy the Managed Identity Object ID for Each Slot

You need the Object ID from both slots to grant Key Vault access to each identity independently.

### Production Slot

1. Open **App Services** → **app-appservice-wus2-lab**
2. In the left menu, select **Identity**
3. Under **System assigned**, confirm **Status** = **On**
4. Copy the **Object (principal) ID**

### Staging Slot

1. Go to **App Services** → **app-appservice-wus2-lab** → **Deployment slots**
2. Click the **staging** slot
3. In the left menu of the staging blade, select **Identity**
4. Under **System assigned**, confirm **Status** = **On**
5. Copy the **Object (principal) ID**

> **Why both Object IDs matter:** Azure treats each deployment slot as a separate identity in Microsoft Entra ID. Both identities must be granted Key Vault access independently.

---

## 10. Grant Key Vault Access to Both Slots

Assign the **Key Vault Secrets User** role to both App Service slot identities via IAM. The secret and permission model were configured in [section 5](#5-create-the-key-vault).

### Step 1 — Open Key Vault IAM

1. Go to **Azure Portal** → **Key Vaults** → select `kv-appservice-wus2-lab`
2. In the left menu, select **Access control (IAM)**
3. Click **+ Add** → **Add role assignment**

### Step 2 — Assign to the Production Slot

1. **Role tab:** search for and select **Key Vault Secrets User** → click **Next**
2. **Members tab:** click **+ Select members**
3. Search for `app-appservice-wus2-lab` and select the identity
4. Click **Review + Assign** → **Assign**

### Step 3 — Assign to the Staging Slot

Repeat the same steps:

1. **Add role assignment** → **Key Vault Secrets User**
2. **Members tab:** search for `app-appservice-wus2-lab (staging)` and select it
3. Click **Review + Assign** → **Assign**

### Verify the Assignments

Go to **Key Vault** → **Access control (IAM)** → **Role assignments**. You should see:

| Role | Principal |
| --- | --- |
| Key Vault Secrets User | `app-appservice-wus2-lab` |
| Key Vault Secrets User | `app-appservice-wus2-lab/staging` |

---

## 11. Add Key Vault References in App Service Configuration

Key Vault references allow the App Service to resolve secrets at runtime without storing credentials anywhere. Perform these steps for **both** the production slot and the staging slot.

### Step 1 — Open Environment Variables

1. Go to **Azure Portal** → **App Services** → `app-appservice-wus2-lab`
2. In the left menu, scroll to **Settings**
3. Click **Environment variables**
4. You will see the following tabs and controls:
   - **Application settings** tab
   - **+ Add** button
   - **Save** button

### Step 2 — Add the Key Vault Reference

1. Click **+ Add** under the **Application settings** tab
2. Fill in:
   - **Name:** `MySecret`
   - **Value:** Key Vault reference URI in the following format:

```text
@Microsoft.KeyVault(SecretUri=https://<your-key-vault-name>.vault.azure.net/secrets/<secret-name>/)
```

Example:

```text
@Microsoft.KeyVault(SecretUri=https://kv-appservice-wus2-lab.vault.azure.net/secrets/app-secret/)
```

3. Click **Apply** → **Save**

The App Service restarts automatically and resolves the reference on next startup.

### Step 3 — Repeat for the Staging Slot

1. Go to **App Services** → `app-appservice-wus2-lab` → **Deployment slots** → **staging**
2. In the left menu, scroll to **Settings** → click **Environment variables**
3. Under the **Application settings** tab, click **+ Add**
4. Enter the same **Name** and **Value** (Key Vault reference) as above
5. Click **Apply** → **Save**

### Verify the Key Vault Reference (New Portal UI)

After saving, return to **App Service** → **Settings** → **Environment variables** and locate `MySecret`.

> **Note:** The new Azure Portal UI does not show green or red status icons next to Key Vault references. Instead, check the value displayed in the **Value** column:

| Status | What you see |
| --- | --- |
| Working | The resolved secret value is shown |
| Failing | A warning message is displayed next to the setting |

If you see a warning message, work through the following checks in order:

| Check | Action |
| --- | --- |
| Managed Identity enabled | **App Service** → **Settings** → **Identity** → confirm **Status = On** for the slot |
| Role assignment propagated | Wait up to 5 minutes after assigning **Key Vault Secrets User** |
| RBAC permission model | **Key Vault** → **Settings** → **Access configuration** → confirm **Azure role-based access control** is selected |
| Correct secret name in URI | Verify the secret name in the Key Vault reference URI matches exactly the name in **Key Vault** → **Objects** → **Secrets** |

### Reading the Secret in Code

| Runtime | Code |
| --- | --- |
| .NET | `Environment.GetEnvironmentVariable("MySecret")` |
| Node.js | `process.env.MySecret` |
| Python | `os.getenv("MySecret")` |

---

## 12. Azure DevOps Pipeline Setup

At this point, the environment includes:

- App Service
- Staging slot
- Managed Identity
- Key Vault reference

### Step 1 — Create a Service Connection

The pipeline authenticates to Azure using a service connection. Create it before creating the pipeline.

1. Go to `dev.azure.com` → Your Project
2. In the bottom-left, click **Project settings**
3. Under **Pipelines**, select **Service connections**
4. Click **New service connection** → choose **Azure Resource Manager** → click **Next**
5. Select **Service principal (automatic)** → click **Next**
6. Configure:
   - **Scope level:** Subscription
   - **Subscription:** select your Azure subscription
   - **Resource group:** `rg-appservice-wus2-lab`
   - **Service connection name:** `sc-appservice-lab`
7. Check **Grant access permission to all pipelines** → click **Save**

> **Note:** Automatic service principal creation requires the **Owner** role on the subscription. If you see a permission error, ask your subscription owner to create the service connection or use the **Manual** option with an existing service principal.
> **Permissions granted:** When created automatically at resource group scope, Azure DevOps assigns the service principal the **Contributor** role on `rg-appservice-wus2-lab`. This grants the pipeline permission to deploy code and swap slots — no additional role assignment is needed.

### Step 2 — Open Azure DevOps

1. Go to `dev.azure.com` → Your Project → **Pipelines**
2. Click **New Pipeline**

### Step 3 — Initialize a Repository and Choose Your Code Source

If you do not already have a repository with application code, initialize one now:

1. In your Azure DevOps project, go to **Repos** → **Files**
2. Click **Initialize** to create the repo with a default branch (`main`)
3. Add at least a placeholder file (e.g., `index.html` or `app.py`) and commit it to `main` — the pipeline requires a non-empty repo to publish artifacts

Once your repository is ready, in the pipeline creation wizard select **Azure Repos Git** (or **GitHub** if applicable), then pick your repository.

### Step 4 — Select Starter Pipeline

When Azure DevOps displays template options, choose **Starter pipeline** to create a blank YAML file.

### Step 5 — Replace the Starter YAML

Paste the following into the editor:

```yaml
trigger:
  branches:
    include:
      - main

variables:
  appName: 'app-appservice-wus2-lab'
  resourceGroup: 'rg-appservice-wus2-lab'
  serviceConnection: 'sc-appservice-lab'

stages:

- stage: Build
  displayName: Build Application
  jobs:
  - job: BuildJob
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: echo "Build your app here"
      displayName: Build
    - task: PublishBuildArtifacts@1
      displayName: Publish Artifact
      inputs:
        PathtoPublish: '$(Build.SourcesDirectory)'
        ArtifactName: 'drop'
        publishLocation: 'Container'

- stage: Deploy_Staging
  displayName: Deploy to Staging Slot
  dependsOn: Build
  jobs:
  - deployment: DeployStaging
    environment: staging
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: drop
          - task: AzureWebApp@1
            inputs:
              azureSubscription: $(serviceConnection)
              appName: $(appName)
              deployToSlotOrASE: true
              resourceGroupName: $(resourceGroup)
              slotName: 'staging'
              package: '$(Pipeline.Workspace)/drop'

- stage: SwapToProduction
  displayName: Swap Staging → Production
  dependsOn: Deploy_Staging
  jobs:
  - job: Swap
    steps:
    - task: AzureAppServiceManage@0
      inputs:
        azureSubscription: $(serviceConnection)
        Action: 'Swap Slots'
        WebAppName: $(appName)
        ResourceGroupName: $(resourceGroup)
        SourceSlot: 'staging'
        TargetSlot: 'production'
```

### Step 6 — Save and Run

Click **Save** then **Run**. The pipeline completes the following flow:

1. Build
2. Deploy to staging slot
3. Swap staging → production

### Validate the Deployment

| Slot | URL |
| --- | --- |
| Staging | `https://app-appservice-wus2-lab-staging.azurewebsites.net` |
| Production | `https://app-appservice-wus2-lab.azurewebsites.net` |

### Step 7 — Create the `staging` Environment in Azure DevOps

The pipeline YAML references `environment: staging` in the `Deploy_Staging` stage. Azure DevOps auto-creates environments on first use, but the pipeline may pause on its first run to request authorization. Create it manually beforehand to avoid this:

1. Go to **Azure DevOps** → **Pipelines** → **Environments**
2. Click **New Environment**
3. Name it: `staging`
4. Leave **Resource** as **None**
5. Click **Create**

> **Note:** The `production` environment with its approval gate is configured separately in [section 14](#14-add-manual-approval-gates-enterprise-pattern). Do not add approval checks to the `staging` environment.

---

## 13. Test Slot Swap

Before testing, confirm all components are in place: production slot, staging slot, Azure DevOps pipeline, Key Vault reference, and Managed Identity.

### Step 1 — Make a Visible Change in the App

Create a small change that is easy to identify after deployment (e.g., change homepage text, add a version label, or add a "Deployed to Staging" message). Commit and push the change to your repo.

### Step 2 — Run the Pipeline

Go to **Azure DevOps** → **Pipelines** → **Run pipeline**.

### Step 3 — Validate the Staging Slot

Open `https://<your-app-name>-staging.azurewebsites.net`. The new version should appear here first.

### Step 4 — Validate the Production Slot

Open `https://<your-app-name>.azurewebsites.net`. After the swap stage completes, the new version should appear in production.

### Step 5 — Validate Key Vault Secret Access

Inside your app, print the environment variable:

| Runtime | Code |
| --- | --- |
| .NET | `Environment.GetEnvironmentVariable("MySecret")` |
| Node.js | `process.env.MySecret` |
| Python | `os.getenv("MySecret")` |

If the value appears correctly, Key Vault access through Managed Identity is working.

### Step 6 — Validate Rollback (Optional)

Test rollback by swapping production back to staging:

1. Go to **App Service** → **Deployment slots**
2. Click **Swap**
3. Swap production → staging

The previous version should return to production after the rollback swap completes.

---

## 14. Add Manual Approval Gates (Enterprise Pattern)

Manual approvals add a controlled checkpoint before production changes are released. With this gate, the pipeline pauses after staging deployment and waits for explicit approval before swapping to production.

### Step 1 — Create an Environment in Azure DevOps

1. Go to **Azure DevOps** → **Pipelines** → **Environments**
2. Click **New Environment**
3. Name it: `production`
4. Click **Create**

### Step 2 — Add an Approval Gate

Inside the new `production` environment:

1. Open the environment
2. Click **Approvals and checks**
3. Click **Add** → **Approvals**
4. Add yourself (or any approver)

The pipeline will now pause until the configured approver approves the production swap.

### Step 3 — Update the Pipeline YAML

Modify the `SwapToProduction` stage to use a `deployment` job with the `production` environment:

```yaml
- stage: SwapToProduction
  displayName: Swap Staging → Production
  dependsOn: Deploy_Staging
  jobs:
  - deployment: Swap
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureAppServiceManage@0
            inputs:
              azureSubscription: $(serviceConnection)
              Action: 'Swap Slots'
              WebAppName: $(appName)
              ResourceGroupName: $(resourceGroup)
              SourceSlot: 'staging'
              TargetSlot: 'production'
```

The key change is the `environment: production` assignment, which links the swap stage to the environment where the approval gate is configured.

### Step 4 — Approve the Pipeline Run

Once the pipeline is running with the updated YAML:

1. Go to **Azure DevOps** → **Pipelines** → open the active pipeline run
2. The `Swap Staging → Production` stage displays a **Waiting for review** banner
3. Click **Review** → **Approve**
4. Optionally add a comment (e.g., `Validated in staging — approved for production`)
5. Click **Approve** to confirm

The swap executes immediately after approval and the new version promotes to production.

> **Tip:** You can also **Reject** the gate if staging validation fails. The pipeline stops without touching production.

### Resulting Pipeline Flow

```text
1. Build
2. Deploy to Staging
3. WAIT for approval
4. Swap Staging → Production
```

---

## 15. Cleanup / Teardown

To avoid ongoing charges, delete the resources created in this lab:

1. Go to **Azure Portal** → **Resource Groups**
2. Select `rg-appservice-wus2-lab`
3. Click **Delete resource group**
4. Type the resource group name to confirm, then click **Delete**

This removes the App Service, App Service Plan, and all associated slots. The Key Vault (`kv-appservice-wus2-lab`) must be deleted separately if it was created for this lab.
