using '../postdeploy.bicep'

param resourceGroupName = 'resourceGroupName'
param identityName = 'identityName'
param networkName = 'vnet'
param gelaryName = 'cgName123'

param networkSettings = {
  resources: {
    virtualNetwork: {
      name: 'vnet'
      addressPrefix: '10.0.0.0/16'
      subnet: {
        addressPrefix: '10.0.0.0/24'
      }
    }
    securityGroup: {
      name: 'securityGroup'
    }
  }
}

param devcenterSettings = {
  resources: {
    compute: gelaryName
    networkConnection: {
      name: networkName
      resourceGroup: resourceGroupName
    }
    devcenter: {
      name: 'devcenterName'
    }
    definitions: [
      {
        name: 'standard'
        image: 'WS11-dev-preinstalled-software'
        sku: '8-vcpu-32gb-ram-256-ssd'
      }
      {
        name: 'office'
        image: 'WS11-dev-preinstalled-software'
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
            definition: 'standard'
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
