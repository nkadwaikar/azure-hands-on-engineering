# Compute Track

This track covers VM provisioning from scratch through to a deployable web workload — base build, image preparation via Sysprep, and IIS installation for server role validation.

## Track Structure

```text
Compute/
|-- 1-build-base-vm.md
|-- 2-sysprep-vm.md
`-- 3-Install IIS.md
```

Flow: build base VM → Sysprep the image source → install and validate IIS.

## Lab Sequence

1. [Build Base VM](1-build-base-vm.md) — provision a VM with consistent naming conventions and post-deployment configuration
2. [Sysprep the VM](2-sysprep-vm.md) — generalise the VM for image capture and reuse
3. [Install IIS](3-Install%20IIS.md) — install the IIS web server role and validate the default site

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- Azure Portal access
- RDP client for post-deployment validation

---

[← Back to Azure Hands-On Engineering](../README.md)
