# Cost and Security Governance

Cost governance is not an afterthought — it is a design constraint applied from day one. Every architectural decision in this project was evaluated against its cost impact, ensuring predictable, controlled Azure spend without trading away security, reliability, or operational quality.

## Cost Tracking Reminder

To keep your Azure spend predictable, please use the Azure Pricing Calculator to estimate and track the cost of the services you deploy in this lab. Select each resource (VMs, Storage, Networking, App Services, etc.), adjust the configuration, and review the monthly estimate before you begin. This helps you stay within budget and ensures full cost visibility throughout the lab.

Azure Pricing Calculator:

[https://azure.microsoft.com/en-us/pricing/calculator/](https://azure.microsoft.com/en-us/pricing/calculator/) (azure.microsoft.com in Bing)

---

## Cost Optimisation Practices

| Practice | Detail |
| --- | --- |
| **Right‑sizing** | Compute and storage are sized to workload baselines and utilisation metrics — not worst‑case estimates. |
| **Auto‑shutdown** | Non‑production environments are scheduled to shut down outside business hours, eliminating idle consumption. |
| **Consumption‑based services** | Functions, Logic Apps, and event‑driven components replace fixed‑cost resources wherever workloads are bursty or intermittent. |
| **Log Analytics optimisation** | Ingestion is scoped via Data Collection Rules, retention is tuned per table, and workspaces are consolidated to avoid duplication. |
| **Dev/Test SKUs** | Lower‑cost SKUs are used in non‑production tiers where they meet functional requirements, reducing recurring charges. |
| **Tagging & policy enforcement** | Azure Policy enforces mandatory tags, blocks unapproved high‑cost SKUs, and flags resources missing cost attribution. |
| **Architecture efficiency** | Designs avoid unnecessary data egress, redundant components, and over‑provisioned redundancy tiers. |

---

## Security — Non‑Negotiables

Cost decisions are always weighed against security impact. The following controls are maintained regardless of cost pressure:

| Control | Implementation |
| --- | --- |
| **Least‑privilege access** | Managed Identities and service principals hold only the permissions their role requires — no standing admin access. |
| **Network isolation** | Resources sit behind Virtual Networks with private endpoints, NSGs, and subnet segmentation. No unnecessary public exposure. |
| **Secrets management** | Credentials and connection strings are never stored in code or config. All secrets live in Azure Key Vault, with access fully audited. |
| **Defender for Cloud** | Continuously monitors security posture, surfaces misconfigurations, and generates prioritised recommendations. |
| **JIT VM access** | Management ports are closed by default. Just‑In‑Time access opens them only on demand, for a limited window, to approved IPs. |
| **Policy enforcement** | Azure Policy enforces security baselines, blocks non‑compliant deployments, and auto‑remediates configuration drift. |
| **Break‑glass accounts** | Emergency accounts use certificate‑based authentication, are excluded from standard Conditional Access, and are monitored via high‑priority alerts. |

---

> No cost optimisation is applied if it weakens the security posture. Spend efficiency and security hardening are treated as complementary, not competing, goals.
> **⚠️ Cost Notice**
> Following this lab will incur Azure costs. Use a personal or trial subscription and delete resources when finished.

---

[← Back to Azure Hands-On Engineering](./README.md)