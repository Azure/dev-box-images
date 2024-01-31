// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// -------
// Pre existing resources
// -------

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: gelaryName
}

// -------
// Modules
// -------

// DevCenter
module devcenter 'modules/devcenter/main.bicep' = {
  name: 'Microsoft.DevCenter'
  scope: resourceGroup(resourceGroupName)
  params: {
    settings: devcenterSettings
    identityId: managedIdentity.id
    resourceGroupname: resourceGroupName
    location: location
    networkSettings: networkSettings
    galeryName: gallery.name
  }
  dependsOn: [
    managedIdentity
    gallery
  ]
}

// ----------
// Parameters
// ----------

param devcenterSettings object
param identityName string
param networkName string
param gelaryName string
param networkSettings object
param resourceGroupName string
param location string = resourceGroup().location
