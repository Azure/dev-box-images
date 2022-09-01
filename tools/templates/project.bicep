// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

@sys.description('Location of the Project. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(63)
@sys.description('Name of the Project')
param name string

@minLength(113)
@sys.description('The Resource ID of the DevCenter.')
param devCenterId string

@sys.description('The description of the Project.')
param description string = ''

@sys.description('The principal ids of users to assign the role of DevCenter Project Admin.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param projectAdmins array = []

@sys.description('The principal ids of users to assign the role of DevCenter Dev Box User.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param devBoxUsers array = []

@sys.description('Tags to apply to the resources')
param tags object = {}

resource project 'Microsoft.DevCenter/projects@2022-08-01-preview' = {
  name: name
  location: location
  properties: {
    devCenterId: devCenterId
    description: (!empty(description) ? description : null)
  }
  tags: tags
}

module projectAdminAssignments 'projectRole.bicep' = [for admin in projectAdmins: {
  name: admin
  params: {
    projectName: project.name
    principalId: admin
    role: 'ProjectAdmin'
  }
}]

module devBoxUserAssignments 'projectRole.bicep' = [for user in devBoxUsers: {
  name: user
  params: {
    projectName: project.name
    principalId: user
    role: 'DevBoxUser'
  }
}]
