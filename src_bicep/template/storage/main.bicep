param name string
param location string
param kind string
param sku string

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: name
  location: location
  kind: kind
  sku: {
    name: sku
  }
}
