
# Azure Hands‑On Engineering  

## Identity‑First Architecture • Governance • Automation • Resilience

Kia ora — I’m **Nadeem Kadwaikar**, a Senior Cloud & Identity Engineer focused on building secure, well‑governed, and resilient Azure platforms.

This repository is a collection of **hands‑on labs, architecture patterns, and implementation guides** that reflect how modern Azure environments are designed and operated. Everything here is practical, deployable, and aligned with real‑world engineering work.

Start here: [Architecture Overview](Architecture%20Overview.md)

---

## What You’ll Find Here

- [Identity‑first architecture and access governance](Identity-First/README.md)  
- [VM image lifecycle and scale‑set engineering](Compute/1-build-base-vm.md)  
- [Global delivery with Azure Front Door](Azure%20Front%20Door-Static%20Website%20Hosting/Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md)  
- [Policy‑driven governance and auto‑remediation](Azure%20Policy%20Auto%E2%80%91Remediation/1-Azure%20Policy%20Auto%E2%80%91Remediation.md)  
- [Backup, restore, and disaster recovery patterns](Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md)  
- [Microsoft Entra backup and recovery](Microsoft%20Entra%20Backup%20%26%20Recovery/1-Microsoft%20Entra%20Backup%20%26%20Recovery.md)  
- [Emergency access and break‑glass design](Secure%20Break%E2%80%91Glass%20Accounts/1-Secure%20Break%E2%80%91Glass%20Accounts.md)  

These labs are built to help engineers understand *how* and *why* Azure platforms are structured the way they are — with identity, governance, and resilience at the centre.

---

## Quick Start

If you want a fast overview:

1. [**Identity Fundamentals**](Identity-First/01-identity%20fundamentals.md)  
2. [**Managed Identity + Key Vault (Secretless Authentication)**](Identity-First/02-managed%20Identity%20%2B%20Azure%20Key%20Vault%20%28Secretless%20Authentication%29.md)  
3. [**Azure Front Door + Static Hosting**](Azure%20Front%20Door-Static%20Website%20Hosting/Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md)  
4. [**Azure Policy Auto‑Remediation**](Azure%20Policy%20Auto%E2%80%91Remediation/1-Azure%20Policy%20Auto%E2%80%91Remediation.md)  

A 30‑minute path that covers the core concepts used across the repo.

---

## Naming Convention

Labs in this repository follow a simple, predictable pattern:

- `1-<topic>.md`, `2-<topic>.md`, `3-<topic>.md` for ordered walkthroughs
- Folder names map to the Azure domain (for example, `Compute`, `VMSS`, and `Identity-First`)
- Keep new filenames short, lowercase where practical, and aligned to the existing sequence

Use this convention when adding new labs so navigation and cross-references remain consistent.

Reference examples:

- [Compute](Compute/1-build-base-vm.md)
- [VMSS](VMSS/1-capture-and-test-image.md)
- [Identity-First](Identity-First/01-identity%20fundamentals.md)

---

## Why I Built This

To provide clear, repeatable, engineering‑led guidance for:

- Cloud engineers building secure Azure foundations  
- Platform teams standardising identity and governance  
- Organisations adopting Zero Trust and automation‑first practices  

The goal is simple: **make Azure easier to build, operate, and recover**.

---

## Current Work

- App Services with managed identity + deployment slots  
- Defender for Cloud CSPM in hub‑and‑spoke  
- Azure Arc hybrid server management  

---

## Get in Touch

[LinkedIn](https://linkedin.com/in/nadeemkadwaikar) • <nadeemkadwaikar@outlook.com>
