param location string = resourceGroup().location
param gatewayName string
param skuName string = 'Standard_v2'
param skuTier string = 'Standard_v2'
param frontendIpConfigName string = 'frontendIpConfig'
param backendAddressPoolName string = 'backendAddressPool'
param httpListenerName string = 'httpListener'
param frontendPortName string = 'frontendPort'
param requestRoutingRuleName string = 'requestRoutingRule'
param identityName string
param subnetId string
param publicIpName string
param maxCapacity int = 2
param backendHttpSettingsName string= 'bes-default'
param keyVaultName string
//param certificateInKeyVaultName string

var applicationGatewayFrontendIPConfigurationId = resourceId(
  'Microsoft.Network/applicationGateways/frontendIPConfigurations',
  gatewayName,
  frontendIpConfigName
)

var applicationGatewayFrontendPortId = resourceId(
  'Microsoft.Network/applicationGateways/frontendPorts',
  gatewayName,
  frontendPortName
)

var applicationGatewayHttpListenerId = resourceId(
  'Microsoft.Network/applicationGateways/httpListeners',
  gatewayName,
  httpListenerName
)

var applicationGatewayBackendAddressPoolId = resourceId(
  'Microsoft.Network/applicationGateways/backendAddressPools',
  gatewayName,
  backendAddressPoolName
)

var applicationGatewayBackendHttpSettingsId = resourceId(
  'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
  gatewayName,
  backendHttpSettingsName
)


resource agwManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

module roleKeyVaultUser 'keyvault-roleassigment.bicep' = {
  name: 'roleKeyVaultUser'
  params: {
    keyVaultName: keyVaultName
    principalId: agwManagedIdentity.properties.principalId
    roleName: 'Key Vault Secrets User'
  }
}

// resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
//   name: keyVaultName
// }

// resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' existing = {
//   parent: keyVault
//   name: certificateInKeyVaultName
// }


resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}


resource applicationGateway 'Microsoft.Network/applicationGateways@2024-05-01' = {
  dependsOn: [
    roleKeyVaultUser
  ]
  name: gatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${agwManagedIdentity.id}': {}
    }
  }
  
  properties: {
    sku: {
      name: skuName
      tier: skuTier
      //capacity: 1
    }
  
    gatewayIPConfigurations: [
      {
        name: 'gatewayIpConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIpConfigName
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPoolName
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsName
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortName
        properties: {
          port: 80
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: maxCapacity
    }
    httpListeners: [
      {
        name: httpListenerName
        properties: {
          frontendIPConfiguration: {
            id: applicationGatewayFrontendIPConfigurationId
          }
          frontendPort: {
            id: applicationGatewayFrontendPortId
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: requestRoutingRuleName
        properties: {
          priority: 100
          ruleType: 'Basic'
          httpListener: {
            id: applicationGatewayHttpListenerId
          }
          backendAddressPool: {
            id: applicationGatewayBackendAddressPoolId
          }
          backendHttpSettings: {
            id: applicationGatewayBackendHttpSettingsId
          }
        }
      }
    ]
    // sslCertificates: [
    //   {
    //     name: certificateInKeyVaultName
    //     properties: {
    //       keyVaultSecretId: keyVaultSecret.id
    //     }
    //   }
    // ]
  }
  tags: {}

}


output applicationGatewayId string = applicationGateway.id
output applicationGatewayManagedIdentityPrincipalId string = agwManagedIdentity.properties.principalId
