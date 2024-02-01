// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Location of the Dev Center. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(26)
@description('Name of the Dev Center')
param name string

@description('Resource ID of an existing Azure Compute Gallery to attach to the DevCenter.')
param galleryId string = ''

@description('Tags to apply to the resources')
param tags object = {}

var windows365PrinicalId = 'df65ee7f-8ea9-481d-a20f-e7e23bcf25ed'

var galleryName = empty(galleryId) ? '' : last(split(galleryId, '/'))
var galleryGroup = empty(galleryId) ? '' : first(split(last(split(replace(galleryId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))

resource devCenter 'Microsoft.DevCenter/devcenters@2022-08-01-preview' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}

// If a galleryId was provided, get a reference to it
resource gallery 'Microsoft.Compute/galleries@2022-01-03' existing = if (!empty(galleryId)) {
  name: empty(galleryId) ? 'galleryName' : galleryName
  scope: (!empty(galleryId) ? resourceGroup(galleryGroup) : resourceGroup())
}

// give Reader permission to the Windows 365 first-party SP
module galleryRole365 'galleryRole.bicep' = if (!empty(galleryId)) {
  name: 'galleryRole365'
  scope: (!empty(galleryId) ? resourceGroup(galleryGroup) : resourceGroup())
  params: {
    role: 'Reader'
    principalId: windows365PrinicalId
    galleryName: gallery.name
  }
}

// and give the dev center identity Owner permissions on the gallery...
module galleryRoleDC 'galleryRole.bicep' = if (!empty(galleryId)) {
  name: 'galleryRoleDC'
  scope: (!empty(galleryId) ? resourceGroup(galleryGroup) : resourceGroup())
  params: {
    role: 'Owner'
    principalId: devCenter.identity.principalId
    galleryName: gallery.name
  }
}

// then attach the gallery to the devcenter
module galleryAttach 'galleryAttach.bicep' = if (!empty(galleryId)) {
  name: 'galleryAttach'
  params: {
    devCenterName: devCenter.name
    galleryResourceId: gallery.name
  }
  dependsOn: [
    galleryRole365
    galleryRoleDC
  ]
}

output id string = devCenter.id
