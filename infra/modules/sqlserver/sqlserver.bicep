metadata description = 'Creates an Azure SQL Server instance.'
param name string = 'sqlx'
param location string = 'australiaeast'
param tags object = {}

//param appUser string = 'appUser'
//param databaseName string
//param keyVaultName string
param sqlAdmin string = 'sqlAdmin'
//param connectionStringKey string = 'AZURE-SQL-CONNECTION-STRING'

//param  virtualNetworkName string
//param  virtualNetworkSubNetName string

//param sqlVirtualNetworkSubnetId string

//@secure()
param sqlAdminPassword string = 'F6cEhD#kp@WR=Bf8+GqdY'


resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = {
  name: 'vnet-feddev/snet-feddev-sql'
  scope: resourceGroup('rg-feddev-network')
}

resource managedSqlInstance 'Microsoft.Sql/managedInstances@2024-05-01-preview' = {
  name: name
  tags: tags
  location: location
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
  }
  properties: {
    administratorLogin: sqlAdmin
    administratorLoginPassword: sqlAdminPassword
    subnetId: subnet.id
    storageSizeInGB: 32
    vCores: 4
  }
}

/*

resource sqlAdminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'sqlAdminPassword'
  properties: {
    value: sqlAdminPassword
  }
}

resource sqlAzureConnectionStringSercret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: connectionStringKey
  properties: {
    value: '${connectionString}; Password=${appUserPassword}'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

var connectionString = 'Server=${sqlServer.properties.fullyQualifiedDomainName}; Database=${sqlServer::database.name}; User=${appUser}'
output connectionStringKey string = connectionStringKey
output databaseName string = sqlServer::database.name
*/
