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
