// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Gallery
resource galleries 'Microsoft.Compute/galleries@2022-03-03' = [for gallery in settings.resources.galleries: {
  name: gallery.name
  location: settings.resourceGroup.location
  properties: {}
}]

// Role Assignment - Contributor
resource roleAssignmentsContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(settings.resources.galleries)): {
  name: guid(galleries[i].name, 'Contributor')
  scope: galleries[i]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

// Role Assignment - Owner
resource roleAssignmentsReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(settings.resources.galleries)): {
  name: guid(galleries[i].name, 'Owner')
  scope: galleries[i]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
    principalId: '0af06dc6-e4b5-4f28-818e-e78e62d137a5' // Windows 365
    principalType: 'ServicePrincipal'
  }
}]

// ---------
// Resources
// ---------

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: split(identityId, '/')[8]
  scope: resourceGroup(split(identityId, '/')[4])
}

// ----------
// Parameters
// ----------

param settings object
param identityId string

// -------
// Outputs
// -------

output galleryIds array = [for i in range(0, length(settings.resources.galleries)): galleries[i].id]
