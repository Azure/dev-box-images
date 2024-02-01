// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Location for the Dev Box Definition. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(63)
@description('Dev Box Definition name')
param name string

@minLength(3)
@maxLength(26)
@description('The resource ID of the DevCenter.')
param devCenterName string

@minLength(3)
@maxLength(63)
@description('The name of the gallery.')
param galleryName string

@minLength(3)
@maxLength(63)
@description('The name of the image in the gallery to use.')
param imageName string

@description('The version of the image to use. If none is provided, the latest version will be used.')
param imageVersion string = 'latest'

@allowed([ '256', '512', '1024' ])
@description('The storage in GB used for the Operating System disk of Dev Boxes created using this definition.')
param storage string = '1024'

@allowed([ '4c16gb', '8c32gb' ])
@description('The specs on the of Dev Boxes created using this definition. For example 8c32gb would create dev boxes with 8 vCPUs and 32 GB RAM.')
param compute string = '8c32gb'

@description('Tags to apply to the resources')
param tags object = {}

var versionSuffix = (empty(imageVersion) || toLower(imageVersion) == 'latest') ? '' : '/versions/${imageVersion}'
var skuName = 'general_a_${compute}_v1'
var osStorageType = 'ssd_${storage}gb'

resource devCenter 'Microsoft.DevCenter/devcenters@2022-08-01-preview' existing = {
  name: devCenterName
}

resource gallery 'Microsoft.DevCenter/devcenters/galleries@2022-08-01-preview' existing = {
  name: galleryName
  parent: devCenter
}

resource image 'Microsoft.DevCenter/devcenters/galleries/images@2022-08-01-preview' existing = {
  name: imageName
  parent: gallery
}

resource definition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2022-08-01-preview' = {
  name: name
  parent: devCenter
  location: location
  properties: {
    sku: { name: skuName }
    imageReference: {
      id: '${image.id}${versionSuffix}'
    }
    osStorageType: osStorageType
  }
  tags: tags
}
