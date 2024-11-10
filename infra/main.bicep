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

@description('SQL Admin Password')
@secure()
param sqlAdminPassword string

@description('SQL Admin User')
@secure()
param sqlAdminUser string

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

var uniqueID = substring(uniqueString(subscription().id),0,4)

var resourceGroupSettingsName = '${abbrs.resourcesResourceGroups}${environmentName}-settings'
var resourceGroupName = '${abbrs.resourcesResourceGroups}${environmentName}'

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

resource resourceGroupSettings 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupSettingsName
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


var keyvaultName = '${abbrs.keyVaultVaults}${environmentName}-${uniqueID}'
module keyvault 'modules/keyvault/keyvault.bicep' = {
  name: keyvaultName
  scope: resourceGroupSettings
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
var databaseName = 'todo'
module sqlServer 'modules/sqlserver/sqlwithprivate.bicep' = {
  dependsOn:[networking, monitoring]
  name: sqlServerName
  scope: resourceGroup
  params: {
    virtualNetworkSubNetId: networking.outputs.sqlVirtualNetworkSubnetId
    virtualNetworkId: networking.outputs.virtualNetworkId
    sqlAdminPassword:sqlAdminPassword
    sqlAdminUsername: sqlAdminUser
    databaseName: databaseName
    tags: tags
    location: location
    sqlServerName: sqlServerName
  }
}

var sqlServerKeyVaultConnectionStringName = '${abbrs.sqlServers}${environmentName}-${abbrs.keyVaultVaults}secret-connectionstring'
module sqlServerKeyVaultConnectionString 'modules/keyvault/keyvault-secret.bicep' = {
  dependsOn:[sqlServer, keyvault]
  name: sqlServerKeyVaultConnectionStringName
  scope: resourceGroupSettings
  params: {
    secretName:'ToDoDbConnectionString'
    secretValue: 'Server=tcp:${sqlServer.outputs.sqlServerFqdn},1433;Initial Catalog=${databaseName};Persist Security Info=False;User ID=${sqlAdminUser};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    keyVaultName: keyvaultName
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
  dependsOn: [appServicePlan, monitoring, networking, keyvault]
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
      KEY_VAULT_URL: keyvault.outputs.endpoint
    }
  }
}

var appServiceKeyVaultAccessName = '${abbrs.keyVaultVaults}api-${environmentName}-${uniqueID}-access'
module appServiceKeyVaultAccess 'modules/keyvault/keyvault-appsecretaccess.bicep' = {
  dependsOn: [keyvault,apiAppService]
  name: appServiceKeyVaultAccessName
  scope: resourceGroupSettings
  params: {
     keyVaultName: keyvaultName
      principalId: apiAppService.outputs.appServicePrincipalId
  }
}

output APIAPPSERVICEURL string = apiAppService.outputs.appServiceHostName
