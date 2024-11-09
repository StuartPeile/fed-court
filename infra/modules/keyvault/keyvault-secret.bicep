
@description('Name of the Key Vault')
param keyVaultName string

@description('Name of the secret to be added')
param secretName string

@description('Value of the secret to be added')
@secure()
param secretValue string

// Reference the existing Key Vault in the target resource group
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  parent:keyVault
  properties: {
    value: secretValue
  }
}

output secretId string = secret.id
