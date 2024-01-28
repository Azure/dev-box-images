// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: settings.resources.managedIdentity.name
  location: settings.resourceGroup.location
}

// ----------
// Parameters
// ----------

param settings object

// -------
// Outputs
// -------

output identityId string = managedIdentity.id
