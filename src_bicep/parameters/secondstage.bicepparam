using '../secondstage.bicep'

param resourceGroupName = 'resourceGroupName'
param identityName = 'identityName'
param networkName = 'vnet'
param gelaryName = 'cgName123'

param devcenterSettings = {
  resources: {
    networkConnection: {
      name: networkName
      resourceGroup: resourceGroupName
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
