// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

// Resources
module resource './modules/resources/main.bicep' = {
  name: 'Microsoft.Resources'
  scope: subscription()
  params: {
    resourseGroupSettings: resourseGroupSettings
  }
}

// Identity
module identity 'modules/identity/main.bicep' = {
  name: 'Microsoft.ManagedIdentity'
  scope: resourceGroup(resourseGroupSettings.name)
  params: {
    settings: identitySettings
    location : resourseGroupSettings.location
  }
  dependsOn: [
    resource
  ]
}

// Network
module network './modules/network/main.bicep' = {
  name: 'Microsoft.Network'
  scope: resourceGroup(resourseGroupSettings.name)
  params: {
    settings: networkSettings
    location: resourseGroupSettings.location
  }
  dependsOn: [
    resource
  ]
}

// Compute
module compute './modules/compute/main.bicep' = {
  name: 'Microsoft.Compute'
  scope: resourceGroup(resourseGroupSettings.name)
  params: {
    settings: computeSettings
    identityId: identity.outputs.identityId
    location: resourseGroupSettings.location
  }
  dependsOn: [
    resource
  ]
}

//StorageAccount
module storage './modules/storage/main.bicep' = {
  name: 'Microsoft.Storage'
  scope: resourceGroup(resourseGroupSettings.name)
  params: {
    settings: storageAccountSettings
    location: resourseGroupSettings.location
  }
  dependsOn: [
    resource
  ]
}

// // DevCenter
// module devcenter 'modules/devcenter/main.bicep' = {
//   name: 'Microsoft.DevCenter'
//   scope: resourceGroup(devcenterSettings.resourceGroup.name)
//   params: {
//     settings: devcenterSettings
//     identityId: identity.outputs.identityId
//     subnetId: network.outputs.subnetId
//     galleryIds: compute.outputs.galleryIds
//   }
//   dependsOn: [
//     resources
//   ]
// }

// ----------
// Parameters
// ----------

param resourseGroupSettings object
param identitySettings object
param networkSettings object
param computeSettings object
param devcenterSettings object
param storageAccountSettings object
