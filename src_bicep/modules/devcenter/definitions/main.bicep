// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Definitions
resource definitions 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-04-01' = [for definition in settings.resources.definitions: {
  parent: devcenter
  name: definition.name
  location: location
  properties: {
    imageReference: {
      id: '${devcenter.id}/galleries/default/images/${definition.image}'
    }
    sku: {
      name: skus[definition.sku]
    }
    hibernateSupport: 'Disabled'
  }
}]

// ---------
// Resources
// ---------

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: settings.resources.devcenter.name
}

// ---------
// Variables
// ---------

var skus = {
  '8-vcpu-32gb-ram-256-ssd': 'general_i_8c32gb256ssd_v2'
  '8-vcpu-32gb-ram-512-ssd': 'general_i_8c32gb512ssd_v2'
  '8-vcpu-32gb-ram-1024-ssd': 'general_i_8c32gb1024ssd_v2'
  '8-vcpu-32gb-ram-2048-ssd': 'general_i_8c32gb2048ssd_v2'
  '16-vcpu-64gb-ram-254-ssd': 'general_i_16c64gb256ssd_v2'
  '16-vcpu-64gb-ram-512-ssd': 'general_i_16c64gb512ssd_v2'
  '16-vcpu-64gb-ram-1024-ssd': 'general_i_16c64gb1024ssd_v2'
  '16-vcpu-64gb-ram-2048-ssd': 'general_i_16c64gb2048ssd_v2'
  '32-vcpu-128gb-ram-512-ssd': 'general_i_32c128gb512ssd_v2'
  '32-vcpu-128gb-ram-1024-ssd': 'general_i_32c128gb1024ssd_v2'
  '32-vcpu-128gb-ram-2048-ssd': 'general_i_32c128gb2048ssd_v2'
}

// ----------
// Parameters
// ----------

param settings object
param location string = resourceGroup().location
