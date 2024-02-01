// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@description('Location for the Network Connection. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(63)
@description('Network connection name')
param name string

@minLength(114)
@description('The resource ID of the VNet')
param vnetId string

@minLength(1)
@maxLength(80)
@description('Name of the subnet to use. If none is provided uses default')
param subnet string = 'default'

@maxLength(90)
@description('Name of the resource group in which the NICs will be created. This should NOT be an existing resource group, it will be created by the service in the same subscription as your vnet. If not provided a name will automatically be generated based on the vnet name and region.')
param networkingResourceGroupName string = ''

@allowed([ 'AzureADJoin', 'HybridAzureADJoin' ])
@description('Active Directory join type')
param domainJoinType string = 'AzureADJoin'

@description('The resource ID of an existing DevCenter. If provided, the network connection will be attached to the DevCenter')
param devCenterId string = ''

@description('Tags to apply to the resources')
param tags object = {}

var devCenterName = empty(devCenterId) ? 'devCenterName' : last(split(devCenterId, '/'))
var devCenterGroup = empty(devCenterId) ? '' : first(split(last(split(replace(devCenterId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))
var devCenterSub = empty(devCenterId) ? '' : first(split(last(split(devCenterId, '/subscriptions/')), '/'))

resource networkConnection 'Microsoft.DevCenter/networkConnections@2022-08-01-preview' = {
  name: name
  location: location
  properties: {
    subnetId: '${vnetId}/subnets/${subnet}'
    networkingResourceGroupName: (!empty(networkingResourceGroupName) ? networkingResourceGroupName : null)
    domainJoinType: domainJoinType
  }
  tags: tags
}

// If a devcenter resource id was provided attach the nc to the devcenter
module networkAttach 'networkAttach.bicep' = if (!empty(devCenterId)) {
  scope: resourceGroup(devCenterSub, devCenterGroup)
  name: '${name}-attach'
  params: {
    name: name
    devCenterName: devCenterName
    networkConnectionId: networkConnection.id
  }
}

output networkConnectionId string = networkConnection.id
