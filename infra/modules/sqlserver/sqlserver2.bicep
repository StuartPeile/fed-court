@description('Name of the SQL Managed Instance')
param sqlManagedInstanceName string = 'mysql'

@description('Administrator username for the SQL Managed Instance')
param sqlAdminUsername string = 'sqlAdmin'

@description('Administrator password for the SQL Managed Instance')
@secure()
param sqlAdminPassword string = 'F6cEhD#kp@WR=Bf8+GqdY'

@description('Name of the existing Virtual Network')
param vnetName string = 'vnet-feddev'

@description('Name of the existing subnet for the SQL Managed Instance')
param subnetName string = 'snet-feddev-sql'

@description('Azure Region')
param location string = 'australiaeast'

@description('SKU for the SQL Managed Instance')
param skuName string = 'GP_Gen5' // General Purpose Gen5

@description('Compute generation for the SQL Managed Instance')
param vCores int = 4

@description('Storage size in GB for the SQL Managed Instance')
param storageSizeInGB int = 32

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = {
  name: 'vnet-feddev/snet-feddev-sql'
  scope: resourceGroup('rg-feddev-network')
}


var subnex = resourceId('rg-feddev-network','Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)


output subNetName string = subnet.id

output subNetNameX string = subnex



resource sqlManagedInstance 'Microsoft.Sql/managedInstances@2021-11-01' = {
  name: sqlManagedInstanceName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    subnetId: resourceId('rg-feddev-network','Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    storageSizeInGB: storageSizeInGB
    vCores: vCores
  }
  sku: {
    name: skuName
    tier: 'GeneralPurpose'
  }
}

