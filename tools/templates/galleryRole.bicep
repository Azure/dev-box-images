// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@minLength(36)
@maxLength(36)
@description('The principal id of the Service Principal to assign permissions to the Gallery.')
param principalId string

@maxLength(80)
@description('Name of an existing Azure Compute Gallery.')
param galleryName string

@allowed([ 'Reader', 'Contributor', 'Owner' ])
@description('The Role to assign.')
param role string = 'Reader'

var assignmentId = guid('gallery${role}${resourceGroup().id}${galleryName}${principalId}')

// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader
var readerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner
var ownerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

var roleId = role == 'Owner' ? ownerRoleId : role == 'Contributor' ? contributorRoleId : readerRoleId

resource gallery 'Microsoft.Compute/galleries@2022-01-03' existing = {
  name: galleryName
}

resource galleryAssignmentId 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: assignmentId
  properties: {
    roleDefinitionId: roleId
    principalId: principalId
  }
  scope: gallery
}
