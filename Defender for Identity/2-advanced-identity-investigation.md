# Microsoft Defender for Identity — Advanced Investigation and Response Workflow

> **Why this matters:** The first minutes of an identity incident determine whether an attacker is contained or reaches domain dominance. This lab standardizes advanced triage: confirm blast radius, validate privileged exposure, correlate endpoint evidence, and execute containment in the right order.

Last validated on: 2026-09-12
Portal experience note: Screens and labels may vary slightly by tenant rollout, but the workflow remains valid across current Defender XDR experiences.

> **Note:** Complete [Lab 1](1-defender-for-identity.md) before this lab. Lab 2 assumes healthy sensor coverage on all target domain controllers.

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
- [4. Step 1 — Build Incident Scope Fast](#4-step-1--build-incident-scope-fast)
- [5. Step 2 — Analyze Lateral Movement Signals](#5-step-2--analyze-lateral-movement-signals)
- [6. Step 3 — Validate Privilege Escalation Risk](#6-step-3--validate-privilege-escalation-risk)
- [7. Step 4 — Correlate Identity and Endpoint Evidence](#7-step-4--correlate-identity-and-endpoint-evidence)
- [8. Step 5 — Execute Containment and Recovery Actions](#8-step-5--execute-containment-and-recovery-actions)
- [9. Step 6 — Post-Incident Hardening Backlog](#9-step-6--post-incident-hardening-backlog)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Prior lab | [1-defender-for-identity.md](1-defender-for-identity.md) completed |
| Defender XDR permissions | Security operations role with incident and alert investigation rights |
| Sensor state | All production-relevant domain controllers show healthy sensor status |
| Correlation dependency | [Defender for Servers](../Defender%20for%20Servers/README.md) recommended for endpoint-identity joins |
| Estimated time | 45-75 minutes |

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Built a repeatable incident triage workflow for high-severity identity alerts
- Distinguished reconnaissance from active lateral movement patterns
- Assessed privilege escalation risk using entity relationships and account context
- Correlated identity alerts with endpoint signals to confirm attacker behavior
- Executed containment actions in a controlled sequence
- Captured post-incident hardening tasks for long-term risk reduction

---

## 3. Scenario

A high-severity identity alert indicates suspicious authentication and potential credential abuse. Your goal is to determine whether this is isolated noise, targeted reconnaissance, or active lateral movement toward privileged assets.

---

## 4. Step 1 — Build Incident Scope Fast

1. Open **Incidents & alerts** in Defender XDR.
2. Filter incidents where identity alerts are present and sort by severity.
3. Open one high-severity incident and capture:
   - Incident start time and latest activity
   - Impacted users, hosts, and domain entities
   - Alert count and tactic mapping
4. Tag the incident with triage status and owner.
5. Record initial blast radius assumptions before deep investigation.

Validation outcome:
- You have a clear first-pass scope and ownership assigned.

---

## 5. Step 2 — Analyze Lateral Movement Signals

1. In the incident, open identity alerts related to suspicious remote execution, unusual authentication paths, or directory reconnaissance.
2. Review each alert's evidence timeline and sequence order.
3. Identify if access attempts are moving between hosts, service accounts, and privileged groups.
4. Flag indicators consistent with lateral movement:
   - Repeated authentication across multiple hosts
   - Unexpected protocol usage from unusual source systems
   - Privileged account use from non-admin workstations
5. Separate likely false positives from behavior requiring containment.

Validation outcome:
- Lateral movement hypothesis is either confirmed, rejected, or still pending evidence.

---

## 6. Step 3 — Validate Privilege Escalation Risk

1. Pivot to affected account entities.
2. Review group memberships and privileged role exposure.
3. Check if impacted identities have direct or nested high-privilege paths.
4. Prioritize accounts with elevated scope for immediate response action.
5. Document which identities represent domain-critical risk.

Validation outcome:
- Privilege escalation risk is clearly prioritized by account impact.

---

## 7. Step 4 — Correlate Identity and Endpoint Evidence

1. In the same incident, review correlated endpoint alerts.
2. Compare timestamps between identity and endpoint detections.
3. Validate whether endpoint events support identity findings (for example, suspicious process creation or credential access attempts).
4. Mark evidence quality:
   - Strong correlation
   - Partial correlation
   - Identity-only signal requiring further validation
5. Update incident notes with confidence level and rationale.

Validation outcome:
- Investigation confidence is evidence-based, not assumption-based.

---

## 8. Step 5 — Execute Containment and Recovery Actions

Containment order should reduce attacker reach before broad remediation:

1. Disable or isolate impacted accounts when misuse is confirmed.
2. Reset credentials and revoke sessions/tokens for compromised identities.
3. Isolate high-risk hosts where correlated endpoint compromise is likely.
4. Block identified malicious indicators according to your SOC process.
5. Coordinate with IAM and infrastructure teams before restoring access.

Validation outcome:
- Containment actions are complete, tracked, and reversible through approved process.

---

## 9. Step 6 — Post-Incident Hardening Backlog

Create remediation tasks from findings:

- Reduce standing privilege and enforce just-in-time admin patterns
- Remove legacy protocols where possible
- Tighten conditional access and authentication controls
- Review service account hygiene and delegation settings
- Tune detection rules and escalation thresholds

This closes the loop from incident response to long-term posture improvement.

---

## What I Learned

- Fast scope definition prevents investigation drift and missed critical entities
- Identity alerts gain practical value when correlated with endpoint evidence
- Containment sequence matters; removing attacker access paths first reduces blast radius immediately

---

[← Back to Defender for Identity README](README.md)
[← Back to Lab 1](1-defender-for-identity.md)
[← Back to Azure Hands-On Engineering](../README.md)
