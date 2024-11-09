@description('Name of the Key Vault')
param keyVaultName string

@description('Principal ID (object ID) to be granted access to Key Vault')
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}

// Define the Role Assignment for Key Vault Secrets User
var roleId = '4633458b-17de-408a-b874-0445c86b69e6'
resource keyVaultSecretAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, roleId) // Unique name using Key Vault ID, principal ID, and role ID
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId) // Role ID for Key Vault Secrets User
    principalId: principalId
  }
}
