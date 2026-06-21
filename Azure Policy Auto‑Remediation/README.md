# Azure Policy Auto-Remediation Track

This track covers custom Azure Policy authoring with a DeployIfNotExists effect, managed identity-backed remediation tasks, and compliance validation — portal-only.

## Track Structure

```text
Azure Policy Auto‑Remediation/
`-- 1-Azure Policy Auto‑Remediation.md
```

## Lab Sequence

1. [Azure Policy Auto-Remediation](1-Azure%20Policy%20Auto%E2%80%91Remediation.md) — author a custom policy, assign it with a managed identity, trigger remediation, and validate compliance state

## What it covers

- Custom policy definitions with `DeployIfNotExists` effect
- Managed identity assignment for remediation tasks
- Compliance dashboard and remediation task monitoring
- Scoped assignment and exemption patterns

## Prerequisites

- Azure subscription with **Owner** or **Contributor + Policy Contributor** role
- Azure Portal access
- A storage account in the target subscription to use as the remediation target
