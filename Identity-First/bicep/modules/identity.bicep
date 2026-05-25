param identityName string
resource namedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: resourceGroup().location
}
output identityId string = namedIdentity.id
output identityPrincipalId string = namedIdentity.properties.principalId
