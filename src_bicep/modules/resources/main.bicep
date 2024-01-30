// ------
// Scopes
// ------

targetScope = 'subscription'

// ---------
// Resources
// ---------

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourseGroupSettings.name
  location: resourseGroupSettings.location
  properties: {}
  tags: resourseGroupSettings.tags
}

// ----------
// Parameters
// ----------

param resourseGroupSettings object
