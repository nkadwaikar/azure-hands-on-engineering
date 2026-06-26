# VMSS Deployment Using a Custom Windows Image

> **Why this matters:** Scaling virtual machines manually means downtime, human error, and over-provisioned costs during variable load — this lab deploys a scale set from a validated golden image so Azure can add or remove identical instances automatically against a load balancer.

This document covers the **end‑to‑end deployment** of an Azure **Virtual Machine Scale Set (VMSS)** using a **custom Windows Server image** stored in a **Shared Image Gallery**.

Your custom image already includes:

- IIS  
- A custom “Hello World” webpage  
- All prep steps (Sysprep, cleanup, validation)

This guide focuses **only on VMSS deployment, scaling, validation, and cleanup**.

Last validated on: 2026-06-19  
Portal experience note: Steps validated against Azure Portal as of June 2026.

> **Note:** VMSS deployment requires a validated image version in an Azure Compute Gallery. Complete [Capture and Test Image](1-capture-and-test-image.md) first.

---

## Track Structure

```text
VMSS/
|-- 1-capture-and-test-image.md
`-- 2-vmss-deployment.md
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Create Resource Group](#2-create-the-resource-group)
- [Deploy VMSS](#3-deploy-the-vm-scale-set-vmss)
- [Validate VMSS Deployment](#4-validate-vmss-deployment)
- [Validate IIS](#5-validate-iis-through-load-balancer)
- [Test Scaling](#6-test-vmss-scaling)
- [Final Validation Checklist](#7-final-validation-checklist)
- [Cleanup](#8-cleanup)

---

## Learning Objectives

By the end of this lab, you will have:

- A **VM Scale Set** deployed from a validated gallery image behind an Azure Load Balancer
- **IIS responding** via the Load Balancer public IP across all instances
- **Scale-out** (2 → 4 instances) and **scale-in** (4 → 2 instances) performed and validated
- An understanding of how custom images enable consistent horizontal scale

---

## Scenario

**Prove that your custom image scales horizontally before a real traffic event, not during one.**

A golden image only delivers value when new instances boot correctly and serve traffic without manual configuration. This lab deploys two instances from your gallery image, confirms IIS serves the custom page through a load balancer, then scales out and back in to validate that every instance — at any scale count — behaves identically.

---

## 1. Prerequisites

Before starting this VMSS deployment, ensure you have completed:

| Step | File |
| --- | --- |
| Build Base VM (IIS + custom page) | [../Compute/1-build-base-vm.md](../Compute/1-build-base-vm.md) |
| Sysprep the VM | [../Compute/2-sysprep-vm.md](../Compute/2-sysprep-vm.md) |
| Capture & Test the Image | [1-capture-and-test-image.md](1-capture-and-test-image.md) |

Your Shared Image Gallery should now contain a **validated image version** (e.g., `1.0.0`).

---

## 2. Create the Resource Group

1. In the [Azure Portal](https://portal.azure.com), search for **Resource groups**.
2. Click **+ Create**.
3. Enter the following name:

```text
rg-vmss-lab
```

1. Select your subscription and region, then click **Review + Create** → **Create**.

This keeps all VMSS resources isolated and easy to delete later.

---

## 3. Deploy the VM Scale Set (VMSS)

1. In the [Azure Portal](https://portal.azure.com), search for **Virtual Machine Scale Sets**.
2. Click **+ Create** and select **Virtual Machine Scale Set**.
3. Fill in the following details:

### **Basics**

- **Create a Virtual Machine Scale Set (VMSS)**
- **Image** → Shared Image Gallery → Your Image Version  
- **Authentication** → Password or SSH  
- **Instance Count** → **2**  
- **Region** → Same region as your image  
- **VM Size** → `Standard_B2s` (recommended for labs)

### **Networking**

- **Virtual Network** → Create new or use existing  
- **Public IP** → **Enabled**  
- **Load Balancer** → **Enabled**  
- **Inbound Rules** → Allow:
  - **HTTP (80)**
  - **HTTPS (443)**

### **Scaling**

- Manual scaling is fine for this lab  
- Autoscale rules can be added later

### **Management**

- Boot diagnostics → Optional  
- Monitoring → Optional  

Click **Review + Create** → **Create**

---

## 4. Validate VMSS Deployment

1. In the [Azure Portal](https://portal.azure.com), go to **Virtual Machine Scale Sets** and select your VMSS.
2. Navigate to **Instances** to check running VMs.
3. Find the linked **Load Balancer** under **Networking** and verify backend pool health.

### Check VMSS instances

You should see:

- **2 running instances**
- Both in **Succeeded** state

### Check Load Balancer

You should see:

- Both VMSS instances registered  
- Health probe status: **Healthy**

---

## 5. Validate IIS Through Load Balancer

1. In the [Azure Portal](https://portal.azure.com), search for **Load Balancers** and select the one created for your VMSS.
2. Copy the **Public IP address** from the overview page.
3. Open a browser and navigate to:

```url
http://<Public-IP>
```

You should see your **custom Hello World IIS page**.

This confirms:

- VMSS deployed correctly  
- Custom image works  
- Load Balancer routing is functional  

---

## 6. Test VMSS Scaling

This is the most important part of the lab — proving that your custom image works across scaling events.

### Step 1 — Scale Out (2 → 4 instances)

1. In the [Azure Portal](https://portal.azure.com), go to **Virtual Machine Scale Sets** and select your VMSS.
2. In the left menu, click **Instances**.
3. Click **Scale** or **Capacity**.
4. Change instance count from 2 to 4.
5. Click **Save**.

> **Expected state:** All 4 instances show **Succeeded**; Load Balancer backend pool shows 4 healthy nodes; IIS page loads via Public IP.

### Step 2 — Scale In (4 → 2 instances)

1. Go to your VMSS, click **Instances**, then **Scale/Capacity**.
2. Change instance count from 4 to 2.
3. Click **Save**.

> **Expected state:** 2 instances remain; Load Balancer backend pool shows 2 healthy nodes; IIS still loads via Public IP.

---

## 7. Final Validation Checklist

| Validation | Status |
| --- | --- |
| VMSS deployed using custom image | ✔ |
| Load Balancer configured | ✔ |
| IIS accessible via Public IP | ✔ |
| Scale Out (2 → 4) successful | ✔ |
| Scale In (4 → 2) successful | ✔ |
| IIS works after scaling | ✔ |

This confirms your custom image is **VMSS‑ready and production‑aligned**.

---

## 8. Cleanup

Delete the resource group to remove all VMSS resources:

```text
rg-vmss-lab
```

This removes:

- VMSS  
- Load Balancer  
- Public IP  
- VNet  
- NICs  
- Disks  
- Supporting resources  

---

[← Back to Azure Hands-On Engineering](../README.md)
