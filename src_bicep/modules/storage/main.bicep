// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: settings.resources.storageAccount.name
  location: location
  kind: settings.resources.storageAccount.kind
  sku: {
    name: settings.resources.storageAccount.sku.name
  }
}

// ----------
// Parameters
// ----------

param settings object
param location string
