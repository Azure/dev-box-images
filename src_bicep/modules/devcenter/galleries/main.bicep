// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// DevCenter Galleries
resource galleries 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  parent: devcenter
  name: split(gallery.id, '/')[8]
  properties: {
    galleryResourceId: gallery.id
  }
}

// ---------
// Resources
// ---------

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: settings.resources.devcenter.name
}

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: galeryName
}

// ----------
// Parameters
// ----------

param settings object
param galeryName string
