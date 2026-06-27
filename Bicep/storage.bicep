param storageAccountName string
param location string = resourceGroup().location

@allowed(['Standard_LRS', 'Standard_ZRS', 'Standard_GRS', 'Standard_RAGRS', 'Standard_GZRS', 'Standard_RAGZRS'])
param skuName string = 'Standard_LRS'

param tags object = {}

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    accessTier: 'Hot'
    // Prevents anonymous public read — required for any account that could hold sensitive data
    allowBlobPublicAccess: false
    // TLS 1.0/1.1 are deprecated and vulnerable to POODLE/BEAST; 1.2 is the minimum safe version
    minimumTlsVersion: 'TLS1_2'
    // Rejects plain HTTP entirely; all traffic must traverse an encrypted channel
    supportsHttpsTrafficOnly: true
    // Shared Key auth bypasses RBAC, cannot be scoped per-identity, and cannot be audited
    // Disabling it forces all access through Entra ID RBAC — consistent with identity-first design
    allowSharedKeyAccess: false
  }
}

output storageAccountId string = sa.id
output storageAccountName string = sa.name
