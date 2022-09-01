// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@maxLength(63)
@description('Name of the Gallery in DevCenter. If not provided, the Compute Gallery name is used.')
param name string = ''

@minLength(3)
@maxLength(26)
@description('Name of the DevCenter.')
param devCenterName string

@minLength(90)
@description('The resource ID of the backing Azure Compute Gallery.')
param galleryResourceId string

// Use the gallery name if no name was provided
var attachName = !empty(name) ? name : last(split(galleryResourceId, '/'))

resource devCenter 'Microsoft.DevCenter/devcenters@2022-08-01-preview' existing = {
  name: devCenterName
}

resource galleryAttach 'Microsoft.DevCenter/devcenters/galleries@2022-08-01-preview' = {
  name: attachName
  parent: devCenter
  properties: {
    galleryResourceId: galleryResourceId
  }
}
