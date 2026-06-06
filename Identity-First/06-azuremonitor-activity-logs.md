
# **Azure Monitor + Activity Logs**  
### *Observe, audit, and validate identity + governance operations across your environment.*

Today you add the **observability pillar** to your identity‑first, governance‑first Landing Zone.  
Azure Monitor and Activity Logs give you the visibility needed to track:

- RBAC changes  
- Policy Deny events  
- Lock operations  
- Resource deployments  
- Identity access attempts  
- Key Vault operations  
- VM lifecycle events  

This is how real cloud security teams validate governance in production.

# 🔧 **Prerequisites (Rebuild if Cleaned Up)**

If you cleaned up after Day 5, recreate:

- `rg-bootcamp` (unrestricted RG)  
- `rg-test-compliant` (policy‑restricted RG)  
- VM with system-assigned identity  
- Key Vault (optional for identity access logs)  
- Policy assignments:
  - Custom Audit Policy (RG tag audit)  
  - Allowed VM Size SKUs  

This ensures logs capture meaningful governance events.

---

# 🎯 **Learning Objectives**

By the end of this lab, you will:

- Enable Activity Logs and Diagnostic Settings  
- Create a Log Analytics Workspace  
- Route logs from RGs, VMs, Key Vault, and Policy  
- Query logs using KQL  
- Validate governance events (deny, audit, lock, RBAC)  
- Observe identity operations  
- Build a baseline observability layer for Landing Zones  

---

# 🧪 **Lab Steps**

---

# **1. Create a Log Analytics Workspace**

**Azure Portal → Log Analytics workspaces → Create**

- Name: `law-governance`  
- Resource Group: `rg-bootcamp`  
- Region: same as your resources  

This workspace will receive all logs.

---

# **2. Enable Activity Logs → Log Analytics**

**Azure Portal → Monitor → Activity Log → Diagnostic settings → Add**

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

# **3. Enable Diagnostic Settings on Resource Groups**

Do this for:

- `rg-bootcamp`  
- `rg-test-compliant`

**Resource Group → Diagnostic settings → Add**

Enable:

- Write  
- Delete  
- Action  
- Policy  

Send to: `law-governance`

---

# **4. Enable Diagnostic Settings on Key Vault (Optional but Recommended)**

**Key Vault → Diagnostic settings → Add**

Enable:

- AuditEvent  

Send to: `law-governance`

This captures identity access attempts.

---

# **5. Enable Diagnostic Settings on Virtual Machines**

**VM → Diagnostic settings → Add**

Enable:

- VMConnection  
- VMProtection  
- GuestActivity (if available)  

Send to: `law-governance`

---

# **6. Generate Governance Events to Observe**

Now create events that will appear in logs.

### **Event 1 — RBAC Change**
Assign Reader → Contributor → Reader again.

### **Event 2 — Lock Operation**
Add a Delete lock to a resource group, then remove it.

### **Event 3 — Policy Deny**
Try deploying a disallowed VM SKU in `rg-test-compliant`.

### **Event 4 — Audit Event**
Create a resource group without the required tag.

### **Event 5 — Identity Access**
From your VM’s managed identity:

- Try accessing Key Vault (allowed)  
- Try accessing Storage (denied)  

### **Event 6 — Resource Deployment**
Deploy a VM or storage account in `rg-bootcamp`.

These events will populate your logs.

---

# **7. Query Logs Using KQL**

Go to:

**Azure Portal → Monitor → Logs → law-governance**

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

# **8. Validate Observability Across Governance Layers**

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

# 🧹 **Cleanup (Optional)**

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

## 📌 Day 6 Summary

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

## ▶️ **Next Lab**

**Day 7 — Bicep Deployment: Identity Stack**  
`07-bicep-identity-stack.md`

---

## 🔗 **Related Labs**

- **Day 4 — Azure Locks + Resource Policies**  
  `04-locks-resource-policies.md`

- **Day 5 — Access Validation (Portal + CLI)**  
  `05-access-validation.md`