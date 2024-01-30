// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Gallery
resource galleries 'Microsoft.Compute/galleries@2022-03-03' = {
  name: settings.galeryName
  location: location
  properties: {}
}

// Role Assignment - Contributor
resource roleAssignmentsContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(settings.galeryName, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

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
param location string
