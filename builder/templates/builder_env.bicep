@description('Location for the Compute Gallery. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

param baseName string = 'contoso-images'

@description('The principal id of a service principal used in the image build pipeline. If provided the service principal will be given Owner permissions on the gallery')
param builderPrincipalId string

param defaultSubnetName string = 'default'
param builderSubnetName string = 'builders'

param tags object = {}

var baseNameClean = toLower(replace(replace(baseName, '_', ''), '-', ''))

var keyVaultName = '${baseNameClean}kv'
var storageName = '${baseNameClean}storage'
var vnetName = '${baseName}-vnet'

var builderGroupAssignmentId = guid('groupreader${resourceGroup().id}${baseName}${builderPrincipalId}')
var builderSecretsAssignmentId = guid('kvsecretofficer${resourceGroup().id}${keyVaultName}${builderPrincipalId}')
// var builderStorageAssignmentId = guid('kvsecretofficer${resourceGroup().id}${keyVaultName}${builderPrincipalId}')

var roleIdBase = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions'

var contributorRoleId = '${roleIdBase}/b24988ac-6180-42a0-ab88-20f7382dd24c'
var secretsOfficerRoleId = '${roleIdBase}/b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

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
      addressPrefixes: [ '10.3.0.0/16' ]
    }
    subnets: [
      {
        name: defaultSubnetName
        properties: {
          addressPrefix: '10.3.0.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: builderSubnetName
        properties: {
          addressPrefix: '10.3.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            { service: 'Microsoft.Storage'
              locations: [ 'eastus', 'westus' ] }
            { service: 'Microsoft.KeyVault'
              locations: [ '*' ] }
            { service: 'Microsoft.AzureActiveDirectory'
              locations: [ '*' ] }
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

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
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
  scope: keyvault
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
          privateLinkServiceId: keyvault.id
          groupIds: [
            'vault'
          ]
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
