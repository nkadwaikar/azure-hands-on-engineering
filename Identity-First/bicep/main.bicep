param identityName string = 'wk1-uami'
param kvName string = 'wk1-kv'
param tenantId string = tenant().tenantId

module identity './modules/identity.bicep' = {
  name: 'identity'
  params: {
    identityName: identityName
  }
}

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    kvName: kvName
    tenantId: tenantId
  }
}

module rbac './modules/rbac.bicep' = {
  name: 'rbac'
  params: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b86a8fe4-44ce-4948-aee5-eccb2c155cd7' // Key Vault Secrets User
    )
    principalId: identity.outputs.identityPrincipalId
    targetResourceId: keyvault.outputs.kvId
  }
}

module lock './modules/locks.bicep' = {
  name: 'lock'
  params: {
    lockName: 'wk1-lock'
  }
}
