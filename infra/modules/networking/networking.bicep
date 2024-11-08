@description('Name of the Virtual Network')
param name string

param location string

param tags object = {}

param environmentName string

var abbrs = loadJsonContent('../../abbreviations.json')



resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${abbrs.networkVirtualNetworksSubnets}${environmentName}-webapp'
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
        name: '${abbrs.networkVirtualNetworksSubnets}${environmentName}-sql'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'sqlDelegation'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
    ]
  }
  resource subNetWeb 'subnets' existing = {
    name: '${abbrs.networkVirtualNetworksSubnets}${environmentName}-webapp'
  }

  resource subNetSql 'subnets' existing = {
    name: '${abbrs.networkVirtualNetworksSubnets}${environmentName}-sql'
  }
}

output webAppVirtualNetworkSubnetId string = vnet::subNetWeb.id

output VirtualNetworkName string = vnet.name
output sqlVirtualNetworkSubnetName string = vnet::subNetSql.name
output sqlVirtualNetworkSubnetId string = vnet::subNetSql.id
