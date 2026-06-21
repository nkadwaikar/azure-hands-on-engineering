# 🚀 VMSS Deployment Using a Custom Windows Image

This document covers the **end‑to‑end deployment** of an Azure **Virtual Machine Scale Set (VMSS)** using a **custom Windows Server image** stored in a **Shared Image Gallery**.

Your custom image already includes:

- IIS  
- A custom “Hello World” webpage  
- All prep steps (Sysprep, cleanup, validation)

This guide focuses **only on VMSS deployment, scaling, validation, and cleanup**.

---

## 🏗️ **1. Prerequisites**

Before starting this VMSS deployment, ensure you have completed:

| Step | File |
| --- | --- |
| Build Base VM | [../Compute/1-build-base-vm.md](../Compute/1-build-base-vm.md) |
| Install IIS + custom page | [../Compute/2-install-iis.md](../Compute/2-install-iis.md) |
| Sysprep the VM | [../Compute/3-sysprep-vm.md](../Compute/3-sysprep-vm.md) |
| Capture & Test the Image | [1-capture-and-test-image.md](1-capture-and-test-image.md) |

Your Shared Image Gallery should now contain a **validated image version** (e.g., `1.0.0`).

---

## 📘 **2. Create the Resource Group**

**Portal Navigation:**

1. In the [Azure Portal](https://portal.azure.com), search for **Resource groups** in the top search bar.
2. Click **+ Create**.
3. Enter the following name:

```text
rg-vmss-lab
```

1. Select your subscription and region, then click **Review + Create** → **Create**.

This keeps all VMSS resources isolated and easy to delete later.

---

## 📘 **3. Deploy the VM Scale Set (VMSS)**

**Portal Navigation:**

1. In the [Azure Portal](https://portal.azure.com), search for **Virtual Machine Scale Sets** in the top search bar.
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

## 📘 **4. Validate VMSS Deployment**

**Portal Navigation:**

1. In the [Azure Portal](https://portal.azure.com), go to **Virtual Machine Scale Sets** and select your VMSS.
2. Use the left menu to navigate to **Instances** to check running VMs.
3. In the same VMSS blade, find **Load Balancer** under **Networking** or search for **Load Balancers** and select the one linked to your VMSS.
4. Use **Backend Pools** and **Health Probes** to validate instance registration and health.

### ✔ Check VMSS Instances

You should see:

- **2 running instances**
- Both in **Succeeded** state

### ✔ Check Load Balancer

You should see:

- Both VMSS instances registered  
- Health probe status: **Healthy**

---

## 📘 **5. Validate IIS Through Load Balancer**

**Portal Navigation:**

1. In the [Azure Portal](https://portal.azure.com), search for **Load Balancers** and select the one created for your VMSS.
2. On the overview page, copy the **Public IP address**.
3. Open in your browser:

```url
http://<Public-IP>
```

You should see your **custom Hello World IIS page**.

This confirms:

- VMSS deployed correctly  
- Custom image works  
- Load Balancer routing is functional  

---

## 📘 **6. Test VMSS Scaling**

This is the most important part of the lab — proving that your custom image works **across scaling events**.

## 🔹 **Scale Out (2 → 4 instances)**

**Portal Navigation:**

1. In the [Azure Portal](https://portal.azure.com), go to **Virtual Machine Scale Sets** and select your VMSS.
2. In the left menu, click **Instances**.
3. At the top, click **Scale** or **Capacity**.
4. Change instance count from: 2 → 4
5. Click **Save**.

Azure will create **2 new instances**.

### Validate Scale Out

- All **4 instances** appear  
- All show **Succeeded**  
- Load Balancer backend pool shows **4 healthy nodes**  
- IIS page loads successfully via Public IP  

## 🔹 **Scale In (4 → 2 instances)**

**Portal Navigation:**

1. In the [Azure Portal](https://portal.azure.com), go to your VMSS, click **Instances**, then **Scale/Capacity** at the top.
2. Change instance count from: 4 → 2
3. Click **Save**.
4. Azure will delete **2 instances**

### Validate

- Only **2 instances** remain  
- Load Balancer backend pool shows **2 healthy nodes**  
- IIS still loads via Public IP  

---

## 📘 **7. Final Validation Checklist**

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

## 🧹 **8. Cleanup**

Delete the resource group:

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

You have successfully:

✔ Deployed a VM Scale Set using a custom image  
✔ Validated IIS across all instances  
✔ Performed scale‑out and scale‑in  
✔ Verified load balancing  
✔ Built a real‑world, production‑aligned Azure workload  
