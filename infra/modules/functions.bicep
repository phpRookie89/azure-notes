@description('Function App name')
param appName string

@description('Azure region')
param location string

@description('Storage account name (used by Functions runtime)')
param storageAccountName string

@description('Key Vault name to grant access to')
param keyVaultName string

@description('Cosmos DB endpoint')
param cosmosEndpoint string

@description('Cosmos DB database name')
param cosmosDatabaseName string

@description('Cosmos DB container name')
param cosmosContainerName string

@description('Environment name')
param environment string

// Reference the existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Reference the existing Key Vault to assign RBAC
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

var storageConnString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

// App Service Plan — Flex Consumption (new serverless tier, works on free subscriptions)
resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'plan-${appName}'
  location: location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true // Linux required for Flex Consumption
  }
}

// Application Insights for monitoring
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${appName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned' // enables managed identity for Key Vault access
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageConnString
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'COSMOS_ENDPOINT'
          value: cosmosEndpoint
        }
        {
          // Reads CosmosKey from Key Vault at runtime using managed identity
          name: 'COSMOS_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=CosmosKey)'
        }
        {
          name: 'COSMOS_DATABASE'
          value: cosmosDatabaseName
        }
        {
          name: 'COSMOS_CONTAINER'
          value: cosmosContainerName
        }
        {
          name: 'ENVIRONMENT'
          value: environment
        }
      ]
      cors: {
        allowedOrigins: ['*'] // tighten this in production
      }
    }
    httpsOnly: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}deployments'
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'AzureWebJobsStorage'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 40
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'node'
        version: '20'
      }
    }
  }
}

// Grant Function App's managed identity "Key Vault Secrets User" role
resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, functionApp.id, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output defaultHostName string = 'https://${functionApp.properties.defaultHostName}'
output functionAppName string = functionApp.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
