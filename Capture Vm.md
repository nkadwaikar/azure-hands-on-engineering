Capture the image
Make Sure BaseImage (VM) is Stopped (deallocated):
1. Go to the VM in Azure Portal
2. Click Capture
3. Choose:
	◦ Shared Image Gallery (recommended)
	◦ Create Image Definition (if needed)
	◦ Create Image Version (e.g., 1.0.0)
4. Check the box:
	◦ Automatically delete this VM after creating the image (optional but recommended)
Let the capture run — 10–25 minutes is normal.

---
After capture completes
Deploy a test VM from the image.
If the test VM shows:
✔ Windows login screen → Image is perfect
❌ “Hi there” OOBE → You captured incorrectly
❌ “Specializing…” → Sysprep failed
❌ Black screen → RDP not enabled