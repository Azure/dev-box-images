// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Location for the resources. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

// ex. contoso-images
@description('The prefix to use in the name of all resources created. For example if Contoso-Images is provided, a key vault, storage account, and vnet will be created and named Contoso-Images-kv, contosoimagesstorage, and contoso-images-vent respectively.')
param baseName string

@description('The principal id of a service principal used in the image build pipeline. It will be givin contributor role to the resource group, and the appropriate permissions on the key vault and storage account')
param builderPrincipalId string

param vnetAddressPrefixes array = [ '10.0.0.0/24' ] // 256 addresses

param defaultSubnetName string = 'default'
param defaultSubnetAddressPrefix string = '10.0.0.0/25' // 123 + 5 Azure reserved addresses

param builderSubnetName string = 'builders'
param builderSubnetAddressPrefix string = '10.0.0.128/25' // 123 + 5 Azure reserved addresses

@description('Tags to be applied to all created resources.')
param tags object = {}

var baseNameLower = toLower(trim(baseName)) // ex. 'Contoso Images' -> 'contoso images'
var baseNameLowerNoSpace = replace(baseNameLower, ' ', '-') // ex. 'contoso images' -> 'contoso-images'
var baseNameLowerNoSpaceHyphen = replace(baseNameLowerNoSpace, '_', '-') // ex. 'contoso-images' or 'contoso_images' -> 'contoso-images'
var baseNameLowerAlphaNum = replace(baseNameLowerNoSpaceHyphen, '-', '') // ex. 'contoso-images' -> 'contosoimages'

// ex. contoso-images-kv
// req: (3-24) Alphanumerics and hyphens. Start with letter. End with letter or digit. Can't contain consecutive hyphens. Globally unique.
var baseNameLowerNoSpaceHyphenLength = length(baseNameLowerNoSpaceHyphen)
var keyVaultName = baseNameLowerNoSpaceHyphenLength <= 21 ? '${baseNameLowerNoSpaceHyphen}-kv' : baseNameLowerNoSpaceHyphenLength <= 24 ? baseNameLowerNoSpaceHyphen : take(baseNameLowerNoSpaceHyphen, 24)

// ex. contosoimagesstorage
// req: (3-24) Lowercase letters and numbers only. Globally unique.
var baseNameLowerAlphaNumLength = length(baseNameLowerAlphaNum)
var storageName = baseNameLowerAlphaNumLength <= 17 ? '${baseNameLowerAlphaNum}storage' : baseNameLowerAlphaNumLength <= 20 ? '${baseNameLowerAlphaNum}stor' : baseNameLowerAlphaNumLength <= 24 ? baseNameLowerAlphaNum : take(baseNameLowerAlphaNum, 24)

// ex. contoso-images-vnet
// req: (2-64) Alphanumerics, underscores, periods, and hyphens. Start with alphanumeric. End alphanumeric or underscore. Resource Group unique.
var vnetName = '${baseNameLowerNoSpace}-vnet'

// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer
var secretsOfficerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')

var builderGroupAssignmentId = guid('groupreader${resourceGroup().id}${baseName}${builderPrincipalId}')
var builderSecretsAssignmentId = guid('kvsecretofficer${resourceGroup().id}${keyVaultName}${builderPrincipalId}')

resource builderGroupAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(builderPrincipalId)) {
  name: builderGroupAssignmentId
  properties: {
    principalId: builderPrincipalId
    roleDefinitionId: contributorRoleId
  }
  scope: resourceGroup()
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
      {
        name: defaultSubnetName
        properties: {
          addressPrefix: defaultSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: builderSubnetName
        properties: {
          addressPrefix: builderSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            { service: 'Microsoft.Storage', locations: [ location ] }
            { service: 'Microsoft.KeyVault', locations: [ '*' ] }
            { service: 'Microsoft.AzureActiveDirectory', locations: [ '*' ] }
          ]
          delegations: [
            {
              name: 'Microsoft.ContainerInstance/containerGroups'
              properties: { serviceName: 'Microsoft.ContainerInstance/containerGroups' }
            }
          ]
        }
      }
    ]
  }
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
  tags: tags
}

resource builderKeyVaultAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(builderPrincipalId)) {
  name: builderSecretsAssignmentId
  properties: {
    principalId: builderPrincipalId
    roleDefinitionId: secretsOfficerRoleId
  }
  scope: keyVault
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/${builderSubnetName}'
          action: 'Allow'
        }
      ]
    }
  }
  tags: tags
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags

  resource privateDnsZoneLink 'virtualNetworkLinks' = {
    name: '${vnet.name}-dnslink'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: { id: vnet.id }
    }
    tags: tags
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: '${vnet.name}-pe-${defaultSubnetName}'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${defaultSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${vnet.name}-pe-${defaultSubnetName}-kv'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [ 'vault' ]
        }
      }
    ]
  }
  tags: tags

  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: '${vnet.name}-pe-${defaultSubnetName}-dnsgroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'privatelink.vaultcore.azure.net'
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}

@description('The value for the buildResourceGroup property in the images.yml and image.yml file.')
output buildResourceGroup string = resourceGroup().name

@description('The value for the string property in the images.yml and image.yml file.')
output keyVault string = keyVault.name

@description('The value for the virtualNetwork property in the images.yml and image.yml file.')
output virtualNetwork string = vnet.name

@description('The value for the virtualNetworkSubnet property in the images.yml and image.yml file.')
output virtualNetworkSubnet string = defaultSubnetName

@description('The value for the virtualNetworkResourceGroup property in the images.yml and image.yml file.')
output virtualNetworkResourceGroup string = resourceGroup().name

@description('The value for the subscription property in the images.yml and image.yml file.')
output subscription string = az.subscription().subscriptionId

@description('The storage account name to pass as the value for the --storage-account argument when executing aci.py')
output aciStorageAccount string = storage.name

@description('The subnet id to pass as the value for the --subnet-id argument when executing aci.py')
output aciSubnetId string = '${vnet.id}/subnets/${builderSubnetName}'
