
# Azure Front Door + Static Website Hosting Lab

> **Why this matters:** Without an edge layer, a storage-hosted site has no DDoS protection, no global caching, and no clean custom domain — this lab puts Azure Front Door in front of a static website so the origin endpoint is never directly reachable by clients.

## Module / Track Structure

```text
Azure Front Door-Static Website Hosting/
├── README.md                          ← Track entry point
└── 1-azure-front-door-static-website-hosting.md ← Lab 1: CDN + Static Hosting (you are here)
```

This module is a focused single-lab walkthrough for global static website delivery through Azure Front Door.

Last validated on: 2026-06-19
Portal experience note: Steps validated against Azure Portal as of June 2026; Front Door propagation typically takes 5–15 minutes after configuration changes.

> **Note:** Azure Front Door Standard/Premium incurs hourly and data transfer charges. The origin storage static website endpoint remains accessible directly unless locked down with Private Link — origin lock-down is out of scope for this lab.

---

## Quick Navigation

- [Lab Overview](#1-lab-overview)
- [Learning Objectives](#2-learning-objectives)
- [Environment Setup](#3-environment-setup)
- [Front Door Configuration](#4-configure-azure-front-door-portal-aligned)
- [Validation and Troubleshooting](#5-validation--troubleshooting)
- [Lessons Learned](#6-lessons-learned)
- [Cleanup](#7-cleanup)

## 1. Lab Overview

### Architecture Flow

```text
Client → Azure Front Door Endpoint → Origin Group → Static Website Endpoint → $web Container → index.html
```

---

## 2. Learning Objectives

By the end of this lab, you will have:

- A **static website** hosted on Azure Blob Storage with a public `$web` container
- An **Azure Front Door Standard/Premium** profile with an origin group pointing to the storage endpoint
- A **route** and **endpoint** configured so all client traffic enters through Front Door
- Cache behavior validated by inspecting `X-Cache` headers (`TCP_MISS` on first hit, `TCP_HIT` on repeat)
- Experience troubleshooting Front Door propagation delays and `CONFIG_NOCACHE` responses

---

## 3. Environment Setup

### 2.1 Create a Resource Group

Create a new resource group dedicated to this lab.
This ensures:

- Clean isolation of resources
- Easier cleanup
- Accurate cost tracking

**Steps:**

1. In Azure Portal, search **Resource groups** → **+ Create**
2. Configure:
   - **Subscription:** your lab subscription
   - **Resource group name:** `rg-afd-eus-lab-web`
   - **Region:** East US
3. Click **Review + Create** → **Create**

---

### 2.2 Create a Storage Account and Enable Static Website

**Create the storage account:**

1. Search **Storage accounts** → **+ Create**
2. Configure:
   - **Subscription:** your lab subscription
   - **Resource group:** `rg-afd-eus-lab-web`
   - **Storage account name:** `stafdeuslab01` *(must be globally unique — adjust as needed)*
   - **Region:** East US
   - **Performance:** Standard
   - **Redundancy:** Locally redundant storage (LRS)
3. Leave remaining defaults → **Review + Create** → **Create**

**Enable static website hosting:**

1. Open `stafdeuslab01`
2. In the left menu, go to **Data management → Static website**
3. Set **Static website** to **Enabled**
4. Configure:
   - **Index document name:** `index.html`
   - **Error document path:** *(leave blank for this lab)*
5. Click **Save**

Azure creates the `$web` container automatically. Your static website endpoint will look like:

```url
https://stafdeuslab01.zXX.web.core.windows.net/
```

Copy this URL — you will use it as the **Origin hostname** in Front Door.

---

### 2.3 Upload Website Content

1. Navigate to **Containers → `$web`**
2. Upload `index.html` into the root of the `$web` container
3. Verify:
   - File name is **exactly** `index.html`
   - Blob type is **Block blob**
   - File size matches your intended content

### Test the origin directly

```bash
curl -I https://<storage-account>.zXX.web.core.windows.net/
```

Expected:

```http
HTTP/1.1 200 OK
```

---

## 4. Configure Azure Front Door (Portal-Aligned)

### 3.1 Create Front Door Profile (with Endpoint, Origin, and Route)

Using **Custom Create**, Azure guides you through configuring all major components during setup.

#### Profile Details

- **Name:** Choose a descriptive name
- **Tier:** Standard or Premium
- **Resource group location:** e.g., East US 2

---

#### Endpoint Settings

- **Endpoint name:** Choose a unique name
- Azure generates:

  ```text
  <endpoint-name>.z01.azurefd.net
  ```

---

#### Origin Settings

- **Origin type:** Storage (Static website)
- **Origin host name:**
  Use the storage account's actual static website hostname:

  ```text
  <storage-account>.zXX.web.core.windows.net
  ```

- **Origin host header:** Same as hostname
- **HTTPS port:** 443
- **Health probe:** Default settings

---

#### Caching and Compression

- **Enable caching:** Yes
- **Query string caching behavior:** Ignore Query String
- **Enable compression:** Optional

---

#### Route Configuration

Configure the route during creation:

| Setting               | Value                            |
|-----------------------|----------------------------------|
| Enable route          | Yes                              |
| Domains               | Select your Front Door endpoint  |
| Patterns to match     | `/*`                             |
| Accepted protocols    | HTTP and HTTPS                   |
| Redirect to HTTPS     | Enabled                          |
| Origin group          | Select the created origin group  |
| Origin path           | Leave empty                      |
| Forwarding protocol   | **HTTPS only**                   |
| Caching               | Enabled                          |
| Query string behavior | Ignore Query String              |
| Compression           | Optional                         |

#### Why “HTTPS only” is required

Azure Storage Static Website Hosting should be reached over HTTPS from Front Door.
Keep the route's forwarding protocol set to HTTPS only so the origin is always contacted securely.

---

#### Review + Create

- Click **Review + Create**
- Ensure validation passes
- Deploy the Front Door profile

Azure provisions:

- Front Door profile
- Endpoint
- Origin group
- Origin
- Route

---

### 3.2 Post‑Deployment Configuration Update

After deployment, update the **origin group health probe** for accuracy.

#### Updated Health Probe Settings

| Setting    | Value       |
|------------|-------------|
| Probe Path | `/*`        |
| Protocol   | HTTPS       |
| Method     | HEAD        |
| Interval   | 100 seconds |

#### Why this matters

- Ensures the probe checks the root of your static site
- Matches the origin’s HTTPS endpoint
- Keeps the origin in a **Healthy** state

---

### 3.3 Validate Route Settings

Confirm the route settings match:

- Patterns to match: `/*`
- Redirect to HTTPS: Enabled
- Forwarding protocol: **HTTPS only**
- Caching: Enabled
- Query string behavior: Ignore Query String
- Origin path: Empty

---

### 3.4 Purge Front Door Cache

After deploying Azure Front Door and configuring the route, purge the cache to ensure that no stale configuration or content is served by edge nodes.

#### Steps

- Navigate to **Caching → Purge** in the Azure Front Door portal.
- Purge the pattern:

  ```text
  /*
  ```

This forces all POPs (Points of Presence) to refresh their cached configuration and content.

---

## 5. Validation & Troubleshooting

### 4.1 Initial Behavior: 404 with `CONFIG_NOCACHE`

When testing the Front Door endpoint immediately after deployment:

```bash
curl -I https://<frontdoor-endpoint>.z01.azurefd.net/
```

You may observe:

```text
HTTP/2 404
x-cache: CONFIG_NOCACHE
```

#### Meaning

- Azure Front Door’s global edge POPs **have not yet received the route configuration**.
- This is a **propagation delay**, not a misconfiguration.

Testing `/index.html`:

```bash
curl -I https://<frontdoor-endpoint>.z01.azurefd.net/index.html
```

Produces the same result, confirming the route has not propagated.

---

### 4.2 Configuration Verification

Verify the following to ensure the configuration is correct:

- The static website endpoint returns **200 OK**.
- The `$web` container contains `index.html`.
- The route is **enabled** and provisioning state is **Succeeded**.
- The domain is correctly associated with the endpoint.
- The forwarding protocol is set to **HTTPS only**.
- The origin group is properly linked.
- No origin path is set.
- No private endpoints or firewalls are blocking traffic.

#### Conclusion

The configuration is correct.
The 404 `CONFIG_NOCACHE` response is caused by **propagation delay**, not an error.

---

### 4.3 Propagation Completion

After waiting and periodically testing, you will eventually receive:

```http
HTTP/2 200
content-length: <size>
x-cache: TCP_MISS
```

#### Interpretation

- The route is now active.
- The origin is serving content.
- Azure Front Door is delivering the static website globally.
- `TCP_MISS` indicates the first request fetched content from the origin.
- Subsequent requests will return `TCP_HIT` once cached at the edge.

---

## 6. Lessons Learned

1. `CONFIG_NOCACHE` indicates no active route at the edge.
2. This is caused by propagation delay, not misconfiguration.
3. Always validate the origin independently.
4. If the static website endpoint returns **200 OK**, the storage configuration is correct.
5. Forwarding protocol must match the origin.
6. Static website endpoints require **HTTPS**.
7. Leave **Origin Path** empty for static websites.
8. Static website hosting automatically maps `/` → `/index.html`.
9. Propagation delays can be longer than expected.
10. After multiple edits, purges, or recreations, Front Door may enter a lengthy global sync.
11. Do not modify settings during propagation.
12. Once the configuration is correct, wait for propagation to complete.
13. Response headers provide valuable insight:
    - `CONFIG_NOCACHE` → No route has propagated.
    - `TCP_MISS` → Route active; content fetched from origin.
    - `TCP_HIT` → Content cached at the edge.
14. Costs remain predictable.
15. Propagation delays and 404 errors do **not** generate data transfer charges.

---

## 7. Cleanup

Delete resources in this order to avoid dependency errors.

### Step 1 — Delete the Front Door Profile

1. Go to **Azure Portal** → search **Front Door and CDN profiles**
2. Select `fd-afd-eus-lab-web`
3. Click **Delete** → confirm deletion

> **Note:** Deleting the Front Door profile also removes all associated endpoints, origin groups, origins, and routes.

### Step 2 — Delete the Resource Group

Deleting the resource group removes the storage account, the `$web` container, and all blobs in one step.

1. Go to **Resource groups**
2. Select `rg-afd-eus-lab-web`
3. Click **Delete resource group**
4. Type the resource group name to confirm → **Delete**

### Expected post-cleanup state

| Resource | Expected state |
| --- | --- |
| Front Door profile | Deleted |
| Storage account `stafdeuslab01` | Deleted (inside the resource group) |
| `$web` container and blobs | Deleted |
| Resource group `rg-afd-eus-lab-web` | Deleted |

---

[← Back to Azure Hands-On Engineering](../README.md)
