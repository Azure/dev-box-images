// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Pools
resource pools 'Microsoft.DevCenter/projects/pools@2023-04-01' = [for pool in project.pools: {
  name: pool.name
  location: location
  parent: parent
  properties: {
    devBoxDefinitionName: pool.definition
    licenseType: 'Windows_Client'
    localAdministrator: pool.administrator
    networkConnectionName: connectionName
    stopOnDisconnect: {
      status: 'Disabled'
    }
  }
}]

// ---------
// Resources
// ---------

resource parent 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: project.name
}

// ----------
// Parameters
// ----------

param project object
param location string
param connectionName string
