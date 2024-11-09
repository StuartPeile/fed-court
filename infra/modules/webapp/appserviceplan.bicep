metadata description = 'Creates an Azure App Service plan.'
param name string
param location string = resourceGroup().location
param tags object = {}
param sku object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
}

var autoscaleSettingName = 'myAutoscaleSetting'
var minInstanceCount = 1
var maxInstanceCount = 10
var defaultInstanceCount = 1
var cpuThreshold = 75
var scaleOutCount = 1
var scaleInCount = 1

resource autoscaleSetting 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: autoscaleSettingName
  location: location
  properties: {
    targetResourceUri: appServicePlan.id
    enabled: true
    profiles: [
      {
        name: 'CPU Scaling Profile'
        capacity: {
          minimum: string(minInstanceCount)
          maximum: string(maxInstanceCount)
          default: string(defaultInstanceCount)
        }
        rules: [
          // Scale out rule
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              timeGrain: 'PT1M' // 1-minute granularity
              statistic: 'Average'
              timeWindow: 'PT5M' // 5-minute evaluation period
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: cpuThreshold
              metricResourceUri: appServicePlan.id
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: string(scaleOutCount)
              cooldown: 'PT5M' // 5-minute cooldown
            }
          }
          // Scale in rule
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              timeGrain: 'PT1M' // 1-minute granularity
              statistic: 'Average'
              timeWindow: 'PT5M' // 5-minute evaluation period
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: cpuThreshold - 20 // Scale in when CPU goes below 55%
              metricResourceUri: appServicePlan.id
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: string(scaleInCount)
              cooldown: 'PT5M' // 5-minute cooldown
            }
          }
        ]
      }
    ]
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
