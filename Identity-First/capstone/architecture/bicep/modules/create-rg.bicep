// create-rg.bicep
// Module to create a resource group

param rgName string
param location string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

output rgName string = rg.name
output location string = rg.location
