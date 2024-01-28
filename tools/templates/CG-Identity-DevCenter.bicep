
param identityname string
param devcenterName string
param cgName string
param subscriptionId string
param location string = resourceGroup().location

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

resource rgContributor 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid('ContributorRoleAssignment')
  properties: {
    principalId: tenant()

  }
}


resource addGallerryToDevcenter 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  name: '${devcenter.name}${computeGallery.name}'
  parent: devcenter
  properties: {
    galleryResourceId: computeGallery.id
  }
}
