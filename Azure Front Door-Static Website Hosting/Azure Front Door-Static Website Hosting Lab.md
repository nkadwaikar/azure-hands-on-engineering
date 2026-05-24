
# **Azure Front Door + Static Website Hosting Lab**

## **1. Lab Overview**

### **Objective**
Deploy a static website using **Azure Storage Static Website Hosting** and publish it globally through **Azure Front Door (Standard/Premium)**.  
This lab covers:

- Static website hostingå  
- Front Door endpoint, origin, and route configuration  
- Validation using `curl`  
- Caching behavior  
- Troubleshooting propagation delays (`CONFIG_NOCACHE`, `TCP_MISS`, `TCP_HIT`)  

### **Architecture Flow**
```
Client → Azure Front Door Endpoint → Origin Group → Static Website Endpoint → $web Container → index.html
```

---

# **2. Environment Setup**

## **2.1 Create a Resource Group**
Create a new resource group dedicated to this lab.  
This ensures:

- Clean isolation of resources  
- Easier cleanup  
- Accurate cost tracking  

---

## **2.2 Create a Storage Account and Enable Static Website**

- Create a **Storage Account** in any region  
- **LRS** redundancy is sufficient for lab purposes  

### Enable Static Website:
- Go to **Static Website**  
- Enable the feature  
- Set:
  - **Index document:** `index.html`
  - **Error document:** optional  

Example static website endpoint:
```
https://<storage-account>.z13.web.core.windows.net/
```

---

## **2.3 Upload Website Content**

1. Navigate to **Containers → `$web`**  
2. Upload `index.html` into the root of the `$web` container  
3. Verify:
   - File name is **exactly** `index.html`  
   - Blob type is **Block blob**  
   - File size matches your intended content  

### Test the origin directly:
```bash
curl -I https://<storage-account>.z13.web.core.windows.net/
```

Expected:
```
HTTP/1.1 200 OK
```

---

# **3. Configure Azure Front Door (Portal‑Aligned)**

## **3.1 Create Front Door Profile (with Endpoint, Origin, and Route)**

Using **Custom Create**, Azure prompts you to configure all major components during setup.

### **Profile Details**
- **Name:** Choose a descriptive name  
- **Tier:** Standard or Premium  
- **Resource group location:** e.g., East US 2  

---

### **Endpoint Settings**
- **Endpoint name:** Choose a unique name  
- Azure generates:
  ```
  <endpoint-name>.z01.azurefd.net
  ```

---

### **Origin Settings**
- **Origin type:** Storage (Static website)  
- **Origin host name:**  
  ```
  <storage-account>.z13.web.core.windows.net
  ```
- **Origin host header:** Same as hostname  
- **HTTPS port:** 443  
- **Health probe:** Default settings  

---

### **Caching and Compression**
- **Enable caching:** Yes  
- **Query string caching behavior:** Ignore Query String  
- **Enable compression:** Optional  

---

### **Route Configuration**
Configure the route during creation:

| Setting               | Value                            |
|----------------------|----------------------------------|
| Enable route         | Yes                              |
| Domains              | Select your Front Door endpoint  |
| Patterns to match    | `/*`                             |
| Accepted protocols   | HTTP and HTTPS                   |
| Redirect to HTTPS    | Enabled                          |
| Origin group         | Select the created origin group  |
| Origin path          | Leave empty                      |
| Forwarding protocol  | **HTTPS only**                   |
| Caching              | Enabled                          |
| Query string behavior| Ignore Query String              |
| Compression          | Optional                         |

### **Why “HTTPS only” is required**
Azure Storage Static Website Hosting **only supports HTTPS**.  
Forwarding HTTP would cause origin failures.

---

### **Review + Create**
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

## **3.2 Post‑Deployment Configuration Update**

After deployment, update the **origin group health probe** for accuracy.

### **Updated Health Probe Settings**

| Setting         | Value        |
|----------------|--------------|
| Probe Path     | `/*`         |
| Protocol       | HTTPS        |
| Method         | HEAD         |
| Interval       | 100 seconds  |

### **Why this matters**
- Ensures the probe checks the root of your static site  
- Matches the origin’s HTTPS endpoint  
- Keeps the origin in a **Healthy** state  

---

## **3.3 Validate Route Settings**

Confirm the route settings match:

- Patterns to match: `/*`  
- Redirect to HTTPS: Enabled  
- Forwarding protocol: **HTTPS only**  
- Caching: Enabled  
- Query string behavior: Ignore Query String  
- Origin path: Empty  

---

# **3.4 Purge Front Door Cache**

After deploying Azure Front Door and configuring the route, purge the cache to ensure that no stale configuration or content is served by edge nodes.

### **Steps**
- Navigate to **Caching → Purge** in the Azure Front Door portal.
- Purge the pattern:
  ```
  /*
  ```

This forces all POPs (Points of Presence) to refresh their cached configuration and content.

---

# **4. Validation & Troubleshooting**

## **4.1 Initial Behavior: 404 with `CONFIG_NOCACHE`**

When testing the Front Door endpoint immediately after deployment:

```bash
curl -I https://<frontdoor-endpoint>.z01.azurefd.net/
```

You may observe:

```
HTTP/2 404
x-cache: CONFIG_NOCACHE
```

### **Meaning**
- Azure Front Door’s global edge POPs **have not yet received the route configuration**.
- This is a **propagation delay**, not a misconfiguration.

Testing `/index.html`:

```bash
curl -I https://<frontdoor-endpoint>.z01.azurefd.net/index.html
```

Produces the same result, confirming the route has not propagated.

---

## **4.2 Configuration Verification**

Verify the following to ensure the configuration is correct:

- The static website endpoint returns **200 OK**.  
- The `$web` container contains `index.html`.  
- The route is **enabled** and provisioning state is **Succeeded**.  
- The domain is correctly associated with the endpoint.  
- The forwarding protocol is set to **HTTPS only**.  
- The origin group is properly linked.  
- No origin path is set.  
- No private endpoints or firewalls are blocking traffic.  

### **Conclusion**
The configuration is correct.  
The 404 `CONFIG_NOCACHE` response is caused by **propagation delay**, not an error.

---

## **4.3 Propagation Completion**

After waiting and periodically testing:

```bash
curl -I https://<frontdoor-endpoint>.z01.azurefd.net/
```

You will eventually receive:

```
HTTP/2 200
content-length: <size>
x-cache: TCP_MISS
```

### **Meaning**
- The route is now active.  
- The origin is serving content.  
- Azure Front Door is delivering the static website globally.  
- `TCP_MISS` indicates the first request fetched content from the origin.  
- Subsequent requests will return `TCP_HIT` once cached at the edge.  

---

# **5. Lessons Learned**

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
