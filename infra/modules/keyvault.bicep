@description('Key Vault name (3-24 chars, globally unique)')
param vaultName string

@description('Azure region')
param location string

@description('Cosmos DB endpoint to store as a secret')
param cosmosEndpoint string

@description('Cosmos DB primary key to store as a secret')
@secure()
param cosmosKey string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    // Access policies are managed via RBAC — modern best practice
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

// Store Cosmos endpoint as a secret
resource cosmosEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'CosmosEndpoint'
  properties: {
    value: cosmosEndpoint
  }
}

// Store Cosmos key as a secret
resource cosmosKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'CosmosKey'
  properties: {
    value: cosmosKey
  }
}

output vaultName string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
