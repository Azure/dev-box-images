var settings = loadJsonContent('main.parameters.json')
param location string = resourceGroup().location

resource networkConnection 'Microsoft.DevCenter/networkConnections@2023-04-01' existing = {
  name: settings.networkConnectionName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: settings.identityName
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: settings.projectName
}

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: settings.galleryName
}

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: settings.devcenterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
}

resource addGallery 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  parent: devcenter
  name: gallery.name
  properties: {
    galleryResourceId: gallery.id
  }
}

resource addNetworkConnection 'Microsoft.DevCenter/devcenters/attachednetworks@2023-04-01' = {
  name: networkConnection.name
  parent: devcenter
  properties: {
    networkConnectionId: networkConnection.id
  }
}

resource definition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-04-01' = {
  parent: devcenter
  name: settings.deffinition.name
  location: location
  properties: {
    imageReference: {
      id: '${devcenter.id}/galleries/${gallery.name}/images/${settings.deffinition.imageName}'
    }
    sku: {
      name: settings.deffinition.sku
    }
    hibernateSupport: 'Disabled'
  }
  dependsOn: [
    addGallery
  ]
}


resource pool 'Microsoft.DevCenter/projects/pools@2023-04-01' = {
  name: settings.pool.name
  location: location
  parent: project
  properties: {
    devBoxDefinitionName: settings.pool.deffinitionName
    licenseType: 'Windows_Client'
    localAdministrator: 'Enabled'
    networkConnectionName: networkConnection.name
    stopOnDisconnect: {
      status: 'Disabled'
    }
  }
  dependsOn: [
    definition
  ]
}




