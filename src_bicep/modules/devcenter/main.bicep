// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// DevCenter
resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: settings.resources.devcenter.name
  location: settings.resourceGroup.location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {}
}

// DevCenter Attached Networks
resource attachedNetworks 'Microsoft.DevCenter/devcenters/attachednetworks@2023-04-01' = {
  parent: devcenter
  name: 'default'
  properties: {
    networkConnectionId: networkConnection.id
  }
}

// Network Connection
resource networkConnection 'Microsoft.DevCenter/networkConnections@2023-04-01' = {
  name: settings.resources.networkConnection.name
  location: settings.resourceGroup.location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: subnetId
    networkingResourceGroupName: settings.resources.networkConnection.resourceGroup
  }
}

// -------
// Modules
// -------

module definitions 'definitions/main.bicep' = {
  name: 'Microsoft.DevCenter.Definitions'
  params: {
    settings: settings
  }
  dependsOn: [
    devcenter
    networkConnection
  ]
}

module galleries 'galleries/main.bicep' = {
  name: 'Microsoft.DevCenter.Galleries'
  params: {
    settings: settings
    galleryIds: galleryIds
  }
  dependsOn: [
    devcenter
    networkConnection
  ]
}

module projects 'projects/main.bicep' = {
  name: 'Microsoft.DevCenter.Projects'
  params: {
    settings: settings
  }
  dependsOn: [
    devcenter
    networkConnection
    definitions
  ]
}

// ----------
// Parameters
// ----------

param settings object

param identityId string
param subnetId string
param galleryIds array
