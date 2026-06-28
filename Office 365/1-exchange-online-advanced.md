# Exchange Online Advanced Lab

Enterprise Mail Flow • Transport Rules • Threat Protection • Governance

## Summary

This lab builds an enterprise-grade Exchange Online foundation with secure mail flow, transport rules, journaling, anti-phishing, and mailbox governance.

## Table of Contents

1. Mail Flow Architecture
2. Transport Rules
3. Journaling & Archiving
4. Threat Protection
5. Shared Mailbox Governance
6. Validation
7. Next Steps

---

## 1. Mail Flow Architecture

### 1.1 Validate DNS

- Check MX
- Check SPF
- Enable DKIM
- Publish DMARC policy

### 1.2 Document Mail Flow

Diagram recommended:  
Inbound → EOP → Exchange Online  
Outbound → EOP → Internet

---

## 2. Transport Rules (Enterprise Set)

### Create Rules

- Block external auto-forwarding
- Add external recipient disclaimer
- Redirect phishing reports
- Encrypt mail with sensitivity labels
- Block high-risk file types

---

## 3. Journaling & Archiving

### Journaling

- Create journaling mailbox
- Configure journaling rule

### Retention

- Create retention tags
- Create retention policies
- Apply to mailboxes

### Litigation Hold

Enable litigation hold for:

- Executives
- Finance
- Legal
- Security

---

## 4. Threat Protection

### Safe Links

- Enable for email
- Enable for Teams
- Enable for Office apps

### Safe Attachments

- Enable dynamic delivery
- Enable sandboxing

### Anti-Phishing

- Enable mailbox intelligence
- Enable spoof intelligence

---

## 5. Shared Mailbox Governance

### Create Shared Mailboxes

- support@
- finance@
- projects@

### Assign Access

Use groups, not individuals.

### Lifecycle

Document:

- Creation
- Usage
- Archival
- Deletion

---

## 6. Validation

- Send test mail
- Validate transport rules
- Validate Safe Links
- Validate Safe Attachments
- Validate journaling

---

## 7. Next Steps

- [Compliance Automation](4-compliance-automation.md)
- [Zero Trust Advanced](5-zero-trust-advanced.md)
