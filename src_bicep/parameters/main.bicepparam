using '../main.bicep'

param networkSettings = {
  resourceGroup: {
    name: ''
    location: 'easteeurope'
    tags: {}
  }
  resources: {
    virtualNetwork: {
      name: ''
      addressPrefix: '10.0.0.0/16'
      subnet: {
        addressPrefix: '10.0.0.0/24'
      }
    }
    securityGroup: {
      name: ''
    }
  }
}

param computeSettings = {
  resourceGroup: {
    name: ''
    location: 'easteeurope'
    tags: {}
  }
  resources: {
    galleries: [
      {
        name: ''
      }
    ]
  }
}

param identitySettings = {
  resourceGroup: {
    name: ''
    location: 'easteeurope'
    tags: {}
  }
  resources: {
    managedIdentity: {
      name: ''
    }
  }
}

param devcenterSettings = {
  resourceGroup: {
    name: ''
    location: 'easteeurope'
    tags: {}
  }
  resources: {
    networkConnection: {
      name: ''
      resourceGroup: ''
    }
    devcenter: {
      name: ''
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
