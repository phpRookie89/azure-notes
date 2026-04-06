@description('Storage account name (lowercase, 3-24 chars, globally unique)')
param accountName string

@description('Azure region')
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: {
    name: 'Standard_LRS' // Locally Redundant Storage — cheapest tier, fine for dev
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false // security best practice
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Blob container for attachments
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccount.name}/default/attachments'
  properties: {
    publicAccess: 'None'
  }
}

// Blob container for Flex Consumption function deployments
resource deploymentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccount.name}/default/deployments'
  properties: {
    publicAccess: 'None'
  }
}

output accountName string = storageAccount.name
