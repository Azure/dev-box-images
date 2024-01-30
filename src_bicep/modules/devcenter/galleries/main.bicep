// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// DevCenter Galleries
resource galleries 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = [for galleryId in galleryIds: {
  parent: devcenter
  name: split(galleryId, '/')[8]
  properties: {
    galleryResourceId: galleryId
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
param galleryIds array = []
