param identityName string
resource namedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: resourceGroup().location
}
output identityId string = namedIdentity.id
output identityPrincipalId string = namedIdentity.properties.principalId
