// diagnostics.bicep
// Configures Azure Monitor diagnostic settings for the Key Vault
// Routes AuditEvent logs and AllMetrics to a Log Analytics workspace

param kvName string
param workspaceId string
param diagnosticsName string = 'diag-${kvName}'

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticsName
  scope: kv
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        // AuditEvent captures all data-plane operations: secret reads, key usage, access denials
        // Required for compliance and incident investigation
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output diagnosticsId string = diagnostics.id
