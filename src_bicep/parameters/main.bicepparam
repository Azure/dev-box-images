using '../main.bicep'

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
  resources: {
    galleries: [
      {
        name: 'cgName123'
      }
    ]
  }
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

param devcenterSettings = {
  resources: {
    networkConnection: {
      name: 'vnet'
      resourceGroup: 'rgName'
    }
    devcenter: {
      name: 'devcenterName'
    }
    definitions: [
      {
        name: 'devboxforivan'
        image: 'VS2022Box'
        sku: '8-vcpu-32gb-ram-256-ssd'
      }
      {
        name: 'office'
        image: 'VS2022Box'
        sku: '8-vcpu-32gb-ram-256-ssd'
      }
    ]
    projects: [
      {
        name: 'default'
        description: 'This is the default project'
        pools: [
          {
            name: 'standard'
            definition: 'devboxforivan'
            administrator: 'Enabled'
          }
          {
            name: 'office'
            definition: 'office'
            administrator: 'Enabled'
          }
        ]
      }
    ]
  }
}
