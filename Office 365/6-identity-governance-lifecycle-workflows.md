# Identity Governance Lab

## Lifecycle Workflows · Access Reviews · Entitlement Management · Automated Deprovisioning

---

## Summary

This lab automates user identity lifecycle and access governance using Entra ID Governance — entirely through the admin portal. You will create Lifecycle Workflows for joiner, mover, and leaver events; configure automated access reviews for admin roles, Teams, SharePoint, and apps; build entitlement management access packages with approval workflows; and implement a complete deprovisioning checklist.

**Estimated time:** 4–5 hours  
**License required:** Microsoft Entra ID Governance (add-on to Entra ID P2, or included in Entra Suite)  
**Portal used:** [Entra Admin Center](https://entra.microsoft.com) → **Identity governance**

---

## Table of Contents

1. [Lifecycle Workflows](#1-lifecycle-workflows)
2. [Access Reviews](#2-access-reviews)
3. [Entitlement Management](#3-entitlement-management)
4. [Automated Deprovisioning](#4-automated-deprovisioning)
5. [Validation](#5-validation)
6. [Next Steps](#6-next-steps)

---

## 1. Lifecycle Workflows

Lifecycle Workflows automate identity tasks at key moments in an employee's journey — removing manual burden from IT and ensuring consistent, auditable provisioning and deprovisioning.

### 1.1 How Lifecycle Workflows Trigger

Workflows fire automatically based on user attribute changes synced from your HR system (Workday, SAP, SuccessFactors, or via the Entra ID HR connector). Key attributes:

| Event | Trigger attribute |
| --- | --- |
| New hire joins | `employeeHireDate` — workflow runs N days before/after |
| Employee transfers | `department` or `jobTitle` attribute change |
| Employee leaves | `employeeLeaveDateTime` — workflow runs on or after leave date |

### 1.2 Joiner Workflow: New Employee Onboarding

1. **Entra Admin Center** → **Identity governance** → **Lifecycle workflows** → **+ Create workflow**
2. Select the **Onboard new hire** template → **Next**
3. Configure basics:

| Field | Value |
| --- | --- |
| Name | New Employee Onboarding |
| Description | Automates provisioning when a new employee joins |
| Trigger | Days before `employeeHireDate` |
| Days offset | **-2** (run 2 days before start date) |
| Scope | All users (or filter by department/group) |

1. Click **Next: Review tasks** — the template includes default tasks. Configure each:

#### Task 1: Send welcome email

| Field | Value |
| --- | --- |
| Task | Send welcome email |
| To | New employee's manager |
| CC | `it-helpdesk@yourdomain.com` |
| Custom subject | Welcome to the team! Your new account is ready. |
| Custom message | Include onboarding guide link and IT contacts |

#### Task 2: Add user to group

| Field | Value |
| --- | --- |
| Task | Add user to groups |
| Groups | Select the appropriate department security group |

#### Task 3: Generate Temporary Access Pass (TAP)

| Field | Value |
| --- | --- |
| Task | Generate Temporary Access Pass and send via email |
| TAP lifetime | 480 minutes (8 hours) |
| One-time use | ✅ Yes |
| Recipient | Manager (to hand to new employee on Day 1) |

> The TAP allows the new employee to sign in without a password and register their MFA methods (FIDO2, Authenticator) on Day 1.

1. Click **Next: Review** → **Create workflow**

### 1.3 Mover Workflow: Department Transfer

1. **Lifecycle workflows** → **+ Create workflow**
2. Select **Move between departments** template (or **Custom** if not available)
3. Configure:

| Field | Value |
| --- | --- |
| Name | Department Transfer |
| Description | Updates group membership when an employee changes departments |
| Trigger | Attribute change: `department` |

1. Add tasks:

#### Task 1: Remove from previous department group

| Field | Value |
| --- | --- |
| Task | Remove user from groups |
| Groups | Previous department security group |

#### Task 2: Add to new department group

| Field | Value |
| --- | --- |
| Task | Add user to groups |
| Groups | New department security group (note: dynamic group membership may handle this automatically if using Entra dynamic groups) |

#### Task 3: Notify manager and IT

| Field | Value |
| --- | --- |
| Task | Send email |
| To | Manager |
| CC | `it-helpdesk@yourdomain.com` |
| Subject | Department transfer: access update required |
| Message | Please review system access for the transferred employee within 5 business days. |

1. **Create workflow**

### 1.4 Leaver Workflow: Employee Offboarding

1. **Lifecycle workflows** → **+ Create workflow**
2. Select **Offboard an employee** template → **Next**
3. Configure:

| Field | Value |
| --- | --- |
| Name | Employee Offboarding |
| Description | Automates deprovisioning on employee departure |
| Trigger | Days after `employeeLeaveDateTime` |
| Days offset | **0** (on the leave date) |

1. Configure tasks:

#### Task 1: Disable account

| Field | Value |
| --- | --- |
| Task | Disable user account |
| (No additional config required) | Disables sign-in immediately |

#### Task 2: Revoke sessions

| Field | Value |
| --- | --- |
| Task | Revoke user sessions |
| (Invalidates all active tokens) | Immediate effect |

#### Task 3: Remove from all groups

| Field | Value |
| --- | --- |
| Task | Remove user from all groups |

#### Task 4: Remove licenses

| Field | Value |
| --- | --- |
| Task | Remove all licenses from user |

#### Task 5: Send offboarding notification

| Field | Value |
| --- | --- |
| Task | Send email |
| To | Manager |
| CC | `it-helpdesk@yourdomain.com`, `hr@yourdomain.com` |
| Subject | Employee departure: account access revoked |
| Message | The employee's account has been disabled and sessions revoked. Please complete the offboarding checklist within 24 hours. |

1. **Create workflow**

### 1.5 Activate and Schedule Workflows

For each workflow:

1. Open the workflow → **Properties**
2. Toggle **Is enabled** → **On**
3. Toggle **Is scheduling enabled** → **On**
4. Scheduling frequency: **Every hour** (or your preferred interval)
5. Click **Save**

---

## 2. Access Reviews

Access reviews are scheduled, automated reviews that prompt owners to confirm whether users still need their access. They are the primary control for preventing access creep over time.

All reviews are created at:
**Entra Admin Center** → **Identity governance** → **Access reviews** → **+ New access review**

### 2.1 Access Review: Admin Roles (Monthly)

1. **+ New access review**

| Field | Value |
| --- | --- |
| Review name | Monthly Admin Role Review |
| Start date | Today |
| Frequency | Monthly |
| Duration | 14 days |
| Review type | **Teams + groups** or **Azure AD roles** |
| Scope | All directory roles |
| Reviewers | Selected users: Security Admin or IT Manager |

1. **Settings:**

| Setting | Value |
| --- | --- |
| If reviewers don't respond | **Deny access** (auto-deny on no action) |
| At end of review, auto apply results | ✅ Yes |
| Require reviewer justification | ✅ Yes |
| Enable reviewer recommendations | ✅ Yes |
| Show last sign-in info | ✅ Yes |

1. Click **Start**

### 2.2 Access Review: Teams and Groups (Quarterly)

1. **+ New access review**

| Field | Value |
| --- | --- |
| Review name | Quarterly Teams & Group Membership Review |
| Frequency | Quarterly |
| Duration | 21 days |
| Review type | **Teams + groups** |
| Scope | Select **All Microsoft 365 groups with guest users** (or All groups) |
| Reviewers | **Group owners** |

1. Settings: same as above — auto-deny on no response, auto-apply results

2. Click **Start**

### 2.3 Access Review: Enterprise Applications (Semi-Annual)

1. **+ New access review**

| Field | Value |
| --- | --- |
| Review name | Semi-Annual Application Access Review |
| Frequency | Semi-annually (every 6 months) |
| Duration | 30 days |
| Review type | **Applications** |
| Scope | All applications (or select specific apps) |
| Reviewers | **Application owners** |

1. Settings: auto-deny on no response, auto-apply, require justification

2. Click **Start**

### 2.4 Reviewing Access as a Reviewer

Reviewers receive email notifications with a direct link. They can also go to:  
[myaccess.microsoft.com](https://myaccess.microsoft.com) → **Access reviews**

For each user listed, reviewers select **Approve** or **Deny**, provide justification if required, and submit. Results are applied automatically at the end of the review period.

---

## 3. Entitlement Management

Entitlement Management enables users to self-request access to bundles of resources (groups, apps, SharePoint sites) through an approval workflow with automatic expiration.

### 3.1 Create a Catalog

1. **Entra Admin Center** → **Identity governance** → **Entitlement management** → **Catalogs** → **+ New catalog**

| Field | Value |
| --- | --- |
| Name | Enterprise Access Catalog |
| Description | Centralized catalog for enterprise application and collaboration access packages |
| Enabled | ✅ Yes |
| Enabled for external users | ❌ No (internal only) |

1. Click **Create**

### 3.2 Add Resources to the Catalog

1. Open **Enterprise Access Catalog** → **Resources** → **+ Add resources**
2. Add each resource type:

| Resource | Type | Example |
| --- | --- | --- |
| sg-operations | Group | Operations security group |
| Operations SharePoint site | SharePoint site | `https://yourtenant.sharepoint.com/sites/Operations` |
| OPS-SD-Operations | Teams | Operations Team |
| Finance ERP app | Application | Add from enterprise apps list |

### 3.3 Create Access Package: Operations Team Access

1. **Entitlement management** → **Access packages** → **+ New access package**

**Basics:**

| Field | Value |
| --- | --- |
| Name | Operations Team Access |
| Description | Access to Operations SharePoint, Teams, and security group |
| Catalog | Enterprise Access Catalog |

**Resource roles:**

Add each resource and set the role:

| Resource | Role |
| --- | --- |
| sg-operations | Member |
| Operations SharePoint site | Member |
| OPS-SD-Operations (Teams) | Member |

**Requests:**

| Field | Value |
| --- | --- |
| Who can request | ✅ For users in your directory: All members and connected orgs |
| Require approval | ✅ Yes |
| First approver | **Requestor's manager** |
| Decision timeout | 14 days |
| Require approver justification | ✅ Yes |
| Alternative approver (if manager unavailable) | IT Manager |

**Lifecycle:**

| Field | Value |
| --- | --- |
| Access package assignments expire | After 1 year |
| Users can request specific timeline | ❌ No |
| Require access reviews | ✅ Yes → Quarterly → Reviewer: Requestor's manager |

Click **Create**

### 3.4 Create Access Package: Finance System Access

Repeat the process with stricter approval:

| Field | Value |
| --- | --- |
| Name | Finance System Access |
| Resources | sg-finance, Finance SharePoint site, Finance ERP app |
| Requestors | Only users in `sg-finance-eligible` group |
| Approval stages | Two-stage: Stage 1 = Manager; Stage 2 = Finance Director |
| Expiration | 90 days (must re-request) |
| Access reviews | Monthly, reviewed by Finance Director |

### 3.5 Requesting Access (User Experience)

Users can browse and request access packages at:  
[myaccess.microsoft.com](https://myaccess.microsoft.com) → **Access packages**

They complete a request form → manager receives an approval email → upon approval, access is automatically granted to all resources in the package.

---

## 4. Automated Deprovisioning

When an employee leaves, a precise and timely deprovisioning process is critical. The Leaver Lifecycle Workflow (Section 1.4) handles automated steps. The checklist below covers the complete process including manual steps that require human decision-making.

### 4.1 Deprovisioning Checklist

| # | Task | Method | Who | Timing |
| --- | --- | --- | --- | --- |
| 1 | Disable account | Lifecycle Workflow (automatic) | Automated | On leave date |
| 2 | Revoke all sessions | Lifecycle Workflow (automatic) | Automated | On leave date |
| 3 | Reset password | **Entra** → Users → Reset password | IT Admin | Day 0 |
| 4 | Remove from all groups | Lifecycle Workflow (automatic) | Automated | On leave date |
| 5 | Remove licenses | Lifecycle Workflow (automatic) | Automated | On leave date |
| 6 | Convert mailbox to shared | **Exchange Admin Center** → Mailboxes → Convert to shared | IT Admin | Day 1 |
| 7 | Set Out-of-Office | **Exchange Admin Center** → Mailboxes → Manage automatic replies | IT Admin | Day 1 |
| 8 | Transfer OneDrive | **SharePoint Admin Center** → Active sites → former employee's OneDrive → Settings → Transfer to manager | IT Admin | Day 5 |
| 9 | Confirm litigation hold | Review with Legal team | IT + Legal | Day 5 |
| 10 | Delete or retain account | Per records retention policy | IT | Day 30 |

### 4.2 Step-by-Step: Convert Mailbox to Shared

1. **Exchange Admin Center** → **Recipients** → **Mailboxes**
2. Select the former employee's mailbox
3. Click **Convert to shared mailbox** (in the right panel)
4. Confirm the conversion
5. Remove all Full Access permissions from the shared mailbox
6. Assign access only to the former employee's manager if inbox handover is needed

### 4.3 Step-by-Step: Set Out-of-Office Message

1. **Exchange Admin Center** → **Recipients** → **Mailboxes**
2. Select the former employee's mailbox → **Manage automatic replies**
3. Toggle **Automatic replies** → **On**
4. Internal message: *"This employee is no longer with the organization. Please contact [manager name] at [manager email]."*
5. External message: *"This employee is no longer with the organization. Please contact <info@yourdomain.com>."*
6. External audience: **Anyone outside my organization**
7. Click **Save**

### 4.4 Step-by-Step: Transfer OneDrive Ownership

1. **SharePoint Admin Center** → **More features** → **User profiles** → **Manage User Profiles**
2. Search for the former employee → **Manage site collection owners**
3. Add the manager as a **Site Collection Administrator**

Alternatively, use the automated approach:

1. **Microsoft 365 Admin Center** → **Users** → **Active users** (or Deleted users)
2. Select the former employee → **OneDrive** tab → **Get access to files**
3. A link to the OneDrive is provided → share with or transfer to the manager

### 4.5 Final Account Deletion

After the 30-day retention period (or confirmed by Legal):

1. **Entra Admin Center** → **Users** → **All users**
2. Verify the user is still disabled
3. Select the user → **Delete**
4. The account moves to **Deleted users** for 30 days before permanent deletion

To permanently delete immediately:

1. **Entra Admin Center** → **Users** → **Deleted users**
2. Select the user → **Delete permanently**
3. Confirm

---

## 5. Validation

| Test | How to Test | Expected Result |
| --- | --- | --- |
| Joiner workflow | Set `employeeHireDate` to 2 days from now on a test account | On trigger date: welcome email sent; group membership added; TAP generated |
| Mover workflow | Change `department` attribute on a test user in Entra | Old group removed; new group added; notification sent to manager |
| Leaver workflow | Set `employeeLeaveDateTime` to now on a test account | Account disabled; sessions revoked; groups removed; licenses removed |
| Admin access review | **Entra** → **Identity governance** → **Access reviews** | Review listed; reviewer received email notification |
| Group access review | As a group owner, open [myaccess.microsoft.com](https://myaccess.microsoft.com) → **Access reviews** | Members listed; Approve/Deny options visible |
| Access package request | As a regular user, go to [myaccess.microsoft.com](https://myaccess.microsoft.com) → **Access packages** | Operations Team Access package visible; request form works |
| Access package approval | Manager checks email for approval request | Approval email received; one-click approve works; access granted |
| Mailbox conversion | Open former employee's mailbox in Exchange Admin Center | Shows as Shared mailbox type |
| Out-of-Office | Send email to former employee from external address | Auto-reply received with offboarding message |
| OneDrive transfer | Manager navigates to `yourtenant-my.sharepoint.com/personal/...` | Manager listed as Site Collection Admin |

---

## 6. Next Steps

- [Lab 5: Zero Trust Advanced](5-zero-trust-advanced.md)
- [Lab 4: Compliance Automation](4-compliance-automation.md)

---

*This lab completes the Modern Workplace engineering track. You now have a fully governed, Zero Trust-secured, compliance-automated Microsoft 365 environment with automated identity lifecycle management — built and configured entirely through the Microsoft admin portals.*
