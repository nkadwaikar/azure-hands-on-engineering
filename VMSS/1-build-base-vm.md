# ✅ **FILE 3 — `3-capture-and-test-image.md`**
## 📸 Capture the Image + Deploy Test VM

This document covers capturing the custom image and validating it before using it in VMSS.

---

# 📘 **1. Capture the Image**

1. Open the VM in Azure Portal  
2. Select **Capture**  
3. Configure:

   - **Shared Image Gallery** → ✔ Recommended  
   - Create Image Definition (if needed)  
   - Create Image Version → e.g., `1.0.0`  

4. Optional (recommended):  
   **✔ Automatically delete this VM after creating the image**

⏱ Capture time: **10–25 minutes**

---

# 📘 **2. Deploy a Test VM from the Captured Image**

After the image is created:

- Go to **Shared Image Gallery**  
- Select your **Image Definition**  
- Choose the **Image Version**  
- Deploy a **Test VM**

---

# 📘 **3. Validate the Test VM**

### Expected behavior:

| Behavior | Meaning |
|---------|---------|
| ✔ Windows login screen | Image is healthy |
| ❌ “Hi there” OOBE | Wrong capture process |
| ❌ “Specializing…” | Sysprep failed |
| ❌ Black screen | RDP disabled / firewall issue |

---

# 📘 **4. Validate IIS**

Inside the test VM:

- Open browser → `http://localhost`  
- Confirm your custom Hello World page loads  

If IIS works → your custom image is **ready for VMSS**.

---

# 🎉 Image is ready for VMSS deployment

Next step:  
➡ Deploy VMSS using this image

---

# ⭐ Optional: Add an Index File

You can also add a simple `README.md` in the folder:

```
1-custom-image/README.md
```

```markdown
# Custom Windows Image for Azure VMSS

This folder contains the full workflow for creating a reusable Windows Server image:

1. **Build Base VM** → `1-build-base-vm.md`  
2. **Sysprep VM** → `2-sysprep-vm.md`  
3. **Capture & Test Image** → `3-capture-and-test-image.md`  

This image is later used to deploy a VM Scale Set (VMSS).
```

---

If you want, I can now generate:

🔥 A **VMSS Deployment** folder with separate MD files  
🔥 A **diagram** for this entire workflow  
🔥 A **root README.md** for your GitHub portfolio  
🔥 A **navigation index** for all labs  

Just tell me what you want next.