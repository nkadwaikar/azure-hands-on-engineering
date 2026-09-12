# Microsoft Defender for Identity — Onboarding, Health Validation, and Detection Workflow

> **Why this matters:** Identity is the blast radius multiplier in most breaches. Defender for Identity helps detect domain reconnaissance, credential abuse, and privilege escalation directly against AD DS signals, so you can contain attacks before they become tenant-wide incidents.

Last validated on: 2026-09-12
Portal experience note: Defender for Identity configuration and detections are surfaced in the Microsoft Defender portal (Defender XDR). Navigation labels may vary slightly by tenant rollout.

> **Note:** This lab assumes you already have an operational AD DS environment. If not, complete [Deploying a Domain Controller in Azure](../Deploying%20a%20Domain%20Controller%20in%20Azure/README.md) first.

---

## Module / Track Structure

```text
Defender for Identity/
├── README.md
├── 1-defender-for-identity.md
└── 2-advanced-identity-investigation.md
```

---

## Quick Navigation

- [1. Prerequisites](#1-prerequisites)
- [2. Learning Objectives](#2-learning-objectives)
- [3. Scenario](#3-scenario)
- [4. Step 1 — Enable Defender for Identity](#4-step-1--enable-defender-for-identity)
- [5. Step 2 — Onboard and Validate Domain Controllers](#5-step-2--onboard-and-validate-domain-controllers)
- [6. Step 3 — Configure Directory Service Account and Posture](#6-step-3--configure-directory-service-account-and-posture)
- [7. Step 4 — Investigate Identity Detections](#7-step-4--investigate-identity-detections)
- [8. Step 5 — Operational Baseline Checklist](#8-step-5--operational-baseline-checklist)
- [9. Cleanup (Optional for Lab Subscriptions)](#9-cleanup-optional-for-lab-subscriptions)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | Security Administrator or equivalent Defender permissions |
| AD DS footprint | At least one healthy domain controller (recommended: two for redundancy) |
| Connectivity | Domain controllers can reach required Defender endpoints over outbound HTTPS |
| Defender licensing | Defender for Identity capability enabled in the tenant |
| Optional dependency | [Defender for Servers](../Defender%20for%20Servers/README.md) for correlated endpoint + identity investigation |
| Estimated time | 60-90 minutes |

Naming reference: [Naming Convention](../Naming-Convention.md)

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Enabled Defender for Identity in your tenant
- Onboarded and validated domain controller coverage
- Configured a least-privilege directory service account for secure data collection
- Reviewed identity posture recommendations and common health warnings
- Investigated identity alerts in Defender XDR and built a repeatable triage workflow

---

## 3. Scenario

Your environment has domain controllers running correctly, but AD DS activity still has blind spots in security operations. You need identity-layer detections for reconnaissance, credential theft, and privilege abuse, integrated with your existing Defender workflows.

---

## 4. Step 1 — Enable Defender for Identity

1. Open the Microsoft Defender portal.
2. Go to **Settings** and open the **Identities** workload section.
3. Confirm Defender for Identity is enabled for the tenant.
4. Review tenant-level prerequisites and endpoint connectivity guidance shown in the portal.

Validation outcome:
- The identities workload is active and ready for onboarding.

---

## 5. Step 2 — Onboard and Validate Domain Controllers

1. In Defender portal, open **Settings -> Identities -> Sensors**.
2. Start onboarding for each domain controller.
3. Follow the current onboarding method presented by the portal for your tenant.
4. After onboarding, confirm each domain controller appears as healthy in the sensor list.
5. Review sensor health warnings and resolve any connectivity or service issues.

Validation outcome:
- All target domain controllers show connected/healthy status with recent heartbeat.

---

## 6. Step 3 — Configure Directory Service Account and Posture

1. In Defender portal, configure a dedicated directory service account for identity query operations.
2. Assign only the documented minimum permissions required by Defender for Identity.
3. Open identity posture or secure score recommendations for identities.
4. Triage high-impact findings first (legacy protocols, unconstrained delegation, privileged account exposures).
5. Create remediation tasks in your team workflow for findings not fixed immediately.

Validation outcome:
- Directory service account is configured with least privilege.
- Identity posture findings are prioritized and tracked.

---

## 7. Step 4 — Investigate Identity Detections

1. Open **Incidents & Alerts** in Defender XDR.
2. Filter for identity alerts sourced from Defender for Identity.
3. For one alert, review:
   - Alert evidence and impacted entities (account, host, domain)
   - Timeline and correlated alerts from endpoint or cloud workloads
   - Suggested remediation actions
4. Document one runbook path for common detections:
   - Suspected reconnaissance
   - Suspected credential theft
   - Suspected privilege escalation

Validation outcome:
- Analysts can triage identity alerts with a consistent investigation pattern.

---

## 8. Step 5 — Operational Baseline Checklist

Create a recurring checklist (daily/weekly):

- Sensor health status for all domain controllers
- New high-severity identity alerts
- Identity posture drift (new critical recommendations)
- Directory service account status and permission review
- Correlation quality between identity and endpoint incidents

This checklist becomes your minimum operational standard for identity threat monitoring.

---

## 9. Cleanup (Optional for Lab Subscriptions)

Use this section only if you enabled Defender for Identity strictly for temporary lab validation:

1. Export or capture lab findings and screenshots.
2. Remove test-only service accounts if not required for ongoing use.
3. Disable or de-scope temporary resources according to your environment policy.

---

## What I Learned

- AD DS monitoring quality depends on both onboarding and sustained sensor health
- Identity detections become significantly more useful when correlated with endpoint context
- Operational consistency matters more than one-time setup; recurring checks prevent silent drift

---

[Continue to Lab 2: Advanced Investigation and Response](2-advanced-identity-investigation.md)

[← Back to Defender for Identity README](README.md)
[← Back to Azure Hands-On Engineering](../README.md)
