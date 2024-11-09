@description('Enter managed instance name.')
param managedInstanceName string = 'sqlfed'

@description('Enter user name.')
param administratorLogin string = 'sqladmin'

@description('Enter password.')
@secure()
param administratorLoginPassword string

@description('Enter location. If you leave this field blank resource group location would be used.')
param location string = 'australiaeast'

@description('Enter sku name.')
param skuName string = 'GP_Gen5'

@description('Enter number of vCores.')
param vCores int = 4

@description('Enter storage size.')
param storageSizeInGB int = 32

@description('Enter license type.')
param licenseType string = 'LicenseIncluded'

param databaseName string = 'projectmanager'

param tags object = {}

param virtualNetworkSubNetId string

resource managedInstance 'Microsoft.Sql/managedInstances@2021-11-01-preview' = {
  name: managedInstanceName
  location: location
  tags:tags
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    subnetId:  virtualNetworkSubNetId
    storageSizeInGB: storageSizeInGB
    vCores: vCores
    licenseType: licenseType
  }
}

resource sqlDatabase 'Microsoft.Sql/managedInstances/databases@2021-11-01' = {
  name: databaseName
  parent: managedInstance
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

output sqlManagedInstanceFqdn string = managedInstance.properties.fullyQualifiedDomainName
output databaseId string = sqlDatabase.id
