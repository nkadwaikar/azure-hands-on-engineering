# Microsoft Copilot Studio — Governed AI Agent on a Zero Trust Foundation

> **Why this matters:** Generic AI chatbots answer from a global model — they don't know your policies, your internal documentation, or your compliance boundaries. Copilot Studio changes that: you build an agent grounded in your SharePoint knowledge, secured with Entra ID authentication, and governed by Purview DLP policies. Every response traces back to your content, every user is authenticated, and every sensitive data boundary is enforced before the agent responds. This lab builds that pattern end-to-end.

Last validated on: July 2026
Portal experience note: Steps validated against Microsoft Copilot Studio (copilotstudio.microsoft.com) and Power Platform Admin Center (admin.powerplatform.microsoft.com) as of July 2026. UI labels can vary slightly by tenant licence configuration and feature rollout.

> **Note:** This lab requires an active Microsoft 365 tenant with SharePoint Online and a Power Platform environment. Complete the [Identity-First Track](../Identity-First/README.md) and [Microsoft 365 Track](../Microsoft%20365/README.md) first for the Entra ID and SharePoint foundations this lab builds on.

---

## Module / Track Structure

```text
Copilot Studio/
├── README.md                          ← Track entry point
└── 1-copilot-studio-agent.md          ← Lab 1: Build, secure, and govern a SharePoint-grounded AI agent (you are here)
```

---

## Quick Navigation

- [Prerequisites](#1-prerequisites)
- [Learning Objectives](#2-learning-objectives)
- [Scenario](#3-scenario)
- [Step 1 — Create the Copilot Studio Environment](#step-1--create-the-copilot-studio-environment)
- [Step 2 — Build the Agent and Add a Knowledge Source](#step-2--build-the-agent-and-add-a-knowledge-source)
- [Step 3 — Configure Entra ID Authentication](#step-3--configure-entra-id-authentication)
- [Step 4 — Test the Agent in the Studio](#step-4--test-the-agent-in-the-studio)
- [Step 5 — Apply DLP Governance](#step-5--apply-dlp-governance)
- [Step 6 — Publish to Microsoft Teams](#step-6--publish-to-microsoft-teams)
- [Step 7 — Monitor and Audit Agent Activity](#step-7--monitor-and-audit-agent-activity)
- [Troubleshooting](#troubleshooting)
- [What I Learned](#what-i-learned)
- [Cleanup](#cleanup)

---

## 1. Prerequisites

| Requirement | Detail |
| --- | --- |
| Role — Power Platform | **Environment Maker** in the target Power Platform environment |
| Role — SharePoint | **Site Member** (read access minimum) on the SharePoint site used as the knowledge source |
| Role — Entra ID | **Application Administrator** to create the app registration for Entra ID auth |
| Role — Purview | **Compliance Administrator** to configure DLP policies |
| Licence | Microsoft Copilot Studio licence (or Power Platform trial with Copilot Studio capacity) |
| SharePoint site | An existing SharePoint site with at least one document library containing policy or reference documents |
| Microsoft 365 track | Complete [Microsoft 365 Track](../Microsoft%20365/README.md) — SharePoint architecture and Purview foundations |
| Identity foundation | Complete [Identity-First Track](../Identity-First/README.md) — Entra ID app registrations and RBAC |
| Estimated Time | 90–120 minutes |
| Tools | Copilot Studio portal (copilotstudio.microsoft.com), Power Platform Admin Center (admin.powerplatform.microsoft.com), Azure Portal (app registration), Microsoft Teams |

Naming reference: [Naming Convention](../Naming-Convention.md)

### Assumptions and Scope Boundaries

- This lab builds a **single-topic, SharePoint-grounded agent** — not a general-purpose assistant. Scoping the knowledge source prevents hallucination and keeps DLP policies enforceable.
- Entra ID authentication is configured using the **manual** OAuth flow with an app registration. The simplified "Azure AD (prebuilt)" option is available but doesn't give you visibility into the app registration or token claims — this lab uses the manual method to show the full pattern.
- DLP policies applied in Power Platform Admin Center govern which **connectors** the agent can use. They do not govern the content of responses from the AI model itself — use Purview sensitivity labels and SharePoint permissions to control what content the knowledge source exposes.
- Publishing to Teams creates a Teams App — the lab covers personal-scope publishing. Channel-scope deployment follows the same pattern but requires additional Teams App Policy configuration.

---

## 2. Learning Objectives

By the end of this lab, you will have:

- Created a Copilot Studio agent in a **dedicated Power Platform environment**
- Added a **SharePoint document library** as a grounded knowledge source
- Configured **Entra ID (OAuth) authentication** using a manually registered Entra app
- Validated that the agent returns **answers grounded in your documents** — not generic model responses
- Applied a **Power Platform DLP policy** that blocks unintended connector usage by the agent
- Published the agent to **Microsoft Teams** with scoped access via a Teams App Policy
- Reviewed **conversation analytics and session transcripts** in the Copilot Studio monitoring dashboard
- Confirmed agent activity in **Microsoft Purview Audit**

---

## 3. Scenario

**Your team needs answers from your internal policies — without reading 40-page PDFs.**

HR policies, IT runbooks, and compliance guides live in SharePoint but are rarely read in full. Staff ask the same questions repeatedly — to managers, to IT, to HR. A Copilot Studio agent grounded in those documents answers those questions instantly, cites the source document, and enforces the same access boundaries as SharePoint itself: if a user can't read a document in SharePoint, the agent won't surface its content. This lab builds that agent.

---

## Step 1 — Create the Copilot Studio Environment

### 1.1 Verify Your Power Platform Environment

1. Go to **Power Platform Admin Center** (admin.powerplatform.microsoft.com)
2. Click **Environments** → confirm a **non-default** environment exists for this lab (e.g., `env-copilot-lab`)
3. If not, click **New** and create an environment:
   - **Name:** `env-copilot-lab`
   - **Type:** Sandbox
   - **Region:** Select the region matching your data residency requirement
   - **Enable Dataverse:** Yes (required for Copilot Studio)
4. Note the environment URL — you will use it when registering the Entra app

### 1.2 Open Copilot Studio

1. Go to **copilotstudio.microsoft.com**
2. In the top-right environment picker, select `env-copilot-lab`
3. Confirm the portal reflects the correct environment name before proceeding

---

## Step 2 — Build the Agent and Add a Knowledge Source

### 2.1 Create the Agent

1. In Copilot Studio, click **Create** → **New agent**
2. Describe your agent in the creation dialog — for example:
   ```
   An internal IT policy assistant that answers questions about IT security
   policies, acceptable use, and onboarding procedures from our SharePoint
   document library.
   ```
3. Copilot Studio will suggest a name, description, and initial topics — review them
4. Set the **Agent name** (e.g., `IT Policy Assistant`)
5. Click **Create**

### 2.2 Add a SharePoint Knowledge Source

1. In the agent editor, click **Knowledge** (left sidebar) → **Add knowledge**
2. Select **SharePoint**
3. Enter the URL of your SharePoint site (e.g., `https://contoso.sharepoint.com/sites/ITPolicy`)
4. Click **Add** — Copilot Studio will index the accessible document libraries on that site
5. Once indexing completes, the knowledge source appears in the **Knowledge** panel with a status of **Ready**

> **Scope tip:** Add only the specific document libraries your agent should reference. Grounding on a whole site with hundreds of libraries increases response latency and can surface unintended content. Use SharePoint folder-level scoping where possible.

### 2.3 Verify Knowledge Grounding Works (Before Adding Auth)

1. In the **Test** panel (right side of the editor), ask a question answered by a document in your SharePoint library:
   ```
   What is the acceptable use policy for personal devices?
   ```
2. The agent should return an answer with a **citation** pointing to the source document
3. If it returns a generic answer without a citation, the knowledge source is not yet grounded — check indexing status and re-index if needed

---

## Step 3 — Configure Entra ID Authentication

By default, Copilot Studio agents use no authentication. This step locks the agent to authenticated Entra ID users only.

### 3.1 Register an Entra ID Application

1. Go to **Azure Portal** → **Microsoft Entra ID** → **App registrations** → **New registration**
2. Set the following:
   - **Name:** `copilot-studio-it-policy-agent`
   - **Supported account types:** Accounts in this organizational directory only (single tenant)
   - **Redirect URI:** Web → `https://token.botframework.com/.auth/web/redirect`
3. Click **Register**
4. Note the **Application (client) ID** and **Directory (tenant) ID**

### 3.2 Create a Client Secret

1. In the app registration, click **Certificates & secrets** → **New client secret**
2. Set a description (e.g., `copilot-studio-secret`) and an expiry of **6 months**
3. Click **Add** → copy the secret **Value** immediately (it will not be shown again)

> **Security note:** Store this secret in Azure Key Vault rather than copying it into a text file. See the [Identity-First Track — Lab 2](../Identity-First/02-managed-identity-keyvault-secretless-auth.md) for the Key Vault pattern.

### 3.3 Add API Permissions

1. Still in the app registration, click **API permissions** → **Add a permission**
2. Select **Microsoft Graph** → **Delegated permissions**
3. Add `openid`, `profile`, and `email`
4. Click **Add permissions** → **Grant admin consent** → **Yes**

### 3.4 Configure Authentication in Copilot Studio

1. Back in Copilot Studio, click **Settings** (gear icon) → **Security** → **Authentication**
2. Select **Authenticate with Microsoft** (manual configuration)
3. Enter:
   - **Client ID:** the Application (client) ID from Step 3.1
   - **Client secret:** the secret value from Step 3.2
   - **Tenant ID:** your Directory (tenant) ID
   - **Scopes:** `openid profile email`
4. Click **Save**
5. A sign-in topic is automatically added to the agent — do not delete it

### 3.5 Validate Authentication in the Test Panel

1. In the **Test** panel, click **Start over** to reset the session
2. The agent should now prompt for sign-in before answering questions
3. Complete the sign-in flow using your Entra ID credentials
4. After authentication, ask a knowledge question — the agent should return a grounded response

---

## Step 4 — Test the Agent in the Studio

### 4.1 Verify Grounded Responses

Ask a series of questions that should be answered from your SharePoint documents:

```
What is the password rotation policy?
How do I request access to a restricted system?
What happens if I violate the acceptable use policy?
```

For each question, confirm:
- The response directly references content from your documents
- A citation link appears pointing to the source file
- The response does not make up information absent from the documents

### 4.2 Test Out-of-Scope Handling

Ask a question that is not answered by any document in the knowledge source:

```
What is the capital of France?
```

The agent should respond with a graceful "I don't know" or redirect message — **not** a generic AI answer drawn from the underlying model's training data. If it does return a generic answer, review the **Generative answers** settings in the agent and set fallback behavior to "Do not answer if not in knowledge source."

---

## Step 5 — Apply DLP Governance

Power Platform DLP policies control which connectors the agent is allowed to use. This prevents an agent from calling external services or APIs that were not explicitly authorized.

### 5.1 Create a DLP Policy

1. Go to **Power Platform Admin Center** → **Policies** → **Data policies** → **New policy**
2. Name the policy `copilot-lab-dlp`
3. On the **Prebuilt connectors** tab, move all connectors to **Blocked** by default
4. Move only these connectors to **Business** (allowed):
   - **Microsoft Dataverse** (required for Copilot Studio agent runtime)
   - **SharePoint** (required for knowledge source access)
5. Confirm all other connectors remain in **Blocked**
6. On the **Scope** tab, set the policy to apply to `env-copilot-lab` only
7. Click **Next** → **Create policy**

### 5.2 Verify the Policy Is Enforced

1. Return to Copilot Studio and attempt to add a connector that was just blocked (e.g., **HTTP with Azure AD**)
2. The studio should display a DLP violation message preventing the connector from being added
3. Remove the connector attempt — the agent should continue working with the allowed connectors only

---

## Step 6 — Publish to Microsoft Teams

### 6.1 Publish the Agent

1. In Copilot Studio, click **Publish** (top-right) → **Publish** → confirm in the dialog
2. Wait for the publish operation to complete — status shows **Published**

### 6.2 Add the Teams Channel

1. Click **Channels** (left sidebar) → **Microsoft Teams**
2. Click **Turn on Teams**
3. Confirm the channel is enabled — Copilot Studio registers a Teams App automatically

### 6.3 Scope Access via Teams App Policy

1. Go to the **Microsoft Teams Admin Center** (admin.teams.microsoft.com)
2. Navigate to **Teams apps** → **Setup policies**
3. Create a new policy named `copilot-lab-app-policy`
4. Under **Installed apps**, add the agent's Teams app
5. Assign the policy to a specific security group rather than to all users — apply least-privilege access to the agent
6. Click **Save**

### 6.4 Test in Teams

1. Open Microsoft Teams and search for the agent by name in the Apps section
2. Open the agent and send a test message — you should be prompted to sign in (Entra ID auth applies)
3. After sign-in, ask a question from your knowledge source and confirm a grounded response

---

## Step 7 — Monitor and Audit Agent Activity

### 7.1 Review Conversation Analytics

1. In Copilot Studio, click **Analytics** (left sidebar)
2. Review:
   - **Total sessions** — conversation volume over time
   - **Engagement rate** — sessions where the user sent at least two messages
   - **Resolution rate** — sessions where the agent answered without escalation
   - **Escalation rate** — sessions routed to a fallback or human handoff
3. Click into **Sessions** → open individual transcripts to review specific conversations

### 7.2 Check Purview Audit

1. Go to **Microsoft Purview** → **Audit** → **New search**
2. Set the date range to the last 24 hours
3. Under **Activities**, search for **Power Platform** and Copilot Studio activities
4. Confirm agent creation, publish events, and conversation session starts appear in the audit log

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
| --- | --- | --- |
| Agent returns generic answers without SharePoint citations | Knowledge source not indexed or out of scope | Re-index the knowledge source from the **Knowledge** panel; confirm the SharePoint site URL is correct and accessible |
| Authentication loop in the test panel | Redirect URI mismatch in app registration | Verify the redirect URI is exactly `https://token.botframework.com/.auth/web/redirect` |
| DLP policy blocks the agent from running | Knowledge source connector (SharePoint) classified as Non-Business | Move the SharePoint connector to the **Business** classification in the DLP policy |
| Agent not visible in Teams after publishing | Teams App Policy not assigned to the user | Assign the Teams App Setup Policy containing the agent to the user's security group in Teams Admin Center |
| Client secret error on authentication | Secret expired or copied incorrectly | Rotate the secret in the Entra app registration and update it in Copilot Studio Settings → Security → Authentication |
| "No Dataverse environment" error | Power Platform environment does not have Dataverse enabled | Recreate the environment with Dataverse enabled (cannot be added to an existing environment) |

---

## What I Learned

- **Grounding on specific libraries** — not whole sites — is the practical unit of knowledge management in Copilot Studio; over-indexing increases latency and reduces answer quality
- **Manual Entra ID auth** gives full visibility into the app registration, token claims, and secret rotation lifecycle — worth the extra steps over the simplified prebuilt option
- **DLP policies in Power Platform** operate at the connector level, not the content level — they control what the agent can _connect to_, not what it can _say_; content governance still depends on SharePoint permissions and sensitivity labels
- **Least-privilege Teams App Policies** prevent wide org-level rollout before the agent is validated — assign to a pilot group first, then expand
- The combination of **SharePoint permissions + Entra ID auth + Power Platform DLP** creates a three-layer governance model: you control _who_ can use the agent, _what_ data it can access, and _what services_ it can call

---

## Cleanup

1. In Copilot Studio, click **Settings** → **General** → **Delete agent** → confirm
2. In Power Platform Admin Center, go to **Environments** → select `env-copilot-lab` → **Delete** → confirm
3. In Azure Portal, go to **Entra ID** → **App registrations** → delete `copilot-studio-it-policy-agent`
4. In Teams Admin Center, remove the `copilot-lab-app-policy` setup policy

---

**Track:** [Copilot Studio](README.md)
**Related:** [Identity-First Track](../Identity-First/README.md) · [Microsoft 365 Track](../Microsoft%20365/README.md) · [Copilot for Security Track](../Copilot%20for%20Security/README.md)
