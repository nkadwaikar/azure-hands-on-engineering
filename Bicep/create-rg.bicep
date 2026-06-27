targetScope = 'subscription'
param rgName string = 'rg-identity-lab'
param location string = 'eastus'
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}
output rgName string = rg.name
output location string = rg.location
