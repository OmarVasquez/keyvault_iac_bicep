param location string = resourceGroup().location
param identityName string
param vnetName string


var roleDefinitionIdPrivateDNSZoneContributor = 'b12aa53e-6015-4669-85d0-8515ebb3ae7f'

var roleDefinitionIdNetworkContributor = '4d97b98b-1d4f-4787-a291-c67834d212e7'

resource aksManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource aksPrivateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.${location}.azmk8s.io'
  location: 'global'
}

resource vNetAKS 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}



resource privateDnsRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Private DNS Zone Contributor', aksManagedIdentity.id, aksPrivateDNSZone.id)
  scope: aksPrivateDNSZone
  properties: {
    principalId: aksManagedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionIdPrivateDNSZoneContributor)
    
  }
}



resource vnetRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Network Contributor', aksManagedIdentity.id, vNetAKS.id)
  scope: vNetAKS
  properties: {
    principalId: aksManagedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionIdNetworkContributor)
    
  }
}


output aksManagedIdentityId string = aksManagedIdentity.id
