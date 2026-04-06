@description('Cosmos DB account name (must be globally unique)')
param accountName string

@description('Azure region')
param location string

@description('Database name')
param databaseName string

@description('Container name')
param containerName string

// ── Cosmos DB Account ──────────────────────────────────────
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    // Free tier: first 1000 RU/s and 25 GB are free — great for learning!
    enableFreeTier: true
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      { name: 'EnableServerless' } // serverless = pay per request, ideal for dev
    ]
  }
}

// ── Database ───────────────────────────────────────────────
resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: { id: databaseName }
  }
}

// ── Container ──────────────────────────────────────────────
resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
      }
    }
  }
}

// ── Outputs ────────────────────────────────────────────────
output endpoint string = cosmosAccount.properties.documentEndpoint
#disable-next-line outputs-should-not-contain-secrets
output primaryKey string = cosmosAccount.listKeys().primaryMasterKey
output accountName string = cosmosAccount.name
