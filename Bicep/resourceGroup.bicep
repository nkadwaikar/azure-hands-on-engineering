// resourceGroup.bicep
// RG-scope orchestration module.
// Call from a subscription-scoped main.bicep using:
//   scope: resourceGroup(rgName)

param location string = resourceGroup().location
param uamiName string
param kvName string
param lockName string = '${kvName}-lock'
param tags object = {}

module identity './create-uami.bicep' = {
  name: 'deploy-uami'
  params: {
    rgName: resourceGroup().name
    location: location
    uamiName: uamiName
  }
}

module keyvault './keyvault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    kvName: kvName
    tenantId: subscription().tenantId
  }
}

// Key Vault Secrets User — read-only access to secret *values* only
// Scoped to the KV resource (not RG) for least-privilege: UAMI cannot manage, list, or delete secrets
var kvSecretsUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
)

module rbac './rbac.bicep' = {
  name: 'deploy-rbac'
  params: {
    principalId: identity.outputs.principalId
    roleDefinitionId: kvSecretsUserRoleId
    targetResourceId: keyvault.outputs.kvId
  }
}

module lock './locks.bicep' = {
  // CanNotDelete — prevents the RG and its resources from being deleted even by Owners
  // Locks override RBAC; must be removed explicitly before any teardown
  name: 'deploy-lock'
  params: {
    lockName: lockName
  }
}

output uamiPrincipalId string = identity.outputs.principalId
output uamiClientId string = identity.outputs.clientId
output kvId string = keyvault.outputs.kvId
