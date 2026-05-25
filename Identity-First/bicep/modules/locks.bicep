param lockName string
param lockLevel string = 'CanNotDelete'

resource resourceLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: lockName
  properties: {
    level: lockLevel
    notes: 'Lock created via Bicep module'
  }
}
output lockId string = resourceLock.id
