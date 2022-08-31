// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Location for the Virtual Network. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(2)
@maxLength(64)
@description('The name of the Azure Virtual Network.')
param name string

@minLength(1)
param addressPrefixes array = [ '10.4.0.0/16' ]

@minLength(1)
@maxLength(80)
param subnetName string = 'default'
param subnetAddressPrefix string = '10.4.0.0/24' // 250 + 5 Azure reserved addresses

@description('Tags to apply to the resources')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
  tags: tags
}

output id string = vnet.id
output subnet string = subnetName
output subnetId string = '${vnet.id}/subnets/${subnetName}'
