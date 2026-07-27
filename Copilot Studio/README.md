# Copilot Studio

Last validated on: July 2026

> **Why this matters:** Copilot Studio closes the last mile between organisational knowledge and the people who need it. By grounding an AI agent in a SharePoint knowledge source and securing it with Entra ID, you get a governed, auditable assistant that answers questions from your actual documentation — not a generic model. This track shows how to build that pattern correctly: Zero Trust at the identity layer, Purview at the data layer, and DLP policies preventing data exfiltration through the agent surface.

---

## Coverage

This track covers building a governed AI agent in Microsoft Copilot Studio backed by a SharePoint knowledge source, secured with Entra ID authentication, and governed with Purview DLP.

| Topic | What it covers |
| --- | --- |
| **Agent Creation** | Copilot Studio agent setup; knowledge source configuration (SharePoint) |
| **Entra ID Authentication** | Securing the agent with Entra ID; user authentication flow; app registration |
| **SharePoint Knowledge Source** | Scoping the agent to specific SharePoint sites and libraries; content indexing |
| **DLP & Governance** | Applying Purview DLP policies to prevent data exfiltration via agent responses |
| **Conditional Access** | Enforcing authentication strength and device compliance for agent access |
| **Publishing & Channels** | Publishing to Microsoft Teams; channel-scoped access controls |
| **Monitoring & Audit** | Conversation logging; audit trails; Purview activity explorer integration |

---

## Prerequisites

- [Identity-First Track](../Identity-First/README.md) — Entra ID app registrations, RBAC, and Conditional Access
- [Microsoft 365 Track](../Microsoft%20365/README.md) — SharePoint architecture, Purview DLP, and governance foundations
- Microsoft Copilot Studio licence (or Power Platform trial)
- **Environment Maker** role in Power Platform; **SharePoint Site Member** on the target knowledge source
- Purview DLP policy scope configured to cover Copilot Studio interactions

---

## Track Structure

```text
Copilot Studio/
├── README.md                          ← Track entry point (this file)
└── 1-copilot-studio-agent.md          ← Lab 1: Build, secure, and govern a SharePoint-grounded AI agent
```

## Lab Sequence

1. [Microsoft Copilot Studio — Governed AI Agent on a Zero Trust Foundation](./1-copilot-studio-agent.md) — create an agent, ground it on a SharePoint knowledge source, configure Entra ID authentication, apply Power Platform DLP, publish to Teams, and monitor via analytics and Purview Audit

---

## Connection to Other Tracks

| Track | Relationship |
| --- | --- |
| [Identity-First](../Identity-First/README.md) | Entra ID app registration and Conditional Access secure the agent surface |
| [Microsoft 365](../Microsoft%20365/README.md) | SharePoint knowledge source, Purview DLP, and Teams publishing channel |
| [Copilot for Security](../Copilot%20for%20Security/README.md) | Parallel track — Copilot Studio covers productivity AI; Copilot for Security covers SOC AI |

---

← [Back to root README](../README.md)
