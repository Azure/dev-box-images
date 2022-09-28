// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Location for the Compute Gallery. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(2)
@maxLength(80)
@description('The name of the Azure Compute Gallery.')
param name string

@description('The resource ID of the DevCenter.')
param devCenterId string = ''

@minLength(36)
@maxLength(36)
@description('The principal id of a service principal used in the image build pipeline. If provided the service principal will be given Owner permissions on the gallery')
param builderPrincipalId string = ''

@description('Object ID for the first-party Windows 365 enterprise application in your tenant. You find this ID in the Azure portal or via the Azure CLI: `az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id`')
param windows365PrinicalId string

@description('Tags to apply to the resources')
param tags object = {}

var devCenterName = empty(devCenterId) ? '' : last(split(devCenterId, '/'))
var devCenterGroup = empty(devCenterId) ? '' : first(split(last(split(replace(devCenterId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))
var devCenterSub = empty(devCenterId) ? '' : first(split(last(split(devCenterId, '/subscriptions/')), '/'))

var builderAssignmentId = guid('groupcontributor${resourceGroup().id}${name}${builderPrincipalId}')
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource gallery 'Microsoft.Compute/galleries@2022-01-03' = {
  name: name
  location: location
  tags: tags
}

// Give Reader permission to the Windows 365 first-party SP
module galleryRole365 'galleryRole.bicep' = {
  name: 'galleryRole365'
  params: {
    role: 'Reader'
    principalId: windows365PrinicalId
    galleryName: gallery.name
  }
}

// If builder principal id was provided, give it Owner permissions on the gallery...
module galleryRoleBuilder 'galleryRole.bicep' = if (!empty(builderPrincipalId)) {
  name: 'galleryRoleBuilder'
  params: {
    role: 'Owner'
    principalId: builderPrincipalId
    galleryName: gallery.name
  }
}

// and contributor access to the gallery's resource group (to update and create images)
resource builderGroupAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(builderPrincipalId)) {
  name: builderAssignmentId
  properties: {
    principalId: builderPrincipalId
    roleDefinitionId: contributorRoleId
  }
  scope: resourceGroup()
}

// If a devcenter resource id is provided...
resource devCenter 'Microsoft.DevCenter/devcenters@2022-08-01-preview' existing = if (!empty(devCenterId)) {
  scope: resourceGroup(devCenterSub, devCenterGroup)
  name: devCenterName
}

// give it's identity Owner permissions on the gallery...
module galleryRoleDC 'galleryRole.bicep' = if (!empty(devCenterId)) {
  name: 'galleryRoleDC'
  params: {
    role: 'Owner'
    principalId: (!empty(devCenterId) ? devCenter.identity.principalId : '')
    galleryName: gallery.name
  }
}

// then attach the gallery to the devcenter
module galleryAttach 'galleryAttach.bicep' = if (!empty(devCenterId)) {
  scope: resourceGroup(devCenterSub, devCenterGroup)
  name: 'galleryAttach'
  params: {
    devCenterName: devCenter.name
    galleryResourceId: gallery.id
  }
  dependsOn: [
    galleryRole365
    galleryRoleDC
  ]
}

output id string = gallery.id
