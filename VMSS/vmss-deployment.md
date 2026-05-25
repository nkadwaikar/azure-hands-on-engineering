# 🚀 VMSS Deployment Using a Custom Windows Image

This document covers the **end‑to‑end deployment** of an Azure **Virtual Machine Scale Set (VMSS)** using a **custom Windows Server image** stored in a **Shared Image Gallery**.

Your custom image already includes:

- IIS  
- A custom “Hello World” webpage  
- All prep steps (Sysprep, cleanup, validation)

This guide focuses **only on VMSS deployment, scaling, validation, and cleanup**.

---

# 🏗️ **1. Prerequisites**

Before starting this VMSS deployment, ensure you have completed:

| Step | File |
|------|------|
| Build Base VM (IIS + custom page) | `1-build-base-vm.md` |
| Sysprep the VM | `2-sysprep-vm.md` |
| Capture & Test the Image | `3-capture-and-test-image.md` |

Your Shared Image Gallery should now contain a **validated image version** (e.g., `1.0.0`).

---

# 📘 **2. Create the Resource Group**

Create a dedicated resource group for the VMSS lab:

```
rg-vmss-lab
```

This keeps all VMSS resources isolated and easy to delete later.

---

# 📘 **3. Deploy the VM Scale Set (VMSS)**

In the Azure Portal:

### **Basics**
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

# 📘 **4. Validate VMSS Deployment**

After deployment completes:

### ✔ Check VMSS Instances
Navigate to:

**VMSS → Instances**

You should see:

- **2 running instances**
- Both in **Succeeded** state

### ✔ Check Load Balancer
Navigate to:

**Load Balancer → Backend Pools**

You should see:

- Both VMSS instances registered  
- Health probe status: **Healthy**

---

# 📘 **5. Validate IIS Through Load Balancer**

1. Go to the **Load Balancer**  
2. Copy the **Public IP**  
3. Open in browser:

```
http://<Public-IP>
```

You should see your **custom Hello World IIS page**.

This confirms:

- VMSS deployed correctly  
- Custom image works  
- Load Balancer routing is functional  

---

# 📘 **6. Test VMSS Scaling**

This is the most important part of the lab — proving that your custom image works **across scaling events**.

---

## 🔹 **Scale Out (2 → 4 instances)**

1. Go to:

**VMSS → Instances → Capacity**

2. Change instance count from:

```
2 → 4
```

3. Azure will create **2 new instances**

### Validate:

- All **4 instances** appear  
- All show **Succeeded**  
- Load Balancer backend pool shows **4 healthy nodes**  
- IIS page loads successfully via Public IP  

---

## 🔹 **Scale In (4 → 2 instances)**

1. Change instance count from:

```
4 → 2
```

2. Azure will delete **2 instances**

### Validate:

- Only **2 instances** remain  
- Load Balancer backend pool shows **2 healthy nodes**  
- IIS still loads via Public IP  

---

# 📘 **7. Final Validation Checklist**

| Validation | Status |
|-----------|--------|
| VMSS deployed using custom image | ✔ |
| Load Balancer configured | ✔ |
| IIS accessible via Public IP | ✔ |
| Scale Out (2 → 4) successful | ✔ |
| Scale In (4 → 2) successful | ✔ |
| IIS works after scaling | ✔ |

This confirms your custom image is **VMSS‑ready and production‑aligned**.

---

# 🧹 **8. Cleanup**

Delete the resource group:

```
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