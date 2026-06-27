// create-uami.bicep
// Module to create a User Assigned Managed Identity

param rgName string
param location string
param uamiName string

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}

output principalId string = uami.properties.principalId
output clientId string = uami.properties.clientId
