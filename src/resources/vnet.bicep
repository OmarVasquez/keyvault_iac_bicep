param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefix string
param subnetPrefixs object

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-default'
        properties: {
          addressPrefix: subnetPrefixs.snetDefault
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: subnetPrefixs.snetPrivateEndpoints
        }
      }
      {
        name: 'snet-app01'
        properties: {
          addressPrefix: subnetPrefixs.snetApp01
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'snet-aks-nodes'
        properties: {
          addressPrefix: subnetPrefixs.snetAksNodes
        }
      }
      {
        name: 'snet-aks-pods'
        properties: {
          addressPrefix: subnetPrefixs.snetAksPods
        }
      }
      {
        name: 'snet-agw'
        properties: {
          addressPrefix: subnetPrefixs.snetAgw
        }
      }
    ]
  }
}
