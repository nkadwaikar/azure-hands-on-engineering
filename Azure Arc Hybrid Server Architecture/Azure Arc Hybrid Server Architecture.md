# Azure Arc Hybrid Server Architecture (with Defender for Servers)

> **Why this matters:** Managing on-premises and multi-cloud servers without Azure Arc means separate toolchains for policy, patching, monitoring, and security — Arc projects every server into Azure Resource Manager so the same governance stack applies everywhere, with Defender for Servers as the security layer.

Last validated on: 2026-06-19  
Portal experience note: Validated against Azure Portal as of June 2026; agent installation steps apply to both Windows Server and supported Linux distributions.

> **Note:** This document is an architecture reference and design guide. Hands-on agent installation steps require outbound HTTPS (port 443) connectivity from the target server to Azure endpoints.

---

## Quick Navigation

- [Prerequisites](#0-prerequisites)
- [High-Level Architecture](#1-high-level-architecture)
- [Resource Organization & Governance](#2-resource-organization--governance)
- [Connectivity & Agent Architecture](#3-connectivity--agent-architecture)
- [Monitoring & Operations](#4-monitoring--operations)
- [Policy, Configuration & Compliance](#5-policy-configuration--compliance)
- [Security Architecture with Defender for Servers](#6-security-architecture-with-defender-for-servers)
- [Automation & Lifecycle Management](#7-automation--lifecycle-management)

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
- Optional: Microsoft Sentinel for SIEM

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

### 2.4  Management Group Hierarchy

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
- **HTTPS Proxy** — configure `--proxy-url` in the CMA installer and set `NO_PROXY` exceptions for local traffic.
- **ExpressRoute / VPN** — combine with private endpoints for fully private transit; no public endpoint exposure.

Document the chosen approach per site in the network runbook.

### 3.4 Agent Health & Extension Management

- Monitor agent connectivity via the `Heartbeat` table — alert if a machine misses heartbeats for > 15 minutes.
- Use **Arc extension inventory** (portal or `az connectedmachine extension list`) to audit installed extensions across all Arc machines.
- Pin extension versions where possible and test new versions in non-prod before promoting to prod.
- Define an **extension lifecycle policy**: which extensions are mandatory (AMA, MDE, Guest Config), which are optional, and who can approve additions.

### 3.5 Agent Installation

#### Windows (PowerShell — run as Administrator)

```powershell
# Set variables
$SubscriptionId = "<subscription-id>"
$ResourceGroup  = "rg-arc-servers-prod"
$TenantId       = "<tenant-id>"
$Location       = "eastus"

# Download the agent
Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" `
  -OutFile "$env:TEMP\AzureConnectedMachineAgent.msi"

# Install silently
msiexec /i "$env:TEMP\AzureConnectedMachineAgent.msi" /l*v "$env:TEMP\azcm.log" /qn

# Connect to Azure Arc
& "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect `
  --subscription-id $SubscriptionId `
  --resource-group  $ResourceGroup `
  --tenant-id       $TenantId `
  --location        $Location
```

#### Linux (bash — run as root or with sudo)

```bash
# Download and install the agent
curl -L https://aka.ms/azcmagent-linux | sudo bash

# Connect the agent to Azure Arc
sudo azcmagent connect \
  --subscription-id "<subscription-id>" \
  --resource-group  "rg-arc-servers-prod" \
  --tenant-id       "<tenant-id>" \
  --location        "eastus"
```

> **At-scale / unattended:** Use a service principal with the `Azure Connected Machine Onboarding` role and pass `--client-id` and `--client-secret` flags. Alternatively, generate an onboarding script from **Azure Arc → Add machines → Add multiple servers** in the portal.

### 3.6 Onboarding Verification

**On the server:**

```powershell
# Windows — check agent status and connectivity
azcmagent show
azcmagent check
```

```bash
# Linux — check agent status and connectivity
sudo azcmagent show
sudo azcmagent check
```

Expected output: `Agent Status: Connected`

**In the Azure Portal:**

1. Navigate to **Azure Arc → Machines** — confirm the server appears with **Status: Connected**
2. Verify the correct **Resource Group**, **Region**, and **Tags** are applied
3. Check the **Extensions** tab — AMA should appear after policy assignment executes
4. Navigate to **Defender for Cloud → Inventory** — the server should appear within ~15 minutes

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

Use **Azure Update Manager** (via Automation) for:

- Patch assessment
- Scheduled deployments
- Compliance reporting for Windows & Linux

Separate Prod vs Non-Prod maintenance windows; integrate with change management.

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

### 5.4  Configuration Drift Detection

- Schedule Guest Configuration assessments to run daily.
- Alert on newly non-compliant machines using a **Policy compliance change** event alert.
- Use Automation runbooks triggered by policy non-compliance events to auto-remediate low-risk drift (e.g., re-enabling a required service).
- Escalate high-risk drift (e.g., firewall disabled, audit logging off) as a Defender alert or ITSM incident.

---

## 6. Security Architecture with Defender for Servers

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
                     ├─ Security Alerts
                     └─ (Optional) Microsoft Sentinel → Incident Response
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
| Telemetry | Centralized in Log Analytics + Defender + Sentinel |

### 6.5 Just-in-Time (JIT) Admin Access

- Enable **JIT VM access** in Defender for Cloud for all production Arc servers.
- Require explicit JIT request approval before any administrative session (RDP/SSH) is permitted.
- Set maximum session duration (e.g., 2 hours) and restrict source IPs to known admin ranges or Azure Bastion.
- Log all JIT approvals and sessions to Log Analytics for audit trail.

### 6.6 File Integrity Monitoring (FIM)

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

### 7.2 Onboarding at Scale

- Arc at-scale onboarding scripts
- Configuration management tools (SCCM, Ansible, Puppet) to deploy CMA
- Azure Policy machine enrollment (preview) for auto-config of monitoring & security

### 7.3 Runbook Version Control & Testing

- Store all runbooks in **source control** (GitHub / Azure DevOps repo) — never edit directly in the Automation account.
- Use a **CI/CD pipeline** to lint, unit-test (Pester for PowerShell, pytest for Python), and publish runbooks to the Automation account on merge to main.
- Maintain a non-prod Automation account for staging runbook changes before promoting to production.
- Tag each runbook with version, owner, and last-tested date.

### 7.4  Emergency Break-Glass Procedure

Define a documented break-glass process for scenarios where normal Arc/Automation access is unavailable:

- Maintain a **break-glass admin account** in Entra ID with PIM-protected permanent access; stored credential in Azure Key Vault with monitored access.
- Document direct OS-level access paths (IPMI/iDRAC, out-of-band console) for on-prem servers.
- Test the break-glass procedure quarterly; log every use as a security event.
- Alert immediately if break-glass credentials are accessed outside a declared incident.

---

## Check List

1. **Validate prerequisites** — confirm all Azure roles, subscriptions, and OS support are in place.
2. **Provision Azure resources** — create Log Analytics Workspace, Automation account, Key Vault, and Storage account.
3. **Configure networking & DNS** — set up private endpoints, firewall rules, and custom DNS resolution for on-prem environment.
4. **Deploy Arc Connected Machine Agent** — use manual, scripted, or bulk deployment methods; verify agent registration in Azure.
5. **Onboard Defender for Servers** — enable Defender plans, configure monitoring policy, and validate data ingestion.
6. **Test policies & automations** — apply policies at scale, validate remediation runbooks, and monitor audit logs.
7. **Establish monitoring dashboard** — create alerting rules in Azure Monitor, KQL queries for incident detection.
8. **Document runbook version control** — set up CI/CD pipeline and source control for lifecycle automation.
9. **Conduct rollout in phased waves** — start with pilot group, expand to production with documented success criteria.
10. **Conduct break-glass procedure test** — validate emergency access and incident response playbook quarterly.

### 7.5 Decommissioning

Standard pattern:

1. Remove from CMDB
2. Stop Defender monitoring
3. Unregister Arc machine
4. Archive logs for compliance

---
