param location string = resourceGroup().location
param subscriptionId string = subscription().subscriptionId
param environment string
param virtualNetwork object
param keyVaultParams object
param keyVaultSecrets array
param appServiceParams object
param privateEndpointParams object
param containerRegistryParams object
param applicationGatewayParams object
param aksParams object


var vnetName = '${virtualNetwork.name}-${environment}-${location}-01'
var keyVaultName = '${keyVaultParams.name}-${environment}-${location}-02'
var subnetIdPrivateEndpoints = '/subscriptions/${subscriptionId}/resourceGroups/${privateEndpointParams.resourceGroup}/providers/Microsoft.Network/virtualNetworks/${privateEndpointParams.vnet}/subnets/${privateEndpointParams.subnet}'
var subnetIdAppServiceVNetIntegration = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/snet-app01'
var subnetIdApplicationGateway = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/snet-agw'
var subnetIdNodes = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/snet-aks-nodes'
var subnetIdPods = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/snet-aks-pods'

var appServiceName = '${appServiceParams.name}-${environment}-${location}-01'
var appServicePlanName = '${appServiceParams.plan}-${environment}-${location}-01'
var managedIdentityNameAppService = '${appServiceParams.identity}-${environment}-${location}-01'

var containerRegistryName = '${containerRegistryParams.name}${environment}${location}01'

var applicationGatewayName = '${applicationGatewayParams.name}-${environment}-${location}-01'
var managedIdentityNameApplicationGateway = '${applicationGatewayParams.identity}-${environment}-${location}-01'
var publicIpNameApplicationGateway = '${applicationGatewayParams.publicIp}-${environment}-${location}-01'

var aksClusterName = '${aksParams.clusterName}-${environment}-${location}-01'
var managedIdentityNameAKS = '${aksParams.identity}-${environment}-${location}-01'


module vnet './resources/vnet.bicep' = {
  name: 'vnet'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: virtualNetwork.addressPrefix
    subnetPrefixs: virtualNetwork.subnetPrefixs
  }
}


module keyVault './resources/keyvault.bicep' = {
  dependsOn: [
    vnet
  ]
  name: 'keyVault'
  params: {
    location: location
    vaultName: keyVaultName
    sku: keyVaultParams.sku
    subnetId: subnetIdPrivateEndpoints
    secrets: keyVaultSecrets
    vNetName: vnetName

  }
}

module appService './resources/appservice.bicep' = {
  dependsOn: [
    keyVault
  ]
  name: 'appService'
  params: {
    location: location
    appServiceName: appServiceName
    appServicePlanName: appServicePlanName
    appServicePlanSku: appServiceParams.sku
    runtimeStack: appServiceParams.runtimeStack
    keyVaultName:keyVaultName
    secrets: appServiceParams.secrets
    subnetIdPrivateEndpoint: subnetIdPrivateEndpoints
    identity: managedIdentityNameAppService
    subnetIdVnetIntegration: subnetIdAppServiceVNetIntegration
    vNetName: vnetName
  }
}

module roleKeyVaultUser 'resources/keyvault-roleassigment.bicep' = {
  dependsOn: [
    keyVault
    appService
  ]
  name: 'roleKeyVaultUser'
  params: {
    keyVaultName: keyVaultName
    principalId: appService.outputs.appServiceIdentityPrincipalId
    roleName: 'Key Vault Secrets User'
  }
}


module containerRegistry './resources/containerregistry.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    registryName: containerRegistryName
    sku: containerRegistryParams.sku
    subnetIdPrivateEndpoint: subnetIdPrivateEndpoints
  }
}


module applicationGateway './resources/applicationgateway.bicep' = {
  name: 'applicationGateway'
  
  params: {
    location:location
    gatewayName: applicationGatewayName
    skuName: applicationGatewayParams.sku
    identityName:managedIdentityNameApplicationGateway
    publicIpName: publicIpNameApplicationGateway
    subnetId: subnetIdApplicationGateway
    keyVaultName: keyVaultName
  }
}

module aksRoleAssigments './resources/aks-roleassigment.bicep' = {
  name: 'aksRoleAssigments'
  params: {
    identityName: managedIdentityNameAKS
    vnetName: vnetName
  }
}


module aks './resources/aks.bicep' = {
  name: 'aks'
  params: {
    clusterName: aksClusterName
    nodeCountSystem: aksParams.nodeCountSystem
    nodeCountUser: aksParams.nodeCountUser
    kubernetesVersion: aksParams.kubernetesVersion
    vmSizeNodeSystem: aksParams.vmSizeNodeSystem
    vmSizeNodeUser: aksParams.vmSizeNodeUser
    aksManagedIdentityId:aksRoleAssigments.outputs.aksManagedIdentityId
    sku: aksParams.sku
    vnetSubnetIdNodes: subnetIdNodes
    vnetSubnetIdPods: subnetIdPods
    applicationGatewayId: applicationGateway.outputs.applicationGatewayId
  }
}





// module privateEndpoints './resources/privateendpoints.bicep' = {
//   name: 'privateEndpoints'
//   params: {
//     privateEndpointName: privateEndpointName
//     subnetId: subnetId
//     resourceToConnect: keyVault.outputs.vaultId
//   }
// }

// module roleAssignments './resources/roleassignments.bicep' = {
//   name: 'roleAssignments'
//   params: {
//     roleDefinitionId: roleDefinitionId
//     principalId: principalId
//     scope: keyVault.outputs.vaultId
//   }
// }
