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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: networkName
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
    subnetId: virtualNetwork.properties.subnets[0].id // we need use second one 
    resourceGroupname: resourceGroupName
    location: location
    galeryName: gallery.name
  }
  dependsOn: [
    managedIdentity
    virtualNetwork
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
param resourceGroupName string
param location string = resourceGroup().location
