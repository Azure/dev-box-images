@description('Name of the attached Network Connection in DevCenter. If not provided, the Network Connection name is used.')
param name string = ''

@description('Name of the DevCenter.')
param devCenterName string

@description('The resource ID of the Network Connection.')
param networkConnectionId string

// Use the network connection name if no name was provided
var attachName = !empty(name) ? name : last(split(networkConnectionId, '/'))

resource devCenter 'Microsoft.DevCenter/devcenters@2022-08-01-preview' existing = {
  name: devCenterName
}

resource networkAttach 'Microsoft.DevCenter/devcenters/attachednetworks@2022-08-01-preview' = {
  name: attachName
  parent: devCenter
  properties: {
    networkConnectionId: networkConnectionId
  }
}
