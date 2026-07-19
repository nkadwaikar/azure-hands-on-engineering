# Copilot for Security

> **Status:** In development — content coming soon.

> **Why this matters:** Security operations teams are overwhelmed by alert volume. Microsoft Security Copilot integrates natural language directly into the investigation and response workflow — summarising incidents, correlating signals across Sentinel, Defender XDR, and Entra ID, and suggesting remediation steps in seconds rather than minutes. The result is faster triage, less analyst fatigue, and decisions grounded in your actual environment context rather than generic playbooks.

---

## Planned Coverage

This track integrates Microsoft Security Copilot into the incident response and identity investigation workflow established across the Defender for Servers and Identity-First tracks.

| Topic | What it covers |
| --- | --- |
| **Incident Summarisation** | Natural-language summaries of Defender XDR and Sentinel incidents |
| **Identity Investigation** | Entra ID sign-in analysis, risky user triage, and Conditional Access gap identification |
| **KQL Assistance** | Copilot-generated KQL queries for Log Analytics and Sentinel investigation |
| **Guided Response** | Step-by-step remediation guidance inline with alert context |
| **Promptbooks** | Custom prompt sequences for repeatable SOC workflows (e.g., phishing triage, privilege escalation review) |
| **Plugin Integration** | Connecting Copilot for Security to Microsoft Defender, Sentinel, Intune, and Purview |
| **RBAC & Access Control** | Copilot for Security role assignments; data residency and access boundaries |

---

## Prerequisites

- [Identity-First Track](../Identity-First/README.md) — Entra ID RBAC and access governance
- [Defender for Servers Track](../Defender%20for%20Servers/README.md) — Defender for Cloud and security alert context
- Microsoft Security Copilot capacity provisioned (Security Compute Units)
- **Security Copilot Owner** or **Security Copilot Contributor** role in the Copilot for Security portal

---

## Track Structure *(planned)*

```text
Copilot for Security/
├── README.md                           ← Track entry point (this file)
├── 1-setup-and-access-control.md       ← Provisioning SCUs; RBAC; data residency
├── 2-incident-investigation.md         ← Incident summarisation; guided response
├── 3-identity-investigation.md         ← Entra ID sign-in analysis; risky user triage
├── 4-kql-assistance.md                 ← KQL generation; Sentinel integration
└── 5-promptbooks.md                    ← Custom promptbooks for repeatable SOC workflows
```

---

## Connection to Other Tracks

| Track | Relationship |
| --- | --- |
| [Defender for Servers](../Defender%20for%20Servers/README.md) | Security alerts and Secure Score provide the investigation context Copilot reasons over |
| [Defender for Cloud CSPM](../Defender%20for%20Cloud%20CSPM/README.md) | CSPM recommendations and attack paths are surfaceable via Copilot queries |
| [Identity-First](../Identity-First/README.md) | Entra ID sign-in risk, Conditional Access, and RBAC are core Copilot investigation surfaces |
| [Microsoft 365](../Microsoft%20365/README.md) | Purview Insider Risk and DLP alerts feed into the Copilot for Security investigation scope |

---

← [Back to root README](../README.md)
