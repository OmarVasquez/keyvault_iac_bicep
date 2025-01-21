param location string = resourceGroup().location
param clusterName string
param nodeCountSystem int = 1
param nodeCountUser int = 1
param kubernetesVersion string = '1.30.7'
param vmSizeNodeSystem string = 'Standard_DS2_v3'
param vmSizeNodeUser string = 'Standard_DS2_v3'
param aksManagedIdentityId string
param sku string = 'Free'
param maxPodsSystem int = 110
param maxPodsUser int = 30
param vnetSubnetIdNodes string
param vnetSubnetIdPods string
param applicationGatewayId string
param serviceCidr string = '11.0.0.0/16'
param dnsServiceIp string = '11.0.0.10'




resource aksPrivateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.${location}.azmk8s.io'
}


resource aks 'Microsoft.ContainerService/managedClusters@2024-07-01' = {
  name: clusterName
  location: location
  properties: {
    dnsPrefix: clusterName
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCountSystem
        vmSize: vmSizeNodeSystem
        osType: 'Linux'
        maxPods: maxPodsSystem
        mode: 'System'
        vnetSubnetID: vnetSubnetIdNodes
        podSubnetID: vnetSubnetIdPods
        availabilityZones: []
        
      }
      {
        name: 'userpool'
        count: nodeCountUser
        vmSize: vmSizeNodeUser
        osType: 'Linux'
        maxPods: maxPodsUser
        mode: 'User'
        vnetSubnetID: vnetSubnetIdNodes
        podSubnetID: vnetSubnetIdPods
        availabilityZones: []
      }
    ]
    
    networkProfile: {
      networkPlugin: 'azure'
      networkDataplane: 'azure'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIp
      outboundType: 'loadBalancer'
    }

    apiServerAccessProfile: {
      //enablePrivateClusterPublicFQDN: true
      //enableVnetIntegration: true
      //privateDNSZone:aksPrivateDNSZone.id
      enablePrivateCluster: false
      //subnetId: vnetSubnetIdNodes
    }

    addonProfiles: {
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: applicationGatewayId
        }
      }
      
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksManagedIdentityId}': {}
    }
  }
  sku: {
    name: 'Base'
    tier: sku
  }
}

output aksFqdn string = aks.properties.fqdn

