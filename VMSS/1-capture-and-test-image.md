# VMSS Image Validation Track

> **Why this matters:** Deploying a scale set from an unvalidated image means every instance could fail silently on boot — this lab captures the Sysprepped VM as a gallery version and boots a test VM from it to confirm IIS responds before the image is locked.

Last validated on: 2026-06-19
Portal experience note: Steps validated against Azure Portal as of June 2026.

> **Note:** Image capture takes 10–25 minutes. If you select "Automatically delete this VM after creating the image," the source VM is permanently deleted — confirm you no longer need it before proceeding.

---

## Module / Track Structure

```text
VMSS/
├── README.md                          ← Track entry point
├── 1-capture-and-test-image.md        ← Lab 1: Image Capture + Validation (you are here)
└── 2-vmss-deployment.md               ← Lab 2: Scale Set Deployment
```

---

## Quick Navigation

- [Capture the Image](#1-capture-the-image)
- [Deploy a Test VM](#2-deploy-a-test-vm-from-the-captured-image)
- [Validate the Test VM](#3-validate-the-test-vm)
- [Validate IIS](#4-validate-iis)

This document covers capturing the custom image and validating it before using it in VMSS.

---

## Learning Objectives

By the end of this lab, you will have:

- A **Shared Image Gallery version** created from the Sysprepped VM
- A **test VM** deployed from that gallery version to verify the image boots correctly
- **IIS confirmed** as responding on the test VM before the image is used in a scale set
- The source VM deleted (or retained), with the gallery version as the durable artifact

---

## Scenario

**Validate the captured image boots and serves traffic before committing it to scale.**

An image version that looks correct in the gallery can still fail at boot if Sysprep was incomplete or the guest agent wasn't clean. This lab captures the image, boots a test VM from the gallery version, and confirms IIS responds — so any image defect is caught now, not when 10 instances in a scale set all fail simultaneously.

---

## 1. Capture the Image

1. In Azure Portal, search for **Virtual Machines**.
2. Select your prepared VM.
3. In the VM blade, click **Capture** from the top menu.
4. Configure:

   - **Shared Image Gallery** → Recommended
   - Create Image Definition (if needed)
   - Create Image Version → e.g., `1.0.0`

5. (Optional, recommended): Check **Automatically delete this VM after creating the image**.

> **Expected state:** Gallery image version status shows **Succeeded** after 10–25 minutes.

---

## 2. Deploy a Test VM from the Captured Image

1. In Azure Portal, search for **Shared Image Gallery**.
2. Select your gallery, then your **Image Definition**.
3. Click on the desired **Image Version** (e.g., `1.0.0`).
4. Click **+ Create VM** to deploy a test VM from this image.

---

## 3. Validate the Test VM

### Expected behavior

| Behavior | Meaning |
| --------- | --------- |
| ✔ Windows login screen | Image is healthy |
| “Hi there” OOBE | Wrong capture process |
| “Specializing…” | Sysprep failed |
| Black screen | RDP disabled / firewall issue |

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
