# Compute Track

Last validated on: July 2026

This track covers VM provisioning from scratch through to a deployable web workload — base build, image preparation via Sysprep, and IIS installation for server role validation.

## Track Structure

```text
Compute/
|-- 1-build-base-vm.md
|-- 2-sysprep-vm.md
`-- 3-Install IIS.md
```

Flow: build base VM → install and validate IIS → Sysprep the image source → VMSS deployment.

## Lab Sequence

1. [Build Base VM](1-build-base-vm.md) — provision a VM with consistent naming conventions and post-deployment configuration
2. [Install IIS](3-Install%20IIS.md) — install the IIS web server role and validate the default site before image capture
3. [Sysprep the VM](2-sysprep-vm.md) — generalize the VM for image capture and reuse

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- Azure Portal access
- RDP client for post-deployment validation

## Next Track

[VMSS →](../VMSS/README.md) — capture the generalized image and deploy a Virtual Machine Scale Set

---

[← Back to Azure Hands-On Engineering](../README.md)
