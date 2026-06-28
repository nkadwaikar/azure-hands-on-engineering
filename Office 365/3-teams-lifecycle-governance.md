# Teams Lifecycle Governance Lab

**Provisioning · Naming Policies · Templates · Channels · Expiration · Compliance**

---

## Summary

This lab builds a full Teams lifecycle governance model — from creation to deletion — using admin portals only. You will restrict Team creation to authorized users, enforce a naming convention, deploy Teams templates for consistent provisioning, configure channel architecture, set up expiration and archival policies, and integrate sensitivity labels and retention.

**Estimated time:** 3–4 hours  
**License required:** Microsoft 365 E3 or E5; Entra ID P1 for creation restriction  
**Portals used:**
- [Teams Admin Center](https://admin.teams.microsoft.com)
- [Entra Admin Center](https://entra.microsoft.com)
- [Microsoft Purview portal](https://compliance.microsoft.com)

---

## Table of Contents

1. [Teams Creation Governance](#1-teams-creation-governance)
2. [Naming Policies](#2-naming-policies)
3. [Templates](#3-templates)
4. [Channel Architecture](#4-channel-architecture)
5. [Lifecycle Management](#5-lifecycle-management)
6. [Compliance Integration](#6-compliance-integration)
7. [Validation](#7-validation)
8. [Next Steps](#8-next-steps)

---

## 1. Teams Creation Governance

By default, any licensed user can create a Team. In regulated environments this leads to sprawl, inconsistent naming, and ungoverned content. Restrict creation to approved groups first.

### 1.1 Create the Teams Provisioning Group

1. Go to **Entra Admin Center** → **Groups** → **All groups** → **+ New group**

| Field | Value |
|-------|-------|
| Group type | Security |
| Group name | Teams Provisioning |
| Description | Members of this group are authorized to create Microsoft Teams |
| Membership type | Assigned |

2. Click **Create**
3. Open the group → **Members** → **+ Add members**
4. Add authorized users: IT admins, Operations managers, Leadership PAs

### 1.2 Restrict Microsoft 365 Group Creation

> This setting restricts who can create Microsoft 365 Groups (which underpins Teams creation).

1. Go to **Entra Admin Center** → **Groups** → **General**
2. Under **Self service group management**:
   - **Users can create Microsoft 365 groups in Azure portals, API or PowerShell** → **No**
3. Under **Restrict user ability to create Microsoft 365 groups**:
   - Toggle **Restrict group creation** → **Yes**
   - **Group that can create Microsoft 365 groups** → select **Teams Provisioning**
4. Click **Save**

### 1.3 Provisioning Workflow

Communicate this process to the organization:

| Stage | Actor | Action | SLA |
|-------|-------|--------|-----|
| **Request** | Business user | Submit request via IT service portal: business purpose, Team type, initial owners | — |
| **Approval** | IT Manager | Review naming convention; approve or reject | 24 hours |
| **Creation** | IT Admin | Create Team using approved template | 4 hours |
| **Configuration** | IT Admin | Apply sensitivity label, channels, retention | 4 hours |
| **Handoff** | IT Admin | Notify owners; provide governance documentation | Day 1 |

---

## 2. Naming Policies

### 2.1 Naming Convention

**Format:** `Dept-Location-TeamName`

| Token | Example values |
|-------|---------------|
| Dept | OPS, PRJ, FIN, IT, HR, LEAD |
| Location | SD, LA, NY, REMOTE |
| TeamName | Short descriptive name (no spaces) |

**Examples:** `OPS-SD-Operations` · `PRJ-SD-ProjectAlpha` · `LEAD-NY-Leadership`

### 2.2 Configure Naming Policy in Entra

1. Go to **Entra Admin Center** → **Groups** → **Naming policy**
2. Click the **Group naming policy** tab
3. Under **Blocked words** → enter each word on a new line:
   ```
   Internal
   Test
   Temp
   Delete
   Old
   Pilot
   ```
4. Click **Save**

**Configure prefix/suffix (attribute-based):**

1. On the same **Naming policy** page → **Group naming policy** tab
2. Click **+ Add prefix** → select **Attribute** → choose **Department**
3. Click **+ Add prefix** → select **String** → type `-`
4. This prepends the user's Department attribute to every Group name automatically

> Note: The full `Dept-Location-TeamName` convention is enforced through your provisioning workflow and template names, since the Location token is not a standard Entra attribute.

---

## 3. Templates

Teams templates ensure every Team launches with a consistent set of channels, tabs, and apps — eliminating manual setup.

### 3.1 Create Templates in Teams Admin Center

1. Go to **Teams Admin Center** → **Teams** → **Team templates** → **+ Add**

**Template 1: Operations Team**

| Field | Value |
|-------|-------|
| Template name | Operations Team |
| Short description | Standard template for operational departments |
| Locale | English (United States) |

Channels to add (click **+ Add** for each):

| Channel name | Type | Set as favorite |
|-------------|------|-----------------|
| Announcements | Standard | ✅ Yes |
| Projects | Standard | ✅ Yes |
| Incidents | Standard | No |
| Resources | Standard | No |

Apps to pre-install: **Planner**, **SharePoint** (point to Operations site), **OneNote**

Click **Submit**

**Template 2: Projects Team**

| Channel | Type | Favorite |
|---------|------|----------|
| Announcements | Standard | ✅ Yes |
| Planning | Standard | ✅ Yes |
| Deliverables | Standard | No |
| Risks & Issues | Standard | No |
| Finance | Private | No |

Apps: **Planner**, **SharePoint** (Projects site), **Forms**

**Template 3: Leadership Team**

| Channel | Type | Favorite |
|---------|------|----------|
| Executive Updates | Standard | ✅ Yes |
| Strategy | Private | No |
| Finance | Private | No |
| HR Matters | Private | No |

Apps: **SharePoint** (Leadership site), **Power BI**

### 3.2 Create a Team from a Template

1. Go to **Teams Admin Center** → **Teams** → **Manage teams** → **+ Add**
2. Select **From a template**
3. Choose the appropriate template
4. Fill in Team name (following your naming convention), description, and owners
5. Click **Apply**

---

## 4. Channel Architecture

### 4.1 Standard Channels

Standard channels are visible to all Team members.

| Channel | Purpose | Who posts |
|---------|---------|-----------|
| General | Default; system messages | All members |
| Announcements | Official updates only | Owners only (moderated) |
| Projects | Active project coordination | All members |

**Set Announcements as owner-only posting:**

1. Open the Team in **Teams** (as an owner)
2. Click **...** next to **Announcements** → **Manage channel**
3. Under **Channel moderation** → toggle **On**
4. Set **Who can post messages?** → **Only owners can post new messages**
5. Set **Team members can reply to posts** → ✅ On
6. Click **Save**

### 4.2 Private Channels

Private channels are visible only to explicitly added members — use them for confidential content within a Team.

**Create a private channel:**

1. In the Team, click **+ Add channel** (or **...** → **Add channel**)
2. Channel name: `Finance`
3. Privacy: **Private — Specific teammates have access**
4. Click **Create**
5. Add specific members only (finance leads, not all Team members)

> Private channels have their own SharePoint site collection. Apply retention policies separately to private channel sites.

---

## 5. Lifecycle Management

### 5.1 Teams Expiration Policy

The expiration policy automatically prompts Team owners to renew. If no action is taken, the Team is deleted — preventing accumulation of inactive Teams.

1. Go to **Entra Admin Center** → **Groups** → **Expiration**
2. Configure:

| Setting | Value |
|---------|-------|
| Group lifetime (in days) | **180** |
| Email contact for groups with no owners | `it-helpdesk@yourdomain.com` |
| Enable expiration for these Microsoft 365 groups | **All** |

3. Click **Save**

> Team owners receive email reminders at 30, 15, and 1 day before expiration. Renewing resets the 180-day clock.

### 5.2 Archive a Team

Archiving makes the Team read-only and removes it from the active Teams list while preserving all content.

**When to archive:** Project complete, team disbanded, but content must be retained.

1. Go to **Teams Admin Center** → **Teams** → **Manage teams**
2. Select the Team to archive
3. Click **Archive** in the top ribbon
4. ✅ Check **Make the SharePoint site read-only for team members**
5. Click **Archive**

**Archival checklist:**

- [ ] Notify all Team members 5 business days in advance
- [ ] Export Teams wiki content if needed
- [ ] Confirm SharePoint site retention policy is active
- [ ] Transfer outstanding Planner tasks to an active Team
- [ ] Archive the Team
- [ ] Notify business owner and log in your CMDB

### 5.3 Delete a Team

> Deletion is irreversible after the 30-day soft-delete recovery window.

1. **Teams Admin Center** → **Teams** → **Manage teams**
2. Select the Team → **Delete**
3. Confirm the deletion

**To recover within 30 days:**

1. Go to **Microsoft 365 Admin Center** → **Active teams & groups** → **Deleted groups**
2. Select the group → **Restore group**

**Deletion checklist:**

- [ ] Confirm no active litigation holds on Team content
- [ ] Export content if required by records policy
- [ ] Obtain written approval from business owner
- [ ] Delete Team
- [ ] Document: date, approver, reason

---

## 6. Compliance Integration

### 6.1 Apply Sensitivity Labels to Teams

Sensitivity labels control Teams privacy (Public/Private), guest access, and device access settings.

**Prerequisite:** Sensitivity labels must be enabled for Microsoft 365 Groups in Purview.

1. Go to **Microsoft Purview portal** → **Information protection** → **Labels**
2. Select the **Internal** label → **Edit label** → **Groups & sites** scope
3. Enable:
   - ✅ Privacy and external user access settings
   - **Privacy:** Private
   - ✅ Block external sharing
4. Save

**Apply the label when creating a Team:**

1. When provisioning a Team (Teams Admin Center or Teams client), the sensitivity label selector appears
2. Choose **Internal** for most Teams; **Confidential** for sensitive projects

### 6.2 Retention Policies for Teams

1. Go to **Microsoft Purview portal** → **Data lifecycle management** → **Microsoft 365** → **Retention policies** → **+ New retention policy**

| Field | Value |
|-------|-------|
| Name | Teams Retention Policy - 3 Years |
| Description | Retains Teams channel messages and chats for 3 years |

2. **Locations** — toggle on:
   - ✅ **Teams channel messages** — All teams
   - ✅ **Teams chats** — All users

3. **Retention settings:**
   - Retain items for **3 years**
   - At end of period: **Do nothing** (or Delete, per your policy)

4. Submit

> Teams files are stored in SharePoint — apply the SharePoint retention policy from Lab 2 to cover file content.

---

## 7. Validation

| Test | How to Test | Expected Result |
|------|-------------|-----------------|
| Creation restriction | Sign in as non-provisioning user → try to create a Team | Option unavailable or permission error |
| Naming policy | Try to create a Team with a blocked word (e.g., "Test") | Creation fails with policy violation message |
| Template | Create Team using Operations template | Channels pre-created; apps pinned |
| Private channel | Member added only to Finance private channel | Can see Finance; cannot see other channels |
| Expiration | **Entra Admin Center** → **Groups** → **Expiration** | 180-day policy shows for All groups |
| Archive | Archive a test Team | Team moves to Archived section; all content read-only |
| Retention | **Purview** → **Retention policies** | Teams policy active; status: On |
| Sensitivity label | Create Team → apply Internal label | Privacy = Private; guest access blocked |

---

## 8. Next Steps

- [Lab 4: Compliance Automation](4-compliance-automation.md)
- [Lab 6: Identity Governance](6-identity-governance-lifecycle-workflows.md)
