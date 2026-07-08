# Azure Arc Hybrid Server Architecture

Azure Arc projects on-premises and multi-cloud servers into Azure Resource Manager so the same governance stack — policy, patching, monitoring, and security — applies everywhere. Onboarding steps use the **Azure Portal UI** (the portal generates scripts for you; no manual CLI authoring required).

> **Requirements:** Outbound HTTPS (port 443) from each target server to Azure endpoints. Validated against Azure Portal as of July 2026; applies to both Windows Server and supported Linux distributions.

**Companion guide:** [On-Prem Hyper-V Lab Setup for Azure Arc](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) — step-by-step Hyper-V onboarding walkthrough.

---

## Contents

- [0. Prerequisites](#0-prerequisites)
- [1. High-Level Architecture](#1-high-level-architecture)
- [2. Resource Organization & Governance](#2-resource-organization--governance)
- [3. Connectivity & Agent Architecture](#3-connectivity--agent-architecture)
- [4. Monitoring & Operations](#4-monitoring--operations)
- [5. Policy, Configuration & Compliance](#5-policy-configuration--compliance)
- [6. Security Architecture with Defender for Servers](#6-security-architecture-with-defender-for-servers)
- [7. Automation & Lifecycle Management](#7-automation--lifecycle-management)
- [Check List](#check-list)

---

## 0. Prerequisites

Before onboarding servers to Azure Arc, ensure the following are in place.

### Permissions Required

| Role | Scope | Purpose |
| --- | --- | --- |
| `Azure Connected Machine Onboarding` | Subscription / RG | Register Arc machines |
| `Azure Connected Machine Resource Administrator` | Subscription / RG | Manage Arc machine resources |
| `Log Analytics Contributor` | Log Analytics Workspace | Configure monitoring |
| `Security Admin` | Subscription | Enable Defender for Cloud |

### Supported Operating Systems

| Platform | Supported Versions |
| --- | --- |
| Windows Server | 2008 R2 SP1, 2012, 2016, 2019, 2022 |
| Linux | RHEL 7+, SLES 12+, Ubuntu 16.04+, Debian 9+, Amazon Linux 2 |

**Server requirements:**

- Outbound HTTPS (port 443) to Azure endpoints
- 200 MB free disk space
- PowerShell 4.0+ (Windows) or `systemd` (Linux)
- TLS 1.2 or later

### Azure Resources to Pre-Create

- Resource Group (e.g. `rg-arc-servers-prod`)
- Log Analytics Workspace (e.g. `law-hybrid-ops`)
- Automation Account (for Update Manager and runbooks)
- Defender for Cloud with Servers plan enabled at subscription level

### 0.1 Resource Provider Registration (Portal)

Arc onboarding will fail silently on a fresh subscription if these aren't registered — check this **before** attempting any onboarding below.

1. In the Azure Portal, go to **Subscriptions** → select your subscription → **Resource providers** (left nav, under *Settings*).
2. Search for and confirm **Registered** status for:
   - `Microsoft.HybridCompute`
   - `Microsoft.GuestConfiguration`
   - `Microsoft.HybridConnectivity`
   - `Microsoft.AzureArcData` (only needed if you plan to use Arc-enabled data services later)
3. If any provider shows **NotRegistered**, select it and click **Register** at the top of the page. Registration typically completes within a few minutes — refresh the page to confirm.

### 0.2 Provision Supporting Azure Resources (Portal)

Create these before onboarding any servers — several onboarding and monitoring steps later in this doc assume they already exist.

#### Log Analytics Workspace

1. Portal → **Log Analytics workspaces** → **+ Create**.
2. Set subscription, resource group (e.g. `rg-arc-servers-prod`), name (e.g. `law-hybrid-ops`), and region.
3. Review + Create. Note the workspace name — you'll select it when configuring the AMA Data Collection Rule in Section 4.1.

#### Automation Account

1. Portal → **Automation Accounts** → **+ Create**.
2. Set subscription, resource group, name, and region.
3. Under **Advanced**, enable **System-assigned managed identity** (used later for runbooks in Section 7.1 and remediation in Section 5.4).
4. Review + Create.

#### Key Vault

(for break-glass credentials, Section 7.4)

1. Portal → **Key Vaults** → **+ Create**.
2. Set subscription, resource group, unique vault name, and region.
3. On the **Access configuration** tab, use **Azure RBAC** as the permission model (aligns with the RBAC-first approach in Section 2.3).
4. Review + Create. Once created, store the break-glass account credential as a secret and restrict access to a small, monitored group.

#### Storage Account

(for cold log archival, Section 4.5)

1. Portal → **Storage accounts** → **+ Create**.
2. Set subscription, resource group, unique account name, and region.
3. Redundancy: choose per your compliance requirement (e.g. GRS for cross-region durability).
4. Review + Create. This is the target you'll reference when configuring Log Analytics workspace **Data Export** rules for long-term retention tables (`SecurityAlert`, `AuditLogs`, `Syslog`).

---

## 1. High-Level Architecture

**Core idea:**
Non-Azure servers (on-prem, VMware, Hyper-V, AWS, GCP) are **projected into Azure Resource Manager** via the **Connected Machine Agent (CMA)** and managed like native Azure VMs — policy, monitoring, security, automation, RBAC.

**Main components:**

- Azure Arc-enabled Servers
- Azure Resource Manager (subscriptions, RGs, tags, RBAC)
- Log Analytics Workspace
- Azure Monitor (AMA, DCRs, Workbooks)
- Azure Automation / Update Manager
- Azure Policy & Guest Configuration
- Microsoft Defender for Cloud (Servers plan)

---

## 2. Resource Organization & Governance

### 2.1 Subscriptions and Resource Groups

- **Landing zone pattern:**
  - `sub-platform-hybrid` (Arc, monitoring, security)
  - `rg-arc-servers-prod`, `rg-arc-servers-nonprod`
- Keep Arc machines, Log Analytics, Automation, and Defender config in platform subscriptions for clean separation.

### 2.2 Tagging Strategy

Mandatory tags — enforced via Azure Policy (deny or modify) so Arc servers are compliant on onboarding:

| Tag | Values |
| --- | ------- |
| `Environment` | Prod, Dev, Test |
| `Location` | OnPrem, AWS, GCP, Branch |
| `BusinessUnit` | Finance, Retail, SharedServices |
| `Criticality` | Tier1, Tier2, Tier3 |

### 2.3 RBAC Model

| Role | Permissions |
| ------ | ------------- |
| `Hybrid-Server-Reader` | Read-only |
| `Hybrid-Server-Operator` | Restart, extensions, no policy changes |
| `Security-Operator` | Defender, alerts, recommendations |

Assign at RG or subscription level — avoid per-resource RBAC sprawl.

### 2.4 Management Group Hierarchy

Place the hybrid landing zone subscription under a dedicated **Management Group** (e.g., `mg-hybrid-servers`) so Azure Policy initiatives and RBAC can be inherited rather than re-applied per subscription. Align with the broader CAF (Cloud Adoption Framework) management group design if one exists.

---

## 3. Connectivity & Agent Architecture

### 3.1 Connected Machine Agent (CMA)

- Installed on each Windows/Linux server.
- Uses **outbound HTTPS** to Azure — no inbound firewall holes.
- Once registered, server gets:
  - Azure Resource ID
  - Arc Machine resource in chosen RG/region
  - Visibility in **Azure Arc → Machines**

### 3.2 Network & Identity

**Outbound endpoints required (port 443 HTTPS):**

| Endpoint | Purpose |
| ---------- | --------- |
| `*.his.arc.azure.com` | Arc agent heartbeat and metadata |
| `*.guestconfiguration.azure.com` | Guest Configuration extension |
| `*.guestnotificationservice.azure.com` | Notification service |
| `*.servicebus.windows.net` | Service Bus messaging |
| `management.azure.com` | Azure Resource Manager |
| `login.microsoftonline.com` | Entra ID authentication |
| `*.ods.opinsights.azure.com` | Log Analytics data ingestion |
| `*.oms.opinsights.azure.com` | Log Analytics OMS |
| `*.monitoring.azure.com` | Azure Monitor metrics |
| `packages.microsoft.com` | AMA and extension package downloads |

**Identity:**

- **Entra ID** for admin identities
- **Managed identities** for Automation runbooks and Logic Apps

### 3.3 Private Connectivity Options

For environments where direct outbound internet access is restricted, choose one of:

- **Azure Private Link** — route Arc, Log Analytics, and Automation traffic over a private endpoint; requires a Private Link Scope resource (`azuremonitor`, `Arc`).
- **HTTPS Proxy** — the portal onboarding flow (Section 3.5) prompts for a proxy URL directly when you select *Proxy server* as the connectivity method, so no manual `--proxy-url` flag editing is required.
- **ExpressRoute / VPN** — combine with private endpoints for fully private transit; no public endpoint exposure.

Document the chosen approach per site in the network runbook.

**Setting up Azure Arc Private Link Scope (Portal):**

1. Portal → search **Azure Arc Private Link Scope** → **+ Create**. Set subscription, resource group, name (e.g. `pls-arc-hybrid`), and region.
2. Go to the resource → **Private endpoint connections** → **+ Private endpoint**. Choose the VNet/subnet where on-prem VPN/ExpressRoute terminates.
3. Under **DNS**, let the wizard auto-create an **Azure Private DNS zone** (e.g. `privatelink.his.arc.azure.com`), or link your existing zone. The private endpoint's IP must resolve correctly from the server's network.
4. On the Private Link Scope resource → **Azure Arc machines** → **+ Add** — associate each Arc server so its traffic routes privately.
5. For on-prem custom DNS, add conditional forwarders for the `*.azure.com` zones from Section 3.2 pointing to the Private DNS zone, or create matching A records manually.

> Repeat per site/region and document each in your network runbook.

### 3.4 Agent Health & Extension Management

- Monitor agent connectivity via the `Heartbeat` table — alert if a machine misses heartbeats for > 15 minutes.
- Use **Azure Arc → Machines → [server] → Extensions** in the portal to audit installed extensions on an individual machine, or **Azure Arc → Machines → Extensions** (fleet view) to audit across all Arc machines at once.
- Pin extension versions where possible and test new versions in non-prod before promoting to prod.
- Define an **extension lifecycle policy**: which extensions are mandatory (AMA, MDE, Guest Config), which are optional, and who can approve additions.

### 3.5 Onboarding a Single Server (Azure Portal)

> **See also:** [On-Prem Hyper-V Setup](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) — covers the full onboarding flow in a Hyper-V environment.

1. In the Azure Portal, search **Azure Arc** → **Machines** → **+ Add/Create**.
2. Choose **Add a single server** → **Generate script**.
3. On the **Prerequisites** tab, confirm the resource providers from Section 0.1 show as registered (the portal will flag this automatically if something is missing).
4. On the **Resource details** tab, fill in:
   - Subscription
   - Resource group (e.g. `rg-arc-servers-prod`)
   - Region
5. On the **Connectivity method** tab, choose:
   - **Public endpoint** (default, direct outbound HTTPS), or
   - **Proxy server** — enter the proxy URL if your environment routes through an HTTPS proxy (see Section 3.3)
6. On the **Tags** tab, apply the mandatory tags from Section 2.2 (`Environment`, `Location`, `BusinessUnit`, `Criticality`) — applying them here means the server is tag-compliant from the moment it registers, rather than needing remediation afterward.
7. Review + **Download** the generated script — the portal produces a `.ps1` (Windows) or `.sh` (Linux) file with your subscription ID, resource group, tenant ID, region, proxy settings, and tags already embedded. No manual variable editing needed.
8. Copy the downloaded script to the target server and run it:
   - **Windows:** right-click → *Run with PowerShell* (as Administrator)
   - **Linux:** `sudo bash <script-name>.sh`
9. The script handles agent download, silent install, and connection to Arc in one pass.

### 3.6 Onboarding Verification (Portal)

1. In the Azure Portal, go to **Azure Arc → Machines**.
2. Locate the server (filter by resource group or tag if the list is large) — confirm **Status: Connected**. Allow a few minutes after the script completes.
3. Select the machine resource and verify the **Overview** pane shows the correct **Resource Group**, **Region**, and **Tags**.
4. Open the **Extensions** tab — the Azure Monitor Agent (AMA) should appear here once the relevant policy assignment executes (may take up to 30 minutes on first onboarding).
5. Go to **Microsoft Defender for Cloud → Inventory**, filter by resource type *Arc Machine* — the server should appear within ~15 minutes of connecting.
6. If the server does not show **Connected** after 10–15 minutes, open **Azure Arc → Machines → [server] → Redeploy agent troubleshooter** (portal-guided diagnostics) or check that the outbound endpoints in Section 3.2 are reachable from the server.

---

## 4. Monitoring & Operations

### 4.1 Monitoring Pipeline

- **Azure Monitor Agent (AMA)** deployed via Arc extensions.
- **Data Collection Rules (DCRs):**
  - OS performance (CPU, memory, disk)
  - Windows Event Logs / Syslog
  - Heartbeat, dependency maps (VM Insights)
- All data sent to central Log Analytics workspace (e.g. `law-hybrid-ops`).

### 4.2 Update Management

> **Dedicated track:** Full hands-on lab for Azure Update Manager lives in [Azure Update Manager → 1-Azure Update Manager.md](../Azure%20Update%20Manager/1-Azure%20Update%20Manager.md). This section summarises how it fits into the Arc architecture.

Use **Azure Update Manager** for:

- Patch assessment (on-demand or scheduled)
- Scheduled deployments with maintenance windows
- Compliance reporting for Windows & Linux across Azure VMs and Arc-enabled servers

Separate Prod vs Non-Prod maintenance windows; integrate with change management. Target machines by resource group or tag (dynamic scope) so fleet membership stays accurate as servers are added or retired.

### 4.3 Workbooks & KQL

Build workbooks for: health & performance, patch compliance, Arc connectivity status.

| Query            | Purpose                    |
|------------------|----------------------------|
| `Heartbeat`      | Availability monitoring    |
| `UpdateSummary`  | Patch status reporting     |
| `SecurityAlert`  | Defender signals           |

### 4.4 Alerting & Notification

Define alert rules in Azure Monitor for actionable conditions:

| Alert | Condition | Severity |
| --- | --- | --- |
| Arc agent offline | No heartbeat > 15 min | Sev 1 |
| CPU sustained high | CPU > 90% for 10 min | Sev 2 |
| Disk space critical | Free disk < 10% | Sev 2 |
| Patch compliance breach | Machines not patched > 30 days | Sev 3 |

Route alerts to **Action Groups** targeting on-call teams (email, SMS, PagerDuty webhook). Separate action groups for Ops vs Security teams. Suppress known maintenance windows using alert suppression rules.

### 4.5 Log Retention & Archival Policy

- Set the **Log Analytics workspace retention** to meet compliance requirements (e.g., 90 days hot, 2 years archived using workspace archive tier).
- Export long-term audit logs (Security, Defender alerts) to **Azure Storage** or an Event Hub for cold storage.
- Define which tables require longer retention (e.g., `SecurityAlert`, `AuditLogs`, `Syslog`) vs. short-lived telemetry (`Perf`, `Heartbeat`).
- Review ingestion costs quarterly; adjust DCR scope (sampling, filtering) to control spend.

---

## 5. Policy, Configuration & Compliance

### 5.1 Azure Policy for Arc Servers

Use **Arc-enabled servers built-in policies** to:

- Ensure AMA is installed
- Connect to specific Log Analytics workspace
- Deploy required extensions (Dependency agent, Guest Configuration)

Group into a **policy initiative** (e.g. `Arc-Server-Baseline`) and assign at subscription/RG.

### 5.2 Guest Configuration

Use **machine configuration** (Guest Configuration) to:

- Audit OS settings, registry, services, daemons
- Enforce security baselines (CIS, Microsoft benchmarks)
- Report compliance centrally; remediate via Automation runbooks

### 5.3 Policy Exemptions Management

Not every server fits every policy. Establish a formal exemption process:

- Use **Azure Policy exemptions** (Waiver or Mitigated category) rather than excluding resources from scope.
- Require documented business justification, approver, and expiry date for each exemption.
- Review all exemptions quarterly — auto-expire after 12 months unless renewed.
- Track exemptions centrally (e.g., in a tagged Azure resource or a spreadsheet linked from the CMDB).

### 5.4 Configuration Drift Detection

- Schedule Guest Configuration assessments to run daily.
- Alert on newly non-compliant machines using a **Policy compliance change** event alert.
- Use Automation runbooks triggered by policy non-compliance events to auto-remediate low-risk drift (e.g., re-enabling a required service).
- Escalate high-risk drift (e.g., firewall disabled, audit logging off) as a Defender alert or ITSM incident.

---

## 6. Security Architecture with Defender for Servers

> **Dedicated track:** Hands-on Defender for Servers labs (enable plan, Secure Score, vulnerability assessment, FIM, alert investigation) live in the [Microsoft Defender for Cloud track](../Microsoft%20Defender%20for%20Cloud/README.md). JIT VM access is covered separately in [1-JIT.md](../Microsoft%20Defender%20for%20Cloud/1-JIT.md). This section documents the security architecture as it relates to Arc.

### 6.1 Defender for Cloud Integration

- Enable **Defender for Cloud → Servers plan** at subscription level.
- Arc machines automatically onboard to:
  - Defender for Endpoint (EDR)
  - Vulnerability assessment
  - Threat detection & hardening recommendations

### 6.2 Security Data Flow

```text
Arc Server
  └─ AMA → Log Analytics Workspace
               └─ Defender for Cloud
                     ├─ Recommendations
                     └─ Security Alerts
```

### 6.3 Secure Score & Recommendations

Use **Secure Score** as the primary KPI covering:

- Missing patches
- Weak configurations
- Exposed services

Build **Logic App workflows** for high-severity alerts (lateral movement, ransomware indicators) to auto-create tickets in ITSM (ServiceNow, Jira, etc.).

### 6.4 Zero Trust Alignment

| Pillar | Control |
| --------- | ----------- |
| Identity | Entra ID + Conditional Access for admin access |
| Device | Defender for Endpoint on Arc servers |
| Network | Outbound-only, micro-segmentation on-prem |
| Policy | Azure Policy + Guest Configuration for hardening |
| Telemetry | Centralized in Log Analytics + Defender for Cloud |

### 6.5 Just-in-Time (JIT) Admin Access

- Enable **JIT VM access** in Defender for Cloud for all production Arc servers.
- Require explicit JIT request approval before any administrative session (RDP/SSH) is permitted.
- Set maximum session duration (e.g., 2 hours) and restrict source IPs to known admin ranges or Azure Bastion.
- Log all JIT approvals and sessions to Log Analytics for audit trail.

### 6.6 File Integrity Monitoring (FIM)

> **See also:** The [On-Prem Hyper-V Setup](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) covers validating FIM with file-share workloads.

- Enable **FIM** (available in Defender for Servers Plan 2) on critical servers.
- Monitor high-value paths: system binaries (`/bin`, `/sbin`, `C:\Windows\System32`), configuration files (`/etc`, web server configs), and startup locations.
- Alert on unexpected changes; investigate before approving.
- Maintain an approved change baseline — update it during patching windows to suppress false positives.

### 6.7 Defender Plan Cost Management

- **Plan 2** (full EDR + FIM + JIT + vulnerability assessment) should be reserved for Tier1/Tier2 servers.
- **Plan 1** (foundational posture only) is sufficient for Tier3 / dev/test servers — apply via subscription filter or resource tag.
- Review the **Defender for Cloud cost estimate** monthly; use the `microsoft.security/pricings` resource to apply granular plan overrides per resource group.
- Set **budget alerts** in Azure Cost Management for the Defender spend envelope.

---

## 7. Automation & Lifecycle Management

### 7.1 Runbooks & Workflows

Use **Azure Automation** (or Logic Apps) for:

- On-demand patching
- Service restarts
- Baseline remediation
- Bulk tag fixes

**Triggers:** Defender alerts, policy non-compliance, scheduled jobs.

### 7.2 Onboarding Multiple Servers at Scale (Azure Portal)

> **See also:** The [On-Prem Hyper-V Setup](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) covers the Group Policy bulk-onboarding method for AD-joined machines.

1. In the Azure Portal, go to **Azure Arc → Machines → + Add/Create → Add multiple servers**.
2. Choose a deployment method based on your existing tooling:
   - **SCCM** — generates a Configuration Manager package for your existing SCCM deployment
   - **Group Policy** — generates a GPO logon script for AD-joined on-prem machines
   - **Ansible / Chef / Puppet** — generates the corresponding role/playbook/manifest
   - **Custom script (PowerShell/bash)** — generates a standalone bulk script for any other distribution method
3. On the **Resource details** tab, set the subscription, resource group, and region that all onboarded servers will share.
4. On the **Tags** tab, apply the mandatory tags from Section 2.2 — these will be stamped on every server onboarded through this batch.
5. On the **Authentication** tab, the portal defaults to generating a **service principal** automatically, scoped to the `Azure Connected Machine Onboarding` role on your target resource group — you don't need to pre-create one in Entra ID. Set an **expiration** on the credential (shorter is better for a one-time bulk rollout; e.g. 7–30 days).
6. Review + **Download** the generated package/script and distribute it via your chosen method (SCCM package deployment, GPO, Ansible playbook run, etc.).
7. Monitor rollout: **Azure Arc → Machines**, filter by resource group or tag, and compare the **Connected** count against the number of servers targeted in the batch.

> **At-scale caution:** Stagger large rollouts (a few hundred at a time). Bulk registration can hit ARM request throttling — the portal won't warn you in advance; check the onboarding log rather than assuming a clean run.
>
> **Service principal cleanup:** Once all servers show **Connected**, go to **Entra ID → App registrations**, find the auto-generated onboarding service principal, and delete it or confirm the credential expiry (set in step 5) is short. Treat it like any other service principal under your RBAC review process (Section 2.3).

**Sizing guidance:**

| Server count | Recommended approach |
| --- | --- |
| 1–10 | Single-server onboarding (Section 3.5), or one small multi-server batch |
| ~10–100 | Pilot with 5–10 servers first, then one bulk batch for the remainder |
| Several hundred | Split into batches of a few hundred at a time to avoid ARM throttling |
| 1,000+ | Batch by site/wave; monitor onboarding logs per batch before starting the next |

**Splitting by resource group (prod vs non-prod):** the **Add multiple servers** wizard only accepts one resource group per batch, so if your fleet spans both `rg-arc-servers-prod` and `rg-arc-servers-nonprod` (Section 2.1), sort your server list by environment first and run **one batch per resource group**:

1. Run the wizard once targeting `rg-arc-servers-prod`, applying `Environment: Prod` (and other Section 2.2 tags) to that batch.
2. Run it again targeting `rg-arc-servers-nonprod`, applying `Environment: Dev`/`Test` tags to that batch.

This keeps tagging accurate per server without manual fix-up afterward, and lets RBAC (Section 2.3) and policy initiatives (Section 5.1) apply correctly since both are assigned at the resource-group level.

### 7.3 Runbook Version Control & Testing

- Store all runbooks in **source control** (GitHub / Azure DevOps repo) — never edit directly in the Automation account.
- Use a **CI/CD pipeline** to lint, unit-test (Pester for PowerShell, pytest for Python), and publish runbooks to the Automation account on merge to main.
- Maintain a non-prod Automation account for staging runbook changes before promoting to production.
- Tag each runbook with version, owner, and last-tested date.

### 7.4 Emergency Break-Glass Procedure

Define a documented break-glass process for scenarios where normal Arc/Automation access is unavailable:

- Maintain a **break-glass admin account** in Entra ID with PIM-protected permanent access; stored credential in Azure Key Vault with monitored access.
- Document direct OS-level access paths (IPMI/iDRAC, out-of-band console) for on-prem servers.
- Test the break-glass procedure quarterly; log every use as a security event.
- Alert immediately if break-glass credentials are accessed outside a declared incident.

### 7.5 Decommissioning (Azure Portal)

1. In the Azure Portal, go to **Azure Arc → Machines** and select the server(s) to decommission.
2. If Defender for Servers is enabled, go to **Microsoft Defender for Cloud → Environment settings**, locate the subscription/resource group, and confirm the plan assignment — Defender coverage is tied to the Arc machine resource, so it's automatically removed once the Arc resource itself is deleted in step 4.
3. On the server itself, uninstall the Connected Machine Agent:
   - **Windows:** *Settings → Apps → Installed apps* → find **Azure Connected Machine Agent** → Uninstall
   - **Linux:** remove via your distro's package manager (e.g. `apt remove azcmagent` / `yum remove azcmagent`)
4. Back in the Azure Portal, with the machine(s) still selected in **Azure Arc → Machines**, click **Delete** at the top of the list to remove the ARM resource. This step is required — uninstalling the agent locally disconnects the server but does **not** remove the stale resource from Azure Resource Manager.
5. Confirm removal: refresh **Azure Arc → Machines** and verify the server no longer appears; check **Microsoft Defender for Cloud → Inventory** to confirm it has dropped out of Defender coverage as well.
6. Review **Log Analytics workspace → Logs** — retention/archival settings from [Section 4.5](#45-log-retention--archival-policy) are workspace-level, not per-machine, so historical data for the decommissioned server remains available for the configured retention window without any extra action.
7. Remove the server from your CMDB and any tag-based inventory dashboards or workbooks.

---

## Check List

1. **Validate prerequisites** — confirm all Azure roles, subscriptions, resource provider registration, and OS support are in place.
2. **Provision Azure resources** — create Log Analytics Workspace, Automation account, Key Vault, and Storage account ([Section 0.2](#02-provision-supporting-azure-resources-portal)).
3. **Configure networking & DNS** — set up Private Link Scope, private endpoints, firewall rules, and custom DNS resolution for on-prem environment ([Section 3.3](#33-private-connectivity-options)).
4. **Deploy Arc Connected Machine Agent** — use the Azure Portal's single-server or multiple-server onboarding flow; verify agent registration in Azure Arc → Machines ([Section 3.5](#35-onboarding-a-single-server-azure-portal), [3.6](#36-onboarding-verification-portal)).
5. **Onboard Defender for Servers** — enable Defender plans, configure monitoring policy, and validate data ingestion ([Section 6.1](#61-defender-for-cloud-integration)).
6. **Test policies & automations** — apply policies at scale, validate remediation runbooks, and monitor audit logs ([Section 5.1](#51-azure-policy-for-arc-servers), [7.1](#71-runbooks--workflows)).
7. **Establish monitoring dashboard** — create alerting rules in Azure Monitor, KQL queries for incident detection ([Section 4.3](#43-workbooks--kql), [4.4](#44-alerting--notification)).
8. **Document runbook version control** — set up CI/CD pipeline and source control for lifecycle automation ([Section 7.3](#73-runbook-version-control--testing)).
9. **Conduct rollout in phased waves** — start with pilot group, expand to production with documented success criteria ([Section 7.2](#72-onboarding-multiple-servers-at-scale-azure-portal)).
10. **Conduct break-glass procedure test** — validate emergency access and incident response playbook quarterly ([Section 7.4](#74-emergency-break-glass-procedure)).
11. **Validate decommissioning process** — confirm portal-based teardown steps are documented and tested before relying on them at scale ([Section 7.5](#75-decommissioning-azure-portal)).

## Related

- [On-Prem Hyper-V Setup for Azure Arc](2-On-Prem%20Hyper-V%20Lab%20Setup%20for%20Azure%20Arc.md) — Hyper-V environment setup to validate onboarding, policy, Defender, and FIM
- [Azure Arc Track Overview](README.md)
- [Back to Azure Hands-On Engineering](../README.md)
