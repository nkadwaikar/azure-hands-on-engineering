
# Azure Monitor + Activity Logs

> **Why this matters:** A governance model without observability is untestable in production — this lab routes Activity Logs, Diagnostic Settings, and Key Vault audit events into a Log Analytics Workspace so every RBAC change, policy deny, lock operation, and identity access attempt is queryable and auditable.

Today you add the **observability pillar** to your identity-first, governance-first Landing Zone. Azure Monitor and Activity Logs give you the visibility needed to track RBAC changes, Policy Deny events, lock operations, resource deployments, identity access attempts, Key Vault operations, and VM lifecycle events.

This is how real cloud security teams validate governance in production.

Last validated on: 2026-06-25  
Portal experience note: Steps validated against Azure Portal as of June 2026; KQL schema field names may vary slightly by log category.

> **Note:** Log Analytics data ingestion is not instantaneous — allow 5–15 minutes after generating events before querying. Log Analytics Workspaces incur data ingestion charges; delete `law-governance` when the lab is complete.

---

## Quick Navigation

- [Prerequisites](#prerequisites)
- [Learning Objectives](#learning-objectives)
- [Create Log Analytics Workspace](#1-create-a-log-analytics-workspace)
- [Enable Activity Logs](#2-enable-activity-logs--log-analytics)
- [Diagnostic Settings — Resource Groups](#3-enable-diagnostic-settings-on-resource-groups)
- [Diagnostic Settings — Key Vault](#4-enable-diagnostic-settings-on-key-vault)
- [Diagnostic Settings — VMs](#5-enable-diagnostic-settings-on-virtual-machines)
- [Generate Governance Events](#6-generate-governance-events-to-observe)
- [Query Logs with KQL](#7-query-logs-using-kql)
- [Validate Observability](#8-validate-observability-across-governance-layers)
- [Cleanup](#cleanup)

---

## Prerequisites

If you cleaned up after Day 5, recreate:

- `rg-identity-eus-lab-core` (unrestricted RG)  
- `rg-test-compliant` (policy‑restricted RG)  
- VM with system-assigned identity  
- Key Vault (optional for identity access logs)  
- Policy assignments:
  - Custom Audit Policy (RG tag audit)  
  - Allowed VM Size SKUs  

This ensures logs capture meaningful governance events.

---

## Learning Objectives

By the end of this lab, you will have:

- Enable Activity Logs and Diagnostic Settings  
- Create a Log Analytics Workspace  
- Route logs from RGs, VMs, Key Vault, and Policy  
- Query logs using KQL  
- Validate governance events (deny, audit, lock, RBAC)  
- Observe identity operations  
- Build a baseline observability layer for Landing Zones  

---

---

## 1. Create a Log Analytics Workspace

### Azure Portal → Log Analytics workspaces → Create

- Name: `law-governance`  
- Resource Group: `rg-identity-eus-lab-core`  
- Region: same as your resources  

This workspace will receive all logs.

---

## 2. Enable Activity Logs → Log Analytics

### Azure Portal → Monitor → Activity Log → Diagnostic settings → Add

Configure:

- **Send to Log Analytics workspace**  
- Workspace: `law-governance`  
- Categories:
  - Administrative  
  - Policy  
  - Security  
  - Resource Health  
  - Service Health  

Save.

This ensures all subscription-level governance events are captured.

---

## 3. Enable Diagnostic Settings on Resource Groups

Do this for:

- `rg-identity-eus-lab-core`  
- `rg-test-compliant`

### Resource Group → Diagnostic settings → Add

Enable:

- Write  
- Delete  
- Action  
- Policy  

Send to: `law-governance`

---

## 4. Enable Diagnostic Settings on Key Vault

### Key Vault → Diagnostic settings → Add

Enable:

- AuditEvent  

Send to: `law-governance`

This captures identity access attempts.

---

## 5. Enable Diagnostic Settings on Virtual Machines

### VM → Diagnostic settings → Add

Enable:

- VMConnection  
- VMProtection  
- GuestActivity (if available)  

Send to: `law-governance`

---

## 6. Generate Governance Events to Observe

Now create events that will appear in logs.

### Event 1 — RBAC Change

Assign Reader → Contributor → Reader again.

### Event 2 — Lock Operation

Add a Delete lock to a resource group, then remove it.

### Event 3 — Policy Deny

Try deploying a disallowed VM SKU in `rg-test-compliant`.

### Event 4 — Audit Event

Create a resource group without the required tag.

### Event 5 — Identity Access

From your VM’s managed identity:

- Try accessing Key Vault (allowed)  
- Try accessing Storage (denied)  

### Event 6 — Resource Deployment

Deploy a VM or storage account in `rg-identity-eus-lab-core`.

These events will populate your logs.

---

## 7. Query Logs Using KQL

Go to:

### Azure Portal → Monitor → Logs → law-governance

---

## **Query 1 — List All Deny Events**

```kusto
AzureActivity
| where ActivityStatusValue == "Denied"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, ResourceGroup
| order by TimeGenerated desc
```

---

## **Query 2 — List RBAC Role Assignments**

```kusto
AzureActivity
| where OperationNameValue contains "role assignment"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue
| order by TimeGenerated desc
```

---

## **Query 3 — List Lock Operations**

```kusto
AzureActivity
| where OperationNameValue contains "locks"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue
| order by TimeGenerated desc
```

---

## **Query 4 — List Policy Evaluation Events**

```kusto
AzureActivity
| where CategoryValue == "Policy"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, ResourceGroup
| order by TimeGenerated desc
```

---

## **Query 5 — Key Vault Access Attempts**

```kusto
AzureDiagnostics
| where Category == "AuditEvent"
| project TimeGenerated, identity, operationName_s, resultDescription_s
| order by TimeGenerated desc
```

---

## 8. Validate Observability Across Governance Layers

### **RBAC**

- Role assignment events appear in Activity Logs.

### **Locks**

- Lock creation/deletion events appear in Activity Logs.

### **Policy**

- Deny events appear in Activity Logs.  
- Audit events appear in Policy Insights.

### **Identity**

- Key Vault access attempts appear in Diagnostic Logs.

### **Compute**

- VM lifecycle events appear in Activity Logs.

You now have a complete observability baseline.

---

## Cleanup

### **1. Remove Diagnostic Settings**

From RGs, VMs, Key Vault.

### **2. Delete Log Analytics Workspace**

`law-governance`

### **3. Delete Test Resource Groups**

- `rg-test-compliant`  
- `rg-audit-test`  
- `rg-audit-pass`  

### **4. Remove Policy Assignments**

- Custom Audit Policy  
- Allowed VM Size SKUs  

## Day 6 Summary

Today you learned:

- How to enable Activity Logs and Diagnostic Settings
- How to route logs to a Log Analytics Workspace
- How to query logs using KQL
- How to observe RBAC, lock, and policy events
- How to validate deny, audit, and identity access events
- How to build an observability layer for Landing Zones
- How to correlate governance events across services
- How to confirm your identity-first architecture is fully auditable

---

## Next Lab

**Day 7 — Bicep Deployment: Identity Stack**  
[07-bicep-deployment-identity-stack.md](07-bicep-deployment-identity-stack.md)

---

## Related Labs

- **Day 4 — Azure Locks + Resource Policies**  
  [04-azurelocks-resource-policies.md](04-azurelocks-resource-policies.md)

- **Day 5 — Access Validation (Portal + CLI)**  
  [05-access-validation.md](05-access-validation.md)
