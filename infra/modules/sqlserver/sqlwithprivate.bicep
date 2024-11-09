@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Server Database')
param databaseName string

@description('Administrator username for the SQL Server')
param sqlAdminUsername string

@description('Administrator password for the SQL Server')
@secure()
param sqlAdminPassword string

param tags object = {}

param virtualNetworkId string

param virtualNetworkSubNetId string

param location string


resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: sqlServerName
  location: location
  tags:tags
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Disabled' // Disable public access
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags:tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}


resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'

  resource dnsVnetLink 'virtualNetworkLinks' = {
      name: 'example-app-vnet'
      location: 'global'

      properties: {
          registrationEnabled: false // We do not need auto registration of virtual machines in this DNS zone.
          virtualNetwork: {
              id: virtualNetworkId
          }
      }
  }
}

resource sqlPrivateLink 'Microsoft.Network/privateEndpoints@2024-03-01' = {
  name: '${sqlServerName}-privateEndpoint'
  location: location

  properties: {
      subnet: {
          id: virtualNetworkSubNetId
      }
      customNetworkInterfaceName: '${sqlServerName}-privateEndpoint.nic'
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
