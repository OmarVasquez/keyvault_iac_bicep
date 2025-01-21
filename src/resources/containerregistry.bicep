param location string = resourceGroup().location
param registryName string
param sku string = 'Basic'
param subnetIdPrivateEndpoint string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: {
    name: sku
  }
  properties: {}
}


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${registryName}'
  location: location
  properties: {
    subnet: {
      id: subnetIdPrivateEndpoint
    }
    privateLinkServiceConnections: [
      {
        name: '${registryName}-connection'
        properties: {

          privateLinkServiceId: containerRegistry.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    customNetworkInterfaceName: 'nic-pe-${registryName}'
  }
}
