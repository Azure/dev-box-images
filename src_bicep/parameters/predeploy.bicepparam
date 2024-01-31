using '../predeploy.bicep'

param resourseGroupSettings = {
    name: 'resourceGroupName'
    location: 'westeurope'
    tags: {}
}

param networkSettings = {
  resources: {
    virtualNetwork: {
      name: 'vnet'
      addressPrefix: '10.0.0.0/16'
      subnet: {
        addressPrefix: '10.0.0.0/24'
      }
    }
  }
}

param computeSettings = {
  galeryName: 'cgName123'
}

param identitySettings = {
  resources: {
    managedIdentity: {
      name: 'identityName'
    }
  }
}

param storageAccountSettings = {
  resources: {
    storageAccount: {
      name: 'experimentdevboxstg12'
      kind: 'StorageV2'
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
}
