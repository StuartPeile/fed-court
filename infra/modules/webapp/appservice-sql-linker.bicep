
param appServiceName string

param dbAccountId string

param name string

resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

resource dbConnector 'Microsoft.ServiceLinker/linkers@2024-04-01' = {
  scope: appService
  name: name
  properties: {
    targetService: {
      type: 'AzureResource'
      id: dbAccountId
    }
    authInfo: {
      authType: 'systemAssignedIdentity'
    }
    clientType: 'dotnet'
    configurationInfo: {
       action: 'optOut'
    }
  }
}
