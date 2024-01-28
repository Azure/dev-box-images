using '../main.bicep'

param networkSettings = {
  resourceGroup: {
    name: 'resourceGroup'
    location: 'westeurope'
    tags: {}
  }
  resources: {
    virtualNetwork: {
      name: 'virtualNetwork'
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

param computeSettings = {
  resourceGroup: {
    name: 'resourceGroup'
    location: 'westeurope'
    tags: {}
  }
  resources: {
    galleries: [
      {
        name: '34'
      }
    ]
  }
}

param identitySettings = {
  resourceGroup: {
    name: 'resourceGroup'
    location: 'westeurope'
    tags: {}
  }
  resources: {
    managedIdentity: {
      name: '46'
    }
  }
}

param devcenterSettings = {
  resourceGroup: {
    name: 'resourceGroup'
    location: 'westeurope'
    tags: {}
  }
  resources: {
    networkConnection: {
      name: 'virtualNetwork'
      resourceGroup: 'securityGroup'
    }
    devcenter: {
      name: 'devcenter'
    }
    definitions: [
      {
        name: 'standard'
        image: 'win-11-ent-22h2-os'
        sku: '8-vcpu-32gb-ram-256-ssd'
      }
      {
        name: 'office'
        image: 'win-11-ent-22h2-m365'
        sku: '8-vcpu-32gb-ram-256-ssd'
      }
      {
        name: 'developer'
        image: 'vs-22-ent-win-11-m365'
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
            definition: ''
            administrator: 'Enabled'
          }
          {
            name: 'office'
            definition: ''
            administrator: 'Enabled'
          }
          {
            name: 'developer'
            definition: ''
            administrator: 'Enabled'
          }
        ]
      }
    ]
  }
}
