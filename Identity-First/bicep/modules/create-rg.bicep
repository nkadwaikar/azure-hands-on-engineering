targetScope = 'subscription'
param rgName string = 'rg-identity-lab'
param location string = 'eastus'
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}
