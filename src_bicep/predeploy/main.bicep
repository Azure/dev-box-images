var settings = loadJsonContent('main.parameters.json')
param location string = resourceGroup().location
param deploymentId string = newGuid()

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: settings.identityName
}

resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: settings.galleryName
  location: location
  properties: {}
}

var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource roleAssignmentsContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(gallery.name, 'Contributor')
  properties: {
    roleDefinitionId: contributorRoleId
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


module networkModule '../template/network/main.bicep' = {
  name: 'Microsoft.Network-${deploymentId}'
  params: {
    name: settings.network.name
    location: location
    vnetAddressPrefix: settings.network.vnetAddressPrefix
    defaultSubnetAddressPrefix : settings.network.defaultSubnetAddressPrefix
  }
}

module storageModele '../template/storage/main.bicep' = {
  name: guid('Microsoft.Storage-${deploymentId}')
  params: {
    name: settings.storage.name
    sku: settings.storage.sku
    kind: settings.storage.kind
    location: location
  }
}
