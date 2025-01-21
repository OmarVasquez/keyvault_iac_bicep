param location string = resourceGroup().location
param appServiceName string
param appServicePlanName string
param appServicePlanSku string
param runtimeStack string
param identity string
param secrets array
param keyVaultName string
param subnetIdPrivateEndpoint string
param subnetIdVnetIntegration string
param vNetName string


resource appServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identity
  location: location
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true

  }
  sku: {
    name: appServicePlanSku
    capacity: 1   
  }
  kind: 'linux'
}


resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        for secret in secrets: {
          name: secret
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${secret})'
        }
      ]
      linuxFxVersion: runtimeStack
      vnetRouteAllEnabled: true
    }
    keyVaultReferenceIdentity: appServiceIdentity.id
    virtualNetworkSubnetId: subnetIdVnetIntegration
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appServiceIdentity.id}':{}
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
  properties: {}
}

resource vNet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vNetName
}

resource privateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: 'link-${ toLower(vNetName) }'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${appServiceName}'
  location: location
  properties: {
    subnet: {
      id: subnetIdPrivateEndpoint
    }
    privateLinkServiceConnections: [
      {
        name: '${appServiceName}-connection'
        properties: {

          privateLinkServiceId: appService.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    customNetworkInterfaceName: 'nic-pe-${appServiceName}'
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent:privateEndpoint
  name: 'AppServiceDNSGroup'
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

output appServiceId string = appService.id
output appServiceIdentityId string = appServiceIdentity.id
output appServiceIdentityPrincipalId string = appServiceIdentity.properties.principalId
