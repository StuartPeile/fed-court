targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

var uniqueID = substring(uniqueString(subscription().id),0,4)

var resourceGroupName = '${abbrs.resourcesResourceGroups}${environmentName}'

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

var networkingName = '${abbrs.networkVirtualNetworks}${environmentName}'
module networking 'modules/networking/networking.bicep' = {
  name: networkingName
  scope: resourceGroup
  params: {
    name: networkingName
    tags: tags
    location: location
    environmentName: environmentName
  }
}

var sqlNetworkingName = 'sqlnetworking'
module sqlNetworking 'modules/networking/sqlserver-networking.bicep' = {
  scope: resourceGroup
  name: sqlNetworkingName
  dependsOn:[networking]
  params: {
    managedInstanceName: '${abbrs.sqlManagedInstances}${environmentName}'
    virtualNetworkName: networking.outputs.VirtualNetworkName
    tags: tags
    location: location
    environmentName: environmentName
  }
}

var keyvaultName = '${abbrs.keyVaultVaults}${environmentName}-${uniqueID}'
module keyvault 'modules//keyvault/keyvault.bicep' = {
  name: keyvaultName
  scope: resourceGroup
  params: {
    name: keyvaultName
    tags: tags
    location: location
  }
}


var monitoringName = 'mon${environmentName}'
module monitoring 'modules/monitor/monitoring.bicep' = {
  name: monitoringName
  scope: resourceGroup
  params: {
    tags: tags
    applicationInsightsName: '${abbrs.applicationInsights}${environmentName}'
    logAnalyticsName: '${abbrs.logAnalyticsWorkspaces}${environmentName}'
    location: location
  }
}

//SQL

var sqlServerName = '${abbrs.sqlServers}${environmentName}'
module sqlServer 'modules/sqlserver/fullsqlserver.bicep' = {
  dependsOn:[networking, monitoring, sqlNetworking]
  name: sqlServerName
  scope: resourceGroup
  params: {
    virtualNetworkSubNetId: networking.outputs.sqlVirtualNetworkSubnetId
    tags: tags
    location: location
  }
}


var appServicePlanName = '${abbrs.webServerFarms}web-${environmentName}-${uniqueID}'
module appServicePlan 'modules/webapp/appserviceplan.bicep' = {
  name: appServicePlanName
  scope: resourceGroup
  params: {
    name: appServicePlanName
    tags: tags
    sku: {
      name: 'P0V3'
    }
    location: location
  }
}

var appServiceName = '${abbrs.webSitesAppService}api-${environmentName}-${uniqueID}'
module apiAppService 'modules/webapp/appservice.bicep' = {
  dependsOn: [appServicePlan, monitoring, networking]
  name: appServiceName
  scope: resourceGroup
  params: {
    name: appServiceName
    planId: appServicePlan.outputs.id
    tags: union(tags, { 'azd-env-name': environmentName, 'azd-service-name': 'api' })
    location: location
    virtualNetworkSubnetId: networking.outputs.webAppVirtualNetworkSubnetId
    appSettings: {
      APPLICATIONINSIGHTS_CONNECTION_STRING: monitoring.outputs.applicationInsightsConnectionString
      APPINSIGHTS_INSTRUMENTATIONKEY: monitoring.outputs.applicationInsightsInstrumentationKey
    }
  }
}

/*
module webAppApplicationSQLLinker 'modules/webapp/appservice-sql-linker.bicep' = {
  dependsOn: [webAppService, sqlServer]
  name: 'webAppApplicationSqlLinker'
  scope: rgSurface
  params:{
    name:'application'
    dbAccountId: sqlServer.outputs.sqlServerApplicationId
    appServiceName: webAppServiceName
  }
}
  */

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId

output AZURE_APPLICATION_INSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString

//output AZURE_SERVICEBUS_ENDPOINT string = serviceBus.outputs.serviceBusEndpoint
//output AZURE_COSMOSDB_ENDPOINT string = cosmosApp.outputs.cosmosDbAccountEndpoint
//output AZURE_SIGNALR_ENDPOINT string = signalR.outputs.signalREndpoint
//output RG_SURFACE string = rgSurface.name
//output RG_PROCESSING string = rgProcessing.name
