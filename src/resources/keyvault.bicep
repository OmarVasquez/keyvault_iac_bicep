param location string = resourceGroup().location
param vaultName string
param sku string = 'standard'
param subnetId string
param secrets array


resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: sku
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      //defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vault.azure.net'
  location: 'global'
  properties: {}
}


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${vaultName}'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${vaultName}-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    customNetworkInterfaceName: 'nic-pe-${vaultName}'
  }
}


resource privateDnsZoneLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent:privateEndpoint
  name: 'keyVaulDNSGroup'
  properties: {
    privateDnsZoneConfigs:[
      {
        name: '${privateDnsZone.name}-link'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}


resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in secrets: {
  parent: keyVault
  name: secret.name
  properties: {
    value: secret.value
  }
}]



output keyVaultId string = keyVault.id
