// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Projects
resource projects 'Microsoft.DevCenter/projects@2023-04-01' = [for project in settings.resources.projects: {
  name: project.name
  location: location
  properties: {
    devCenterId: devcenter.id
    description: project.description
  }
}]

// -------
// Modules
// -------

module pools './pools/main.bicep' = [for (project, index) in settings.resources.projects: {
  name: 'Microsoft.DevCenter.Projects.${index}.Pools'
  params: {
    project: project
    location: location
    connectionName: settings.resources.networkConnection.name
  }
}]

// ---------
// Resources
// ---------

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: settings.resources.devcenter.name
}

// ----------
// Parameters
// ----------

param settings object
param location string = resourceGroup().location

