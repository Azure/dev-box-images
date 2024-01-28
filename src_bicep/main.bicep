// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

// Resources
module resources './modules/resources/main.bicep' = {
  name: 'Microsoft.Resources'
  scope: subscription()
  params: {
    resourceGroups: resourceGroups
  }
}

// Identity
module identity 'modules/identity/main.bicep' = {
  name: 'Microsoft.ManagedIdentity'
  scope: resourceGroup(identitySettings.resourceGroup.name)
  params: {
    settings: identitySettings
  }
  dependsOn: [
    resources
  ]
}

// Network
module network './modules/network/main.bicep' = {
  name: 'Microsoft.Network'
  scope: resourceGroup(networkSettings.resourceGroup.name)
  params: {
    settings: networkSettings
  }
  dependsOn: [
    resources
  ]
}

// Compute
module compute './modules/compute/main.bicep' = {
  name: 'Microsoft.Compute'
  scope: resourceGroup(computeSettings.resourceGroup.name)
  params: {
    settings: computeSettings
    identityId: identity.outputs.identityId
  }
  dependsOn: [
    resources
  ]
}

// DevCenter
module devcenter 'modules/devcenter/main.bicep' = {
  name: 'Microsoft.DevCenter'
  scope: resourceGroup(devcenterSettings.resourceGroup.name)
  params: {
    settings: devcenterSettings
    identityId: identity.outputs.identityId
    subnetId: network.outputs.subnetId
    galleryIds: compute.outputs.galleryIds
  }
  dependsOn: [
    resources
  ]
}

// ----------
// Variables
// ----------

var resourceGroups = [
  computeSettings.resourceGroup
  networkSettings.resourceGroup
  devcenterSettings.resourceGroup
  identitySettings.resourceGroup
]

// ----------
// Parameters
// ----------

param identitySettings object
param networkSettings object
param computeSettings object
param devcenterSettings object
