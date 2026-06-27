param lockName string

@allowed(['CanNotDelete', 'ReadOnly'])
param lockLevel string = 'CanNotDelete'

param notes string = 'Managed by IaC — do not remove without approval.'

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: lockName
  properties: {
    level: lockLevel
    notes: notes
  }
}

output lockId string = lock.id
