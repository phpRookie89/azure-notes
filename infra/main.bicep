// ============================================================
// Azure Notes — Main Bicep template
// Deploys all infrastructure for the project.
// ============================================================

targetScope = 'resourceGroup'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Unique suffix to avoid naming collisions (e.g. your initials + random digits)')
param suffix string = 'azn001'

// ── Module: Cosmos DB ──────────────────────────────────────
module cosmos 'modules/cosmosdb.bicep' = {
  name: 'cosmosdb'
  params: {
    accountName: 'cosmos-notes-${suffix}'
    location: location
    databaseName: 'notesdb'
    containerName: 'notes'
  }
}

// ── Module: Storage Account ────────────────────────────────
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    accountName: 'stnotes${suffix}'
    location: location
  }
}

// ── Module: Key Vault ──────────────────────────────────────
module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    vaultName: 'kv-notes-${suffix}'
    location: location
    cosmosEndpoint: cosmos.outputs.endpoint
    cosmosKey: cosmos.outputs.primaryKey
  }
}

// ── Module: Azure Functions ────────────────────────────────
module functions 'modules/functions.bicep' = {
  name: 'functions'
  params: {
    appName: 'func-notes-${suffix}'
    location: location
    storageAccountName: storage.outputs.accountName
    keyVaultName: keyvault.outputs.vaultName
    cosmosEndpoint: cosmos.outputs.endpoint
    cosmosDatabaseName: 'notesdb'
    cosmosContainerName: 'notes'
    environment: environment
  }
}


// ── Outputs ────────────────────────────────────────────────
output functionAppUrl string = functions.outputs.defaultHostName
output cosmosEndpoint string = cosmos.outputs.endpoint
output keyVaultUri string = keyvault.outputs.vaultUri
