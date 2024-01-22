// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries.')
param container string = 'ghcr.io/Azure/dev-box-images/builder'

@secure()
@description('The git repository that contains your image.yml and buiild scripts.')
param repository string

@description('Commit hash for the specified revision for the repository.')
param revision string = ''

@description('The name of the image to build. This should match the name of a folder inside the /images folder in your repository.')
param image string

@description('The client (app) id for the service principal to use for authentication.')
param clientId string

@secure()
@description('The secret for the service principal to use for authentication.')
param clientSecret string

@description('The name of an existing storage account to use with the container instance. If not specified, the container instance will not mount a persistant file share.')
param storageAccount string = ''

@description('The resource id of a subnet to use for the container instance. If this is not specified, the container instance will not be created in a virtual network and have a public ip address.')
param subnetId string = ''

@description('The version of the image to build.')
param version string = 'latest'

param timestamp string = utcNow()

@description('Packer variables in the form of key: value pairs to forward to packer when executing packer build the container instance.')
param packerVars object = {}

var validImageName = replace(image, '_', '-')
var validImageNameLower = toLower(validImageName)

var defaultEnvironmentVars = [
  { name: 'BUILD_IMAGE_NAME', value: image }
  { name: 'AZURE_TENANT_ID', value: tenant().tenantId }
  { name: 'AZURE_CLIENT_ID', value: clientId }
  { name: 'AZURE_CLIENT_SECRET', secureValue: clientSecret }
]

var packerEnvironmentVars = [for kv in items(packerVars): {
  name: 'PKR_VAR_${kv.key}'
  value: kv.value
}]

var environmentVars = empty(packerEnvironmentVars) ? defaultEnvironmentVars : concat(defaultEnvironmentVars, packerEnvironmentVars)

var repoVolume = {
  name: 'repo'
  gitRepo: {
    repository: repository
    directory: '.'
    revision: (!empty(revision) ? revision : null)
  }
}

var repoVolumeMount = {
  name: 'repo'
  mountPath: '/mnt/repo'
  readOnly: false
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = if (!empty(storageAccount)) {
  name: empty(storageAccount) ? 'storageAccount' : storageAccount
  resource fileServices 'fileServices' = {
    name: 'default'
    resource fileShare 'shares' = {
      name: validImageNameLower
    }
  }
}

resource group 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: validImageName
  location: location
  tags: {
    version: version
    timestamp: timestamp
  }
  properties: {
    subnetIds: (!empty(subnetId) ? [
      {
        id: subnetId
      }
    ] : null)
    containers: [
      {
        name: validImageNameLower
        properties: {
          image: container
          ports: (empty(subnetId) ? [
            {
              port: 80
              protocol: 'TCP'
            }
          ] : null)
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          volumeMounts: empty(storageAccount) ? [ repoVolumeMount ] : [
            repoVolumeMount
            {
              name: 'storage'
              mountPath: '/mnt/storage'
              readOnly: false
            }
          ]
          environmentVariables: environmentVars
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Never'
    ipAddress: (empty(subnetId) ? {
      type: 'Public'
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
    } : null)
    volumes: empty(storageAccount) ? [ repoVolume ] : [
      repoVolume
      {
        name: 'storage'
        azureFile: {
          shareName: (!empty(storageAccount) ? storage::fileServices::fileShare.name : null)
          storageAccountName: (!empty(storageAccount) ? storage.name : null)
          storageAccountKey: (!empty(storageAccount) ? storage.listKeys().keys[0].value : null)
          readOnly: false
        }
      }
    ]
  }
}

output logs string = 'az container logs -g ${resourceGroup().name} -n ${validImageName}'
