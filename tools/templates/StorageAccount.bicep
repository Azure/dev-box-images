param storageAccountName string
param location string = resourceGroup().location


resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'storageAccountName'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
