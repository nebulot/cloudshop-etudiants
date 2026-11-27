targetScope = 'resourceGroup'

@allowed(['dev', 'prod'])
param environmentName string

param location string = resourceGroup().location

param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var sizing = {
  dev: {
    storageSku: 'Standard_LRS'
    minReplicas: 0
    maxReplicas: 2
    cpu: '0.25'
    memory: '0.5Gi'
    logRetentionDays: 30
    logDailyQuotaGb: 1
  }
  prod: {
    storageSku: 'Standard_ZRS'
    minReplicas: 1
    maxReplicas: 5
    cpu: '0.5'
    memory: '1Gi'
    logRetentionDays: 30
    logDailyQuotaGb: 2
  }
}

var cfg = sizing[environmentName]

var tags = {
  project: 'cloudshop'
  environment: environmentName
  managedBy: 'bicep'
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    storageAccountName: 'st${uniqueString(resourceGroup().id)}'
    skuName: cfg.storageSku
    tags: tags
  }
}

module api 'modules/api.bicep' = {
  name: 'api'
  params: {
    location: location
    environmentName: environmentName
    tags: tags
    containerImage: containerImage
    minReplicas: cfg.minReplicas
    maxReplicas: cfg.maxReplicas
    cpu: cfg.cpu
    memory: cfg.memory
    logRetentionDays: cfg.logRetentionDays
    logDailyQuotaGb: cfg.logDailyQuotaGb
  }
}

output storageAccountName string = storage.outputs.storageAccountName
output apiUrl string = api.outputs.apiUrl
