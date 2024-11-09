@description('Name of the Key Vault')
param keyVaultName string

@description('Principal ID (object ID) to be granted access to Key Vault')
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}

// Define the Role Assignment for Key Vault Secrets User
var roleId = 'b86a8fe8-9e37-4e8b-8d43-8ec9b81d0301'
resource keyVaultSecretAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, roleId) // Unique name using Key Vault ID, principal ID, and role ID
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId) // Role ID for Key Vault Secrets User
    principalId: principalId
  }
}
