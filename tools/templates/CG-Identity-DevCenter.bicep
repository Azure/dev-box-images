
param identityname string
param devcenterName string
param cgName string
param subscriptionId string
param location string = resourceGroup().location

targetScope = 'resourceGroup'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: identityname
  location: location 
}

resource computeGallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: cgName
  location: location
  properties: {
    description: 'compute gallery for store images'
  }
}

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: devcenterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${identity.name}' : {}
    }
  }
}

resource roleAssignmentsContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Contributor')
  scope: tenant()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource addGallerryToDevcenter 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  name: split(computeGallery.id, '/')[8]
  parent: devcenter
  properties: {
    galleryResourceId: computeGallery.id
  }
}
