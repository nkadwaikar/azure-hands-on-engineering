# Azure Front Door — Static Website Hosting Track

Last validated on: July 2026

This track covers global static website delivery through Azure Front Door — origin configuration, routing rules, caching behaviour, and WAF at the edge.

## Track Structure

```text
Azure Front Door-Static Website Hosting/
`-- 1-azure-front-door-static-website-hosting.md
```

## Lab Sequence

1. [Azure Front Door + Static Website Hosting Lab](1-azure-front-door-static-website-hosting.md) — deploy a static site on Azure Storage, publish it through a Front Door Standard/Premium endpoint, and validate caching and routing

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
