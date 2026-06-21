# VMSS Track

This track covers the full VM scale set lifecycle — capturing a generalised image from a prepared VM, validating it with a test deployment, and deploying a scale set from the known-good image.

## Track Structure

```text
VMSS/
|-- 1-capture-and-test-image.md
`-- 2-vmss-deployment.md
```

Flow: capture reusable image → validate with a test VM → deploy scale set.

## Lab Sequence

1. [Capture and Test Image](1-capture-and-test-image.md) — capture a custom image from a Sysprepped VM and validate it with a test deployment
2. [VMSS Deployment](2-vmss-deployment.md) — deploy a Virtual Machine Scale Set from the validated image

## Prerequisites

- Completed [Compute track](../Compute/README.md) — base VM built and Sysprepped
- Azure Compute Gallery created or access to create one
- Azure subscription with Contributor rights on the target resource group
