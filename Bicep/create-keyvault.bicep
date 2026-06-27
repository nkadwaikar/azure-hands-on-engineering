// create-keyvault.bicep
// Standalone module — creates Key Vault + inline RBAC assignment in a single call
// Use for quick standalone deployments or the capstone lab; main.bicep separates these into keyvault.bicep + rbac.bicep

param rgName string
param location string
param kvName string
param uamiPrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: kvName
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}

resource rbacAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, uamiPrincipalId, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: uamiPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output kvUri string = keyVault.properties.vaultUri
