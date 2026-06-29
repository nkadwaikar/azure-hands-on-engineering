# SharePoint Information Architecture Lab

## Metadata · Content Types · Hub Sites · Permissions · Retention Governance

---

## Summary

This lab builds a scalable, governed SharePoint Online information architecture entirely through the admin portals. You will create a hub site topology, design a metadata and content type taxonomy, implement a least-privilege permissions model, configure external sharing governance, and apply Purview retention labels.

**Estimated time:** 3–4 hours  
**License required:** Microsoft 365 E3 or E5  
**Portals used:**

- [SharePoint Admin Center](https://tenant-admin.sharepoint.com)
- [Microsoft Purview portal](https://compliance.microsoft.com)
- SharePoint site settings (accessed from each site)

---

## Table of Contents

1. [Site Architecture](#1-site-architecture)
2. [Metadata & Content Types](#2-metadata--content-types)
3. [Permissions Model](#3-permissions-model)
4. [External Sharing Governance](#4-external-sharing-governance)
5. [Retention & Compliance](#5-retention--compliance)
6. [Validation](#6-validation)
7. [Next Steps](#7-next-steps)

---

## 1. Site Architecture

### 1.1 Architecture Design

The hub site model groups related sites for consistent navigation, search scope, and policy inheritance — without the complexity of traditional subsite nesting.

**Target architecture:**

```txt
Intranet (Communication Site — company home page)

Operations Hub (Hub Site)
    ├── Operations (Team Site)
    ├── Projects (Team Site)
    └── Leadership (Team Site)
```

### 1.2 Create the Intranet Communication Site

1. Go to **SharePoint Admin Center** → **Sites** → **Active sites** → **+ Create**
2. Select **Communication site**

| Field | Value |
| --- | --- |
| Site name | Intranet |
| Site address | `/sites/Intranet` |
| Primary admin | your admin account |
| Language | English |

1. Click **Finish**

### 1.3 Create the Operations Hub Site

1. **Active sites** → **+ Create** → **Communication site**

| Field | Value |
| --- | --- |
| Site name | Operations Hub |
| Site address | `/sites/OperationsHub` |

1. After creation, select **Operations Hub** in the site list
2. Click **Hub** in the top ribbon → **Register as hub site**
3. Hub site name: `Operations Hub`
4. Click **Save**

### 1.4 Create Team Sites

Repeat **+ Create** → **Team site** for each:

| Site name | Address | Primary admin |
| --- | --- | --- |
| Operations | `/sites/Operations` | IT admin |
| Projects | `/sites/Projects` | IT admin |
| Leadership | `/sites/Leadership` | IT admin |

### 1.5 Associate Team Sites to the Hub

For each team site:

1. Select the site in **Active sites**
2. Click **Hub** → **Associate with a hub**
3. Select **Operations Hub**
4. Click **Save**

**Verify:** Each team site should now show `Operations Hub` in the **Hub** column of the Active sites list.

---

## 2. Metadata & Content Types

A consistent metadata taxonomy enables classification, filtering, managed search, and automatic retention policy application across all documents.

### 2.1 Create Site Columns in the Content Type Hub

The Content Type Hub publishes columns and content types to all site collections in your tenant.

1. Go to **SharePoint Admin Center** → **Content services** → **Content type gallery**
2. Click **Create content type** (you will add columns first via an existing content type, or create them at the site level and promote)

### Alternative: Create site columns directly on the Operations Hub site

1. Navigate to `https://yourtenant.sharepoint.com/sites/OperationsHub`
2. Go to **Site settings** (gear icon) → **Site columns** → **Create**

Create each column:

#### Column 1: Department

| Field | Value |
| --- | --- |
| Column name | Department |
| Type | Choice |
| Choices (one per line) | Operations, Finance, Legal, IT, Leadership, HR, Projects |
| Group | Enterprise Metadata |

#### Column 2: Project ID

| Field | Value |
| --- | --- |
| Column name | Project ID |
| Type | Single line of text |
| Group | Enterprise Metadata |

#### Column 3: Document Category

| Field | Value |
| --- | --- |
| Column name | Document Category |
| Type | Choice |
| Choices | Policy, Procedure, Report, Contract, Invoice, Proposal, Reference |
| Group | Enterprise Metadata |

#### Column 4: Retention Label

| Field | Value |
| --- | --- |
| Column name | Retention Label |
| Type | Choice |
| Choices | 1 Year, 3 Year, 7 Year, Permanent |
| Group | Enterprise Metadata |

### 2.2 Create Content Types

1. Go to **Site settings** → **Site content types** → **Create**

#### Content Type 1: Project Document

| Field | Value |
| --- | --- |
| Name | Project Document |
| Parent content type group | Document Content Types |
| Parent content type | Document |
| Group | Enterprise Content Types |

After creation, open **Project Document** → **Add from existing site columns** → add:

- Department
- Project ID
- Document Category
- Retention Label

#### Content Type 2: Policy Document

Same process — add: Department, Document Category, Retention Label

#### Content Type 3: Finance Document

Same process — add: Department, Document Category, Retention Label

### 2.3 Apply Content Types to Document Libraries

For each team site (Operations, Projects, Leadership):

1. Navigate to the site → open the **Documents** library
2. Click **Settings** (gear) → **Library settings** → **Advanced settings**
3. Set **Allow management of content types** → **Yes** → **OK**
4. Back in Library settings → **Content types** section → **Add from existing site content types**
5. Add: Project Document, Policy Document, Finance Document
6. Set **Project Document** as the default content type

---

## 3. Permissions Model

### 3.1 Design Principles

| Principle | Implementation |
| --- | --- |
| Use SharePoint groups | Never assign permissions to individual users |
| Group-based membership | Add Entra security groups to SharePoint groups |
| Least privilege | Visitors = Read; Members = Edit; Owners = Full Control |
| No broken inheritance | Document any inheritance break; review quarterly |

### 3.2 Configure Site Permissions

**Intranet site — read-only for all staff:**

1. Navigate to `https://yourtenant.sharepoint.com/sites/Intranet`
2. Go to **Settings** → **Site permissions**
3. Click **Advanced permissions settings**
4. Open **Intranet Visitors** group → **Add users** → add `Everyone except external users`
5. Open **Intranet Members** group → add your Communications team security group
6. Open **Intranet Owners** group → add IT Admins security group

**Operations site — department access:**

1. Navigate to the Operations site → **Settings** → **Site permissions** → **Advanced permissions settings**
2. Open **Operations Members** → **Add users** → add `sg-operations@yourdomain.com` (Entra security group)
3. Open **Operations Owners** → add `sg-itadmins@yourdomain.com`

**Leadership site — restricted access:**

1. Navigate to the Leadership site → **Settings** → **Site permissions** → **Advanced permissions settings**
2. Click **Stop inheriting permissions** (breaks inheritance from hub)
3. Clear all existing inherited permission groups
4. Manually add:
   - Leadership staff security group → **Members** (Edit)
   - IT Admins security group → **Owners** (Full Control)
5. Do **not** add a Visitors group — no read-only access by default

---

## 4. External Sharing Governance

### 4.1 Tenant-Level Sharing Settings

1. Go to **SharePoint Admin Center** → **Policies** → **Sharing**
2. Configure:

| Setting | Value |
| --- | --- |
| SharePoint external sharing | **Existing guests only** |
| OneDrive external sharing | **Existing guests only** |
| Default sharing link type | **Only people in your organization** |
| Default link permission | **View** |
| Allow guests to share items they don't own | ❌ Off |
| Guest access expires automatically | ✅ On |
| Guest access expires after | **180 days** |
| People who use a verification code must reauthenticate after | **30 days** |

1. Expand **More external sharing settings**:
   - ✅ Guests must sign in using the same account to which sharing invitations are sent
   - ✅ Allow only users in specific security groups to share externally → add `sg-approved-external-sharers`

2. Click **Save**

### 4.2 Site-Level Sharing Settings

**Disable external sharing for sensitive sites:**

1. **SharePoint Admin Center** → **Active sites**
2. Select **Leadership** → click **Sharing** in the top ribbon
3. Set to **Only people in your organization** → **Save**
4. Repeat for any Finance or HR sites

**Allow existing guests only for general sites:**

1. Select **Operations** → **Sharing** → **Existing guests** → **Save**

---

## 5. Retention & Compliance

### 5.1 Create Retention Labels

1. Go to **Microsoft Purview portal** → **Data lifecycle management** → **Microsoft 365** → **Labels** → **+ Create a label**

Create four labels:

#### Label 1: Retain 1 Year

| Field | Value |
| ------- | ------- |
| Name | Retain 1 Year |
| Retain items for | 1 year |
| At end of retention period | Delete items automatically |
| Start retention based on | When items were last modified |

**Label 2: Retain 3 Years** — same settings, 3 years

**Label 3: Retain 7 Years** — same settings, 7 years

#### Label 4: Permanent

| Field | Value |
| ------- | ------- |
| Name | Permanent |
| Retain items for | 100 years |
| At end of retention period | Do nothing |

### 5.2 Publish Retention Labels

1. **Data lifecycle management** → **Label policies** → **+ Publish labels**
2. **Choose labels to publish** → add all four labels
3. **Locations** → select:
   - ✅ SharePoint sites — All sites
   - ✅ OneDrive accounts — All accounts
4. Name the policy: `SharePoint Retention Label Policy`
5. Review and submit

> Labels become available to users in document libraries within 1–7 days of publishing.

### 5.3 Create an Auto-Apply Retention Policy

Automatically applies the **Retain 7 Years** label to Finance Documents without requiring user action.

1. **Data lifecycle management** → **Label policies** → **+ Auto-apply a label**
2. **Label to auto-apply:** Retain 7 Years
3. **Conditions:** Apply label to content that contains specific words or sensitive info types
   - Select **Apply label to content that contains specific words or phrases**
   - Add: `invoice, purchase order, contract, financial statement`
4. **Locations:**
   - SharePoint sites → select the Operations site URL
5. Name: `Auto-Apply Retain 7 Years - Finance Content`
6. Submit

---

## 6. Validation

| Test | How to Test | Expected Result |
| --- | --- | --- |
| Hub association | SharePoint Admin Center → Active sites → Hub column | Team sites show **Operations Hub** |
| Site columns | Open a document library on Operations site → + Add column | Department, Project ID, Document Category available to add |
| Content types | Upload a doc to Operations Documents library | Content type selector visible (Project Document, Policy Document, Finance Document) |
| Permissions | Sign in as a member of sg-operations; navigate to Leadership site | Access denied |
| External sharing | Try to share a Leadership site document externally | Option unavailable or greyed out |
| Retention labels | Open a document → right-click → **More** → **Apply label** | Retain 1 Year, 3 Year, 7 Year, Permanent visible |
| Metadata views | Create a view filtered by Department | View filters correctly by department value |

---

## 7. Next Steps

- [Lab 3: Teams Lifecycle Governance](3-teams-lifecycle-governance.md)
- [Lab 4: Compliance Automation](4-compliance-automation.md)
