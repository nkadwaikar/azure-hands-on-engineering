# Microsoft Entra Backup & Recovery Lab Guide

A hands-on, portal-only lab covering Microsoft Entra Backup & Recovery difference reports, object-level recovery, and post-run cleanup using the current Entra admin experience.

Navigation: [Lab Index](../README.md)

Last validated on: 2026-06-19
Portal experience note: Steps validated against Microsoft Entra admin center UI as of June 2026; labels can vary slightly by tenant, licensing, and feature rollout.

> **Note:** Microsoft Entra Backup & Recovery is a Microsoft-managed service. This lab focuses on comparing recent directory state and restoring supported cloud-managed objects. Tenant-level backup schedule and retention controls are not configurable.

> **Preview note:** Because this capability is still evolving, some labels and delete options can vary by tenant during rollout.

---

## 1. Learning Objectives

By the end of this lab, you will:
- Understand how Microsoft Entra Backup & Recovery works
- Generate a difference report against a recent backup snapshot
- Filter the comparison to selected object types
- Review added, deleted, and modified directory objects
- Perform a recovery operation for supported cloud-managed objects
- Review and clean up difference reports and recovery history

---

## 2. Prerequisites

- Microsoft Entra tenant with Backup & Recovery available in the tenant experience
- Global Administrator or Privileged Role Administrator access for review and recovery actions
- Enough recent directory activity to make the difference report meaningful

Naming reference: [README Naming Convention](../README.md#naming-convention)

### Assumptions and Scope Boundaries

- Lab uses portal-only steps in the Microsoft Entra admin center.
- Microsoft-managed backup cadence is one automatic backup per day.
- Available backup history is limited to the most recent 5 daily snapshots.
- On-premises synchronized objects can appear in reports but are excluded from recovery.
- This lab does not cover licensing validation, long-term retention, or tenant-wide disaster recovery planning.

---

## 3. Service Behavior Overview

Microsoft Entra Backup & Recovery currently behaves as follows:

- One backup is taken automatically each day
- Backups are retained for the last 5 days
- Supported objects can include:
  - Users
  - Groups
  - Cloud-only devices
  - Applications
  - Service principals
  - Conditional Access policies
  - Authentication methods
  - Roles and assignments
  - Administrative units
- On-premises synchronized objects can be shown in reports but are not eligible for recovery
- Backup creation, retention, and deletion are Microsoft-managed and cannot be customized in the portal

---

## 4. Generate a Difference Report

A difference report compares the current state of your directory with one of the last 5 automatic backups. Use it to identify configuration drift, accidental changes, or unexpected access and policy updates.

### 4.1 Sign In to the Entra Admin Center

1. Open [https://entra.microsoft.com](https://entra.microsoft.com)
2. Sign in with a role that can access **Backup and recovery**

---

### 4.2 Open Backup and Recovery

1. In the left navigation pane, select **Microsoft Entra ID**
2. Select **Backup and recovery**
3. Confirm the page shows the service banner explaining daily backups and 5-day retention

---

### 4.3 Create the Report

1. Under **Difference reports**, select **Create difference report**
2. Wait for the configuration panel to open

---

### 4.4 Select Object Types

1. Select **Include only certain types of objects**
2. Choose all relevant object types shown in your tenant, such as:
   - Users
   - Groups
   - Devices
   - Applications
   - Service principals
   - Conditional Access policies
   - Authentication methods
   - Roles and assignments
   - Administrative units
3. Leave synchronized on-premises objects selected only if you want them included in the report output for review

> **Important:** Objects synchronized from on-premises Active Directory can appear in the report, but they are automatically excluded from recovery actions.

---

### 4.5 Generate and Review the Report

1. Select **Generate difference report**
2. Wait for the report to appear under **Difference reports**
3. Open the report and review entries for:
   - Added objects
   - Deleted objects
   - Modified objects
   - Policy changes
   - Application configuration changes
   - Role assignment changes

Expected outcome: you have a point-in-time view of recent directory drift across supported Entra object types.

---

### 4.6 Difference Reports Take Time to Run

Difference reports are not always generated immediately. In many tenants, the report can remain in a running or queued state for several minutes before results are available.

Keep the following in mind:

- Wait for the current difference report job to finish before starting another dependent action
- Review the report status in **Difference reports** until it shows as completed
- Do not assume the feature is stuck if the report does not appear instantly

> **Important:** You cannot start a recovery operation while a previous Backup & Recovery job is still in progress. Wait until the earlier job shows **Completed** or **Failed** before attempting recovery.

---

## 5. Perform a Recovery Operation

Recovery allows you to restore supported cloud-managed objects from one of the last 5 daily backup snapshots.

### 5.1 Open the Recovery Experience

1. Go to **Microsoft Entra ID** → **Backup and recovery**
2. Select **Recovery**

---

### 5.2 Choose a Backup Snapshot

1. Review the available daily backups
2. Select the snapshot you want to restore from
3. Confirm the selected date lines up with the change window you identified in the difference report

---

### 5.3 Select Object Types to Recover

1. Select **Include only certain types of objects**
2. Choose the object categories you want to restore, for example:
   - Users
   - Groups
   - Applications
   - Service principals
   - Roles
   - Conditional Access policies
   - Authentication methods
   - Cloud-only devices

> **Important:** On-premises synchronized objects are visible for review but cannot be recovered from this interface.

---

### 5.4 Start the Recovery

1. Review the selected backup and object scope carefully
2. Select **Recover**
3. Confirm the recovery operation when prompted

---

### 5.5 Monitor Recovery Status

1. Open **Recovery history**
2. Review job states such as:
   - In progress
   - Completed
   - Failed
3. Open job details to inspect logs for auditing and troubleshooting

Expected outcome: the recovery job completes successfully for supported cloud-managed objects, and detailed job history is available for validation.

---

## 6. Validation Checklist

Confirm the lab is complete when:

- A difference report is successfully generated and visible in **Difference reports**
- The report shows at least one object or policy delta you can explain
- A recovery job is submitted from a selected backup snapshot
- Recovery history shows a clear final status and job details
- You can identify which objects were recoverable versus excluded

---

## 7. Cleanup

For shared or repeatable lab environments, clear the generated report and recovery history entries from the UI.

### 7.1 Difference Report Deletion During Preview

During the current public preview of Microsoft Entra Backup & Recovery, **Difference reports** are still under active development. In many tenants, Microsoft has restricted deletion while backend retention and cleanup behavior is finalized for preview environments.

As a result:

- The **Delete** button may not appear
- The **Delete** button may be disabled
- Selecting **Delete** may not perform any action

This is expected preview behavior and does not indicate a tenant misconfiguration.

> **Reader note:** If you do not see the **Delete** option for **Difference reports**, this is not a tenant issue. Microsoft has restricted deletion during the preview rollout.

---

### 7.2 Delete Recovery History Entries

1. Go to **Backup and recovery** → **Recovery history**
2. Select the recovery job entries you want to remove from the view
3. Select **Delete**

You can typically delete:

- Recovery history entries
- Failed recovery jobs
- Incomplete recovery jobs

This cleanup removes recovery history entries from the interface. It does not remove Microsoft-managed backup snapshots.

---

## 8. Lessons Learned

1. Microsoft Entra Backup & Recovery is focused on short-retention, service-managed configuration recovery.
2. Difference reports are the fastest way to confirm recent directory drift before attempting recovery.
3. Recovery scope should be limited to the smallest relevant object set to reduce unintended rollback.
4. On-premises synchronized objects may appear in reporting but remain outside recovery scope.
5. Recovery history is important for auditability and post-change review.
6. Preview features can expose reporting before full lifecycle management actions, such as delete, are available.

---

## 9. Next Steps

- [Azure VM Backup](../Recovery%20Services%20vaults/1-VM%20Backup%20and%20Restore%20Procedure.md) — Extend the recovery theme into workload-level backup and restore
- [Azure Site Recovery](../Recovery%20Services%20vaults/2-Azure%20Site%20Recovery.md) — Compare configuration recovery with cross-region failover
- [Azure Monitor and Activity Logs](../Identity-First/06-azuremonitor-activity-logs.md) — Add audit visibility around directory and platform changes
