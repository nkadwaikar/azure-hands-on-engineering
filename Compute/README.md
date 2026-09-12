# Compute Track

Last validated on: August 2026

[![Duration](https://img.shields.io/badge/Duration-2.5--4%20hours-0A66C2?style=flat-square)](#lab-sequence)
[![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-0052CC?style=flat-square)](#lab-sequence)

This track covers VM provisioning from scratch through to a deployable web workload and local admin credential management — base build, image preparation via Sysprep, IIS installation for server role validation, and Windows LAPS deployment for automated local administrator password rotation.

## Track Structure

```text
Compute/
├── 1-build-base-vm.md
├── 3-install-iis.md
├── 2-sysprep-vm.md
├── 4-windows-laps-deployment-guide.md
└── 5-windows-laps-risks-and-legacy-migration.md
```

Flow: build base VM → install and validate IIS → Sysprep the image source → VMSS deployment → Windows LAPS for local admin password management.

## Lab Sequence

1. [Build Base VM](1-build-base-vm.md) — provision a VM with consistent naming conventions and post-deployment configuration
2. [Install IIS](3-install-iis.md) — install the IIS web server role and validate the default site before image capture
3. [Sysprep the VM](2-sysprep-vm.md) — generalize the VM for image capture and reuse
4. [Windows LAPS Deployment](4-windows-laps-deployment-guide.md) — deploy native Windows LAPS via Group Policy for automated local admin password rotation (Hybrid AD + Azure Arc, no Intune)
5. [LAPS Risks & Legacy Migration](5-windows-laps-risks-and-legacy-migration.md) — production risk notes and legacy LAPS migration steps for environments with the prior CSE-based client installed

## Prerequisites

- Azure subscription with Contributor rights on the target resource group
- Azure Portal access
- RDP client for post-deployment validation

## Next Track

[VMSS →](../VMSS/README.md) — capture the generalized image and deploy a Virtual Machine Scale Set

---

[← Back to Azure Hands-On Engineering](../README.md)
