#!/usr/bin/env bash
set -euo pipefail

echo "Renaming lab files to lowercase kebab-case..."

git mv "Azure Update Manager/1-Azure_Update_Manager.md" \
       "Azure Update Manager/1-azure-update-manager.md"

git mv "Azure Update Manager/2-Azure_Update_Advance_Topics.md" \
       "Azure Update Manager/2-azure-update-advanced-topics.md"

git mv "Compute/3-Install IIS.md" \
       "Compute/3-install-iis.md"

git mv "Deploying a Domain Controller in Azure/1-DeployingDomain Controller in Azure.md" \
       "Deploying a Domain Controller in Azure/1-deploying-domain-controller-in-azure.md"

git mv "Identity-First/01-identity fundamentals.md" \
       "Identity-First/01-identity-fundamentals.md"

git mv "Identity-First/02-managed Identity + Azure Key Vault (Secretless Authentication).md" \
       "Identity-First/02-managed-identity-keyvault-secretless-auth.md"

git mv "Microsoft Entra Backup & Recovery/1-Microsoft Entra Backup & Recovery.md" \
       "Microsoft Entra Backup & Recovery/1-microsoft-entra-backup-recovery.md"

git mv "Recovery Services vaults/1-VM Backup and Restore Procedure.md" \
       "Recovery Services vaults/1-vm-backup-restore.md"

git mv "Recovery Services vaults/2-Azure Site Recovery.md" \
       "Recovery Services vaults/2-azure-site-recovery.md"

git mv "Recovery Services vaults/3-Azure storage replication.md" \
       "Recovery Services vaults/3-azure-storage-replication.md"

git mv "Secure Break‑Glass Accounts/2-Certificate-Based Authentication(CBA)for Emergency Access Accounts.md" \
       "Secure Break‑Glass Accounts/2-certificate-based-auth-cba.md"

git mv "Azure Arc Hybrid Server Architecture/1-Azure Arc Hybrid Server Architecture.md" \
       "Azure Arc Hybrid Server Architecture/1-azure-arc-hybrid-server-architecture.md"

git mv "Azure Arc Hybrid Server Architecture/2-On-Prem Hyper-V Lab Setup for Azure Arc.md" \
       "Azure Arc Hybrid Server Architecture/2-on-prem-hyperv-lab-setup-for-azure-arc.md"

git mv "Azure Bastion/1-Azure Bastion.md" \
       "Azure Bastion/1-azure-bastion.md"

git mv "Azure Front Door-Static Website Hosting/1-Azure Front Door-Static Website Hosting Lab.md" \
       "Azure Front Door-Static Website Hosting/1-azure-front-door-static-website-hosting.md"

git mv "Azure Policy Auto‑Remediation/1-Azure Policy Auto‑Remediation.md" \
       "Azure Policy Auto‑Remediation/1-azure-policy-auto-remediation.md"

git mv "App Service + Managed Identity + Deployment Slots + Azure DevOps/App Service + Managed Identity + Deployment Slots + Azure DevOps.md" \
       "App Service + Managed Identity + Deployment Slots + Azure DevOps/1-app-service-managed-identity-deployment-slots.md"

git mv "Defender for Servers/1-Defender-for-Servers.md" \
       "Defender for Servers/1-defender-for-servers.md"

git mv "Defender for Servers/2-JIT.md" \
       "Defender for Servers/2-jit.md"

echo ""
echo "Done. Review staged renames:"
echo "  git diff --cached --name-status"
