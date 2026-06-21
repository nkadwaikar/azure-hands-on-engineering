# VMSS Image Validation Track

## Capture the Image + Deploy Test VM

## Track Structure

```text
VMSS/
|-- 1-capture-and-test-image.md
`-- 2-vmss-deployment.md
```

Flow: capture reusable image -> validate with a test VM -> deploy scale set from known-good image.

## Quick Navigation

- Track Structure
- Capture the Image
- Deploy a Test VM from the Image
- Validate the Test VM
- Validate IIS
- Continue to VMSS Deployment

This document covers capturing the custom image and validating it before using it in VMSS.

---

## 1. Capture the Image


**Portal Navigation:**
1. In the [Azure Portal](https://portal.azure.com), search for **Virtual Machines** in the top search bar.
2. Select your prepared VM from the list.
3. In the VM blade, click **Capture** from the top menu.
4. Configure:

   - **Shared Image Gallery** → ✔ Recommended  
   - Create Image Definition (if needed)  
   - Create Image Version → e.g., `1.0.0`  

5. (Optional, recommended):
   **✔ Automatically delete this VM after creating the image**

⏱ Capture time: **10–25 minutes**

---

## 2. Deploy a Test VM from the Captured Image


**Portal Navigation:**
1. In the [Azure Portal](https://portal.azure.com), search for **Shared Image Gallery**.
2. Select your gallery, then your **Image Definition**.
3. Click on the desired **Image Version** (e.g., `1.0.0`).
4. Click **+ Create VM** to deploy a test VM from this image.

---

## 3. Validate the Test VM

### Expected behavior:

| Behavior | Meaning |
|---------|---------|
| ✔ Windows login screen | Image is healthy |
| ❌ “Hi there” OOBE | Wrong capture process |
| ❌ “Specializing…” | Sysprep failed |
| ❌ Black screen | RDP disabled / firewall issue |

---

## 4. Validate IIS

Inside the test VM:

- Open browser → `http://localhost`  
- Confirm your custom Hello World page loads  

If IIS works → your custom image is **ready for VMSS**.

---

## Image is ready for VMSS deployment

Next step:  
➡ [VMSS Deployment Guide](2-vmss-deployment.md)
