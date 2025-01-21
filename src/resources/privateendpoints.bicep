param location string = resourceGroup().location
param privateEndpointName string
param subnetId string
param resourceId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: resourceId
          groupIds: [
            'vault' // Adjust this based on the resource type
          ]
        }
      }
    ]
  }
}
