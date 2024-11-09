@description('Name of the SQL Server')
param sqlServerName string = 'mySqlServer'

@description('Name of the SQL Server Database')
param databaseName string = 'fedproductivity'

@description('Administrator username for the SQL Server')
param sqlAdminUsername string

@description('Administrator password for the SQL Server')
@secure()
param sqlAdminPassword string

@description('Name of the Virtual Network for the Private Endpoint')
param vnetName string

@description('Name of the subnet for the Private Endpoint')
param subnetName string

@description('Azure Region')
param location string = resourceGroup().location

var abbrs = loadJsonContent('../../abbreviations.json')

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${vnetName}-${abbrs.networkVirtualNetworksSubnets}-webapp'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'webAppDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: '${vnetName}-${abbrs.networkVirtualNetworksSubnets}-sql'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
  resource sqlSubnet 'subnets' existing = {
      name: '${vnetName}-${abbrs.networkVirtualNetworksSubnets}-sql'
  }
}


resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Disabled' // Disable public access
  }
}

/*
resource database 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: databaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: databaseName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 104857600
    sampleName: 'AdventureWorksLT'
  }
  dependsOn: [
    sqlServer
  ]
}
*/

resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'

  resource dnsVnetLink 'virtualNetworkLinks' = {
      name: 'example-app-vnet'
      location: 'global'

      properties: {
          registrationEnabled: false // We do not need auto registration of virtual machines in this DNS zone.
          virtualNetwork: {
              id: vnet.id
          }
      }
  }
}

resource sqlPrivateLink 'Microsoft.Network/privateEndpoints@2024-03-01' = {
  name: '${sqlServerName}-privateEndpoint'
  location: location

  properties: {
      subnet: {
          id: vnet::sqlSubnet.id
      }
      privateLinkServiceConnections: [
          {
              name: '${sqlServerName}-privateEndpoint'
              properties: {
                  // Plug your SQL Server id here
                  privateLinkServiceId: sqlServer.id

                  groupIds: [
                      'sqlServer'
                  ]
              }
          }
      ]
  }
  resource dns 'privateDnsZoneGroups' = {
      name: 'default'
      properties: {
          privateDnsZoneConfigs: [
              {
                  name: 'privatelink-database-windows-net'
                  properties: {
                      privateDnsZoneId: sqlPrivateDnsZone.id
                  }
              }
          ]
      }
  }
}


output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output privateEndpointId string = sqlPrivateLink.id

//nameresolver myendpointsql.database.windows.net
