param vmName string
param location string = resourceGroup().location
param adminUsername string

@secure()
param sshPublicKey string

param vmSize string = 'Standard_B2s'
param subnetId string
param uamiId string = ''
param tags object = {}

var nicName = '${vmName}-nic'

// No public IP attached — all inbound access must go through Azure Bastion or a private endpoint
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic' // No reserved static IP — reduces cost and admin overhead
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  // If uamiId supplied, attach pre-created UAMI for secretless access to Key Vault and Azure services
  // Fallback to SystemAssigned for standalone VMs where a UAMI hasn't been provisioned yet
  identity: !empty(uamiId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  } : {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        // Password auth disabled — SSH key is the only valid credential; eliminates brute-force attack surface
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        // Ubuntu 22.04 LTS Gen2 — UEFI + Secure Boot capable, supported until April 2027
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS' // Premium SSD — lower latency than Standard; required for production-grade IOPS
        }
        deleteOption: 'Delete' // OS disk deleted with VM — prevents orphaned disks accumulating cost
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete' // NIC deleted with VM — prevents orphaned NICs
          }
        }
      ]
    }
  }
}

output vmId string = vm.id
output vmPrincipalId string = empty(uamiId) ? vm.identity.principalId : ''
