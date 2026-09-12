# Azure Policy Auto-Remediation Track

Last validated on: July 2026

[![Duration](https://img.shields.io/badge/Duration-1--1.5%20hours-0A66C2?style=flat-square)](#lab-sequence)
[![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-0052CC?style=flat-square)](#lab-sequence)

This track covers custom Azure Policy authoring with a DeployIfNotExists effect, managed identity-backed remediation tasks, and compliance validation — portal-only.

## Track Structure

```text
Azure Policy Auto‑Remediation/
`-- 1-azure-policy-auto-remediation.md
```

## Lab Sequence

1. [Azure Policy Auto-Remediation](1-azure-policy-auto-remediation.md) — author a custom policy, assign it with a managed identity, trigger remediation, and validate compliance state

## What it covers

- Custom policy definitions with `DeployIfNotExists` effect
- Managed identity assignment for remediation tasks
- Compliance dashboard and remediation task monitoring
- Scoped assignment and exemption patterns

## Prerequisites

- Azure subscription with **Owner** or **Contributor + Policy Contributor** role
- Azure Portal access
- A storage account in the target subscription to use as the remediation target

---

[← Back to Azure Hands-On Engineering](../README.md)
