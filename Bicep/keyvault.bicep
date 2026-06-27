// keyvault.bicep
// Dependency module — used by main.bicep and resourceGroup.bicep; creates the KV resource only
// RBAC is assigned separately via rbac.bicep — use create-keyvault.bicep for an all-in-one standalone call

param kvName string
param tenantId string

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: kvName
  location: resourceGroup().location
  properties: {
    tenantId: tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

output kvId string = kv.id
