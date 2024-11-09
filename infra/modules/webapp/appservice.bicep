metadata description = 'Creates an Azure App Service.'
param name string
param planId string
param location string = resourceGroup().location
param tags object = {}
param appSettings object = {}
param virtualNetworkSubnetId string

var baseAppSettings = {
  APPINSIGHTS_PROFILERFEATURE_VERSION: '1.0.0'
  APPINSIGHTS_SNAPSHOTFEATURE_VERSION: '1.0.0'
  ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
  DiagnosticServices_EXTENSION_VERSION: '~3'
  InstrumentationEngine_EXTENSION_VERSION: 'disabled'
  SnapshotDebugger_EXTENSION_VERSION: 'disabled'
  XDT_MicrosoftApplicationInsights_BaseExtensions: 'disabled'
  XDT_MicrosoftApplicationInsights_Java: '1'
  XDT_MicrosoftApplicationInsights_Mode: 'recommended'
  XDT_MicrosoftApplicationInsights_NodeJS: '1'
  XDT_MicrosoftApplicationInsights_PreemptSdk: 'disabled'
}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    serverFarmId: planId
    siteConfig: {
      alwaysOn: true
      use32BitWorkerProcess: false
      healthCheckPath: '/alive'
    }
    httpsOnly: true
    virtualNetworkSubnetId:virtualNetworkSubnetId
  }
  identity: {
    type: 'SystemAssigned'
  }
  
}

resource slot 'Microsoft.Web/sites/slots@2022-03-01' = {
  parent: appService
  name: 'deployment'
  location: location
  properties: {
    serverFarmId: planId
  }
}

resource settings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'appsettings'
  parent: appService
  properties: union(appSettings, baseAppSettings)
  //properties: appSettings
}

output appServicePrincipalId string = appService.identity.principalId

output appServiceHostName string = appService.properties.defaultHostName
