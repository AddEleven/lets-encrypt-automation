param applicationGateways_agw_adtest_001_name string
param virtualNetworks_vnet_adtest_001_externalid string
param publicIPAddresses_pip_adtest_001_externalid string

resource applicationGateways_agw_adtest_001_name_resource 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: applicationGateways_agw_adtest_001_name
  location: 'australiaeast'
  zones: [
    '1'
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/1111111-1111-1111-11111-1111111111/resourcegroups/rg-adtest-001/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uid-adtest-001': {}
    }
  }
  properties: {
    sku: {
      name: 'Basic'
      tier: 'Basic'
      family: 'Generation_1'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/gatewayIPConfigurations/appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${virtualNetworks_vnet_adtest_001_externalid}/subnets/default'
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'cert-blog-alexdantico-com'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/sslCertificates/cert-blog-alexdantico-com'
        properties: {
          keyVaultSecretId: 'https://kv.vault.azure.net/secrets/cert-blog-alexdantico-com'
        }
      }
    ]
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_pip_adtest_001_externalid
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/frontendPorts/port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appsvc-adtest-001'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/backendAddressPools/appsvc-adtest-001'
        properties: {
          backendAddresses: [
            {
              fqdn: 'adtest-appservice-001.azurewebsites.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backend-appsvc-001'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/backendHttpSettingsCollection/backend-appsvc-001'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: '${applicationGateways_agw_adtest_001_name_resource.id}/probes/appsvc-001'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'listener-appsvc-001'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/httpListeners/listener-appsvc-001'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGateways_agw_adtest_001_name_resource.id}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
          }
          frontendPort: {
            id: '${applicationGateways_agw_adtest_001_name_resource.id}/frontendPorts/port_443'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGateways_agw_adtest_001_name_resource.id}/sslCertificates/cert-blog-alexdantico-com'
          }
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'urle-appsvc-001'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/requestRoutingRules/urle-appsvc-001'
        properties: {
          ruleType: 'Basic'
          priority: 111
          httpListener: {
            id: '${applicationGateways_agw_adtest_001_name_resource.id}/httpListeners/listener-appsvc-001'
          }
          backendAddressPool: {
            id: '${applicationGateways_agw_adtest_001_name_resource.id}/backendAddressPools/appsvc-adtest-001'
          }
          backendHttpSettings: {
            id: '${applicationGateways_agw_adtest_001_name_resource.id}/backendHttpSettingsCollection/backend-appsvc-001'
          }
        }
      }
    ]
    probes: [
      {
        name: 'appsvc-001'
        id: '${applicationGateways_agw_adtest_001_name_resource.id}/probes/appsvc-001'
        properties: {
          protocol: 'Https'
          host: 'blog.alexdantico.com'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    enableHttp2: true
  }
}
