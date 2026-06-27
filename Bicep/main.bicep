param identityName string = 'wk1-uami'
param kvName string = 'wk1-kv'
param tenantId string = tenant().tenantId
param workspaceId string

module identity './create-uami.bicep' = {
  name: 'identity'
  params: {
    rgName: resourceGroup().name
    location: resourceGroup().location
    uamiName: identityName
  }
}

module keyvault './keyvault.bicep' = {
  name: 'keyvault'
  params: {
    kvName: kvName
    tenantId: tenantId
  }
}

module rbac './rbac.bicep' = {
  name: 'rbac'
  params: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    principalId: identity.outputs.principalId
    targetResourceId: keyvault.outputs.kvId
  }
}

module lock './locks.bicep' = {
  name: 'lock'
  params: {
    lockName: 'wk1-lock'
  }
}

module diagnostics './diagnostics.bicep' = {
  name: 'diagnostics'
  params: {
    kvName: kvName
    workspaceId: workspaceId
  }
}
