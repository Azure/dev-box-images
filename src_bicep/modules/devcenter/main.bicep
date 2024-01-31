// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

//Networck
module network 'network/main.bicep' = {
  name: 'Microsoft.Network'
  scope: resourceGroup(resourceGroupname)
  params: {
    settings: networkSettings
    location: location
    devcenterName: settings.resources.devcenter.name
  }
}

// DevCenter
resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: settings.resources.devcenter.name
  location: location
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
  name: '${devcenter.name}-${settings.resources.networkConnection.name}'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: network.outputs.subnetId
  }
}

// -------
// Modules
// -------

module definitions 'definitions/main.bicep' = {
  name: 'Microsoft.DevCenter.Definitions'
  params: {
    settings: settings
    location: location
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
    galeryName: galeryName
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
    location: location
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
param galeryName string
param resourceGroupname string
param networkSettings object
param location string = resourceGroup().location
