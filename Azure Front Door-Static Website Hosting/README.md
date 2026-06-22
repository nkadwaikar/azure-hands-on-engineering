# Azure Front Door — Static Website Hosting Track

This track covers global static website delivery through Azure Front Door — origin configuration, routing rules, caching behaviour, and WAF at the edge.

## Track Structure

```text
Azure Front Door-Static Website Hosting/
`-- Azure Front Door-Static Website Hosting Lab.md
```

## Lab Sequence

1. [Azure Front Door + Static Website Hosting Lab](Azure%20Front%20Door-Static%20Website%20Hosting%20Lab.md) — deploy a static site on Azure Storage, publish it through a Front Door Standard/Premium endpoint, and validate caching and routing

## What it covers

- Azure Storage static website hosting (`$web` container)
- Front Door endpoint, origin group, and route configuration
- Cache behaviour validation (`TCP_MISS`, `TCP_HIT`, `CONFIG_NOCACHE`)
- Propagation troubleshooting with `curl`

## Prerequisites

- Azure subscription with Contributor rights
- Azure Portal access
- Basic familiarity with Azure Storage and blob containers

---

[← Back to Azure Hands-On Engineering](../README.md)
