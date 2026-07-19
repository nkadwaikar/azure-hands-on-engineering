# Defender for Cloud CSPM

> **Status:** In development — content coming soon.

> **Why this matters:** Cloud Security Posture Management (CSPM) gives a continuous, scored view of your security configuration across every subscription and resource type. Without it, misconfigurations go undetected until they become incidents. Defender for Cloud CSPM closes that loop — surfacing risks, mapping them to regulatory frameworks, and integrating auto-remediation so your posture improves without manual audits.

---

## Planned Coverage

This track extends the [Defender for Servers](../Defender%20for%20Servers/README.md) foundation to fleet-scale posture management across a hub-and-spoke topology.

| Topic | What it covers |
| --- | --- |
| **Secure Score** | Subscription-level score, control weighting, and score improvement workflow |
| **Recommendations** | Grouped vs. individual recommendation model; fleet-scale triage via category tabs and Azure Resource Graph |
| **Regulatory Compliance** | Mapping controls to CIS, NIST, PCI-DSS, and ISO 27001; evidence export |
| **Attack Path Analysis** | Graph-based attack path visualisation; exploitable path suppression |
| **Cloud Security Explorer** | KQL-style graph queries across resource inventory |
| **Governance Rules** | Assign owners and due dates to recommendations; track remediation SLAs |
| **Workbooks & Reporting** | Custom CSPM workbooks; compliance posture reports for stakeholders |
| **Multi-subscription scope** | Aggregate posture across a Management Group; exclude development subscriptions |

---

## Prerequisites

- [Identity-First Track](../Identity-First/README.md) — RBAC and governance foundation
- [Defender for Servers Track](../Defender%20for%20Servers/README.md) — Defender for Cloud enablement, Arc agent health, JIT
- Defender for Cloud **Foundational CSPM** (free tier) or **Defender CSPM** (paid) enabled on the target subscriptions
- **Security Reader** role at Management Group scope for read-only posture review; **Security Admin** to apply governance rules

---

## Track Structure *(planned)*

```text
Defender for Cloud CSPM/
├── README.md                        ← Track entry point (this file)
├── 1-cspm-secure-score.md           ← Secure Score, controls, and improvement workflow
├── 2-recommendations-triage.md      ← Fleet-scale recommendation triage; ARG queries
├── 3-regulatory-compliance.md       ← Compliance dashboard; framework mapping; export
├── 4-attack-path-analysis.md        ← Attack path graph; exploitable path review
└── 5-governance-rules.md            ← Owner assignment; SLA tracking; reporting
```

---

## Connection to Other Tracks

| Track | Relationship |
| --- | --- |
| [Defender for Servers](../Defender%20for%20Servers/README.md) | CSPM builds on the Defender for Cloud enablement and Arc agent health work done there |
| [Azure Policy Auto-Remediation](../Azure%20Policy%20Auto%E2%80%91Remediation/README.md) | Governance Rules complement Policy-driven auto-remediation — CSPM flags, Policy fixes |
| [Identity-First](../Identity-First/README.md) | Security Reader / Security Admin roles; RBAC scopes for posture data access |
| [Azure Arc](../Azure%20Arc%20Hybrid%20Server%20Architecture/README.md) | Arc-enabled servers surface in CSPM recommendations alongside Azure VMs |

---

← [Back to root README](../README.md)
