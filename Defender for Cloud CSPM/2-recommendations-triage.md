# Defender for Cloud CSPM — Part 2: Fleet-Scale Recommendation Triage

> **Why this matters:** When Defender for Cloud surfaces 200 recommendations across 50 subscriptions, the challenge isn't finding security gaps — it's triaging them fast enough to act on the ones that actually matter. This lab teaches the workflows that make recommendation triage scale: category tabs to cut across resource types, Azure Resource Graph to query unhealthy resources in bulk, and the filter system to isolate high-severity findings before they become incidents.

Last validated on: 2026-07-19
Portal experience note: Steps validated against **Microsoft Defender for Cloud → Recommendations** as of July 2026. The individual recommendations model (one row per finding) is the current production model following the removal of grouped recommendations on July 31, 2026. All steps in this lab target the individual recommendations view.

> **Note:** This lab focuses on the triage workflow — understanding, filtering, and querying recommendations at scale. Remediation mechanics are covered in [Lab 1](1-cspm-secure-score.md). Governance rule assignment (owner + due-date) is covered in [Lab 5](5-governance-rules.md).

---

## Module / Track Structure

```text
Defender for Cloud CSPM/
├── README.md                        ← Track entry point
├── 1-cspm-secure-score.md           ← Lab 1: Secure Score, controls, improvement workflow
├── 2-recommendations-triage.md      ← Lab 2: Fleet-scale recommendation triage; ARG queries (you are here)
├── 3-regulatory-compliance.md       ← Lab 3: Compliance dashboard; framework mapping; export
├── 4-attack-path-analysis.md        ← Lab 4: Attack path graph; exploitable path review
└── 5-governance-rules.md            ← Lab 5: Owner assignment; SLA tracking; reporting
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Navigate the Recommendations Blade](#step-1--navigate-the-recommendations-blade)
  - [1.1 — Category tabs](#11--category-tabs)
  - [1.2 — Severity and freshness filters](#12--severity-and-freshness-filters)
- [Step 2 — Triage by Resource Type](#step-2--triage-by-resource-type)
- [Step 3 — Query Unhealthy Resources with Azure Resource Graph](#step-3--query-unhealthy-resources-with-azure-resource-graph)
  - [3.1 — Open Cloud Security Explorer](#31--open-cloud-security-explorer)
  - [3.2 — ARG queries in Log Analytics](#32--arg-queries-in-log-analytics)
- [Step 4 — Export Recommendations to CSV](#step-4--export-recommendations-to-csv)
- [Cleanup](#cleanup)

**Continue to:** [Lab 3 — Regulatory Compliance →](3-regulatory-compliance.md)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Security Reader** minimum; **Security Admin** to apply governance rules |
| Defender CSPM | Enabled on target subscription (see [Lab 1, Step 1](1-cspm-secure-score.md#step-1--enable-defender-cspm-plan)) |
| Prior lab | Complete [Lab 1 — Secure Score and Controls](1-cspm-secure-score.md) first |
| Estimated time | 30–45 minutes |
| Tools | Azure Portal; optionally Azure Resource Graph Explorer (available in portal) |

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Navigated the **Recommendations** blade and used category tabs to filter by resource type and risk area
- Applied **severity and environment filters** to surface the highest-priority findings first
- Identified the practical difference between **High**, **Medium**, and **Low** severity recommendations and how to prioritise between them
- Queried unhealthy resources using **Cloud Security Explorer** and raw **Azure Resource Graph KQL**
- Exported the current recommendations list to CSV for offline review or stakeholder reporting

---

## 3. Scenario

**Forty recommendations are marked High severity. Where do you start?**

Not all High severity findings are equally urgent. A public IP on a dev VM in a learning lab is lower risk than a publicly accessible storage account containing production secrets. This lab teaches you the filtering and querying workflow that separates findings by actual business impact rather than just the severity label.

---

## Step 1 — Navigate the Recommendations Blade

### 1.1 Category tabs

1. In **Defender for Cloud**, select **Cloud Security → Recommendations** from the left menu.
2. At the top of the Recommendations blade, you will see a row of **category tabs** — for example: All, Identity, Data, Compute, Networking, Management ports, App service, Containers, DevOps.
3. Click each tab to understand what falls within it:

   | Category tab | Resource types typically included |
   | --- | --- |
   | **Identity** | Entra ID accounts, service principals, MFA gaps, legacy auth |
   | **Data** | Storage accounts, SQL servers, Key Vaults, Cosmos DB |
   | **Compute** | Virtual machines, VMSS, Arc-enabled servers |
   | **Networking** | NSGs, open management ports, public IPs, DDoS settings |
   | **Management ports** | RDP (3389), SSH (22) — filtered from Networking for visibility |
   | **App service** | App Service instances, Function Apps |

4. The **All** tab shows every recommendation regardless of category — useful for bulk export but impractical for day-to-day triage at scale.

### 1.2 Severity and freshness filters

1. On the **All** tab (or within a category), click **Add filter**.
2. Explore the available filter dimensions:

   | Filter | Use case |
   | --- | --- |
   | **Severity: High** | Start here — surface the most critical findings first |
   | **Environment** | Filter to a specific subscription or connected cloud (AWS, GCP) |
   | **Resource type** | Narrow to a single resource type (e.g., `microsoft.storage/storageaccounts`) |
   | **Owner** | See recommendations assigned to a specific team member (requires governance rules — Lab 5) |
   | **Due date** | See overdue items only |
   | **Fix available** | Filter to recommendations that have a Quick Fix — fastest path to score improvement |

3. Apply **Severity: High** and note the count. This is your critical remediation backlog.
4. Further add **Fix available: Yes** — this subset is where you should focus first because the effort is lowest and the score impact is immediate.

---

## Step 2 — Triage by Resource Type

When multiple teams own different resource types, triaging by resource type lets you delegate accurately.

1. Apply the **Severity: High** filter.
2. Click **Group by: Resource type** (toggle in the top-right of the recommendations list).
3. The list collapses into resource-type groups. Expand each group to see the specific recommendations within it.
4. For each group, note:
   - **Total unhealthy resources** for that resource type
   - **Recommendations with Quick Fix available** — fastest wins
   - **Recommendations requiring manual action** — schedule these with the owning team

5. Use the **Export to CSV** button (Step 4) to capture this grouped view for delegation.

**Example triage decision:**

| Resource type | High severity count | Action |
| --- | --- | --- |
| `microsoft.storage/storageaccounts` | 12 | Quick Fix available for most — apply now |
| `microsoft.compute/virtualmachines` | 8 | Mix of Quick Fix and manual — split by owner |
| `microsoft.keyvault/vaults` | 3 | Manual — requires diagnostic setting configuration |

---

## Step 3 — Query Unhealthy Resources with Azure Resource Graph

### 3.1 Open Cloud Security Explorer

Cloud Security Explorer (Defender CSPM only) provides a graph-based query interface for CSPM data. It is the fastest way to find cross-resource risk patterns without writing raw KQL.

1. In **Defender for Cloud**, select **Cloud Security → Cloud security explorer**.
2. In the **Query template** dropdown, browse the pre-built templates:
   - **Internet-exposed VMs with high severity vulnerabilities** — highest priority starting point
   - **Storage accounts containing sensitive data with public access enabled** — data exfiltration risk
   - **Identities with excessive permissions** — lateral movement risk
3. Select **Internet-exposed VMs with high severity vulnerabilities** and click **Search**.
4. Review the results. Each row is a resource that matches all conditions simultaneously — not just any one of them. This is why Cloud Security Explorer is more useful than filtered recommendations for attack path reasoning.

### 3.2 ARG queries in Log Analytics

For fleet-scale automation and scheduled reporting, use Azure Resource Graph directly:

1. In the Azure Portal, search for **Resource Graph Explorer** and open it.
2. Run the following query to list all unhealthy recommendations across a subscription:

   ```kql
   SecurityResources
   | where type == "microsoft.security/assessments"
   | where properties.status.code == "Unhealthy"
   | project
       resourceId = tolower(properties.resourceDetails.id),
       recommendation = properties.displayName,
       severity = properties.metadata.severity,
       remediationDescription = properties.metadata.remediationDescription
   | order by severity asc
   ```

3. To narrow to a specific severity:

   ```kql
   SecurityResources
   | where type == "microsoft.security/assessments"
   | where properties.status.code == "Unhealthy"
   | where properties.metadata.severity == "High"
   | project
       resourceId = tolower(properties.resourceDetails.id),
       recommendation = properties.displayName,
       remediationDescription = properties.metadata.remediationDescription
   | order by recommendation asc
   ```

4. To find all storage accounts with public access enabled:

   ```kql
   SecurityResources
   | where type == "microsoft.security/assessments"
   | where properties.status.code == "Unhealthy"
   | where properties.displayName has "public"
   | where properties.resourceDetails.id has "storageaccounts"
   | project
       storageAccount = properties.resourceDetails.id,
       recommendation = properties.displayName,
       severity = properties.metadata.severity
   ```

5. Pin a query to an **Azure Dashboard** or export results via the **Download as CSV** button for stakeholder reporting.

---

## Step 4 — Export Recommendations to CSV

1. In the **Recommendations** blade, apply your desired filters (e.g., Severity: High, specific subscription).
2. Click the **Download CSV report** button (cloud-with-down-arrow icon in the toolbar).
3. The export includes:
   - Recommendation name and description
   - Severity
   - Affected resource name and resource ID
   - Remediation steps (text)
   - Control name
   - Score impact
4. Use this file for:
   - **Stakeholder reporting** — share with management or compliance teams without portal access
   - **Team delegation** — filter the spreadsheet by resource type or subscription to create per-team remediation lists
   - **Baseline tracking** — compare exports month-over-month to show posture improvement

---

## Cleanup

No resources were created in this lab. Filters and views are per-session and do not persist after closing the browser tab.

If you ran Resource Graph queries, they are saved in your browser session history within the Resource Graph Explorer and do not incur any charges.

---

**Continue to:** [Lab 3 — Regulatory Compliance →](3-regulatory-compliance.md)

← [Back to CSPM Track README](README.md)
