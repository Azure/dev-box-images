// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${devcenterName}-${settings.resources.virtualNetwork.name}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        settings.resources.virtualNetwork.addressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: settings.resources.virtualNetwork.subnet.addressPrefix
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
}

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: settings.resources.securityGroup.name
  location: location
  properties: {
    securityRules: []
  }
}

// ----------
// Parameters
// ----------

param settings object
param location string
param devcenterName string

// -------
// Outputs
// -------

output subnetId string = virtualNetwork.properties.subnets[0].id

