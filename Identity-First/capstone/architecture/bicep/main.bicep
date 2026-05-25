// main.bicep
// Entry point for deploying the identity-first architecture stack

module createRg 'modules/create-rg.bicep' = {
  name: 'createResourceGroup'
  params: {
    rgName: 'rg-identity-capstone'
    location: 'eastus'
  }
}

module uami 'modules/create-uami.bicep' = {
  name: 'createUserAssignedManagedIdentity'
  params: {
    rgName: createRg.outputs.rgName
    location: createRg.outputs.location
    uamiName: 'wk1-uami'
  }
}

module keyVault 'modules/create-keyvault.bicep' = {
  name: 'createKeyVault'
  params: {
    rgName: createRg.outputs.rgName
    location: createRg.outputs.location
    kvName: 'wk1-kv'
    uamiPrincipalId: uami.outputs.principalId
  }
}
