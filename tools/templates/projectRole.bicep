// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@minLength(36)
@maxLength(36)
@description('The principal id of the User to assign permissions to the Project.')
param principalId string

@minLength(3)
@maxLength(63)
@description('The Project name.')
param projectName string

@allowed([ 'ProjectAdmin', 'DevBoxUser' ])
@description('The Role assignment to assign the user. Defaults to DevBoxUser')
param role string = 'DevBoxUser'

@allowed([ 'Device', 'ForeignGroup', 'Group', 'ServicePrincipal', 'User' ])
@description('The principal type of the assigned principal ID.')
param principalType string = 'User'

var assignmentId = guid('project${role}${resourceGroup().id}${projectName}${principalId}')

var projectAdminRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '331c37c6-af14-46d9-b9f4-e1909e1b95a0')
var devBoxUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '45d50f46-0b78-4001-a660-4198cbe8cd05')

var roleId = role == 'ProjectAdmin' ? projectAdminRoleId : devBoxUserRoleId

resource project 'Microsoft.DevCenter/projects@2022-08-01-preview' existing = {
  name: projectName
}

resource projectAssignmentId 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: assignmentId
  properties: {
    roleDefinitionId: roleId
    principalId: principalId
    principalType: principalType
  }
  scope: project
}
