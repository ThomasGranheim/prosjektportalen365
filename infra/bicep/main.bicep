// Main Bicep template for Azure Container Apps development environment
targetScope = 'resourceGroup'

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container Registry name')
param containerRegistryName string

@description('Container Apps Environment name')
param containerAppsEnvironmentName string

@description('Container App name for SPFx development')
param spfxDevAppName string = 'spfx-dev-app'

@description('Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Tags to apply to all resources')
param tags object = {
  environment: environmentName
  project: 'prosjektportalen365'
  managedBy: 'bicep'
}

// Deploy Log Analytics Workspace for monitoring
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalytics-deployment'
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    tags: tags
  }
}

// Deploy Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry-deployment'
  params: {
    registryName: containerRegistryName
    location: location
    tags: tags
  }
}

// Deploy Container Apps Environment
module containerAppsEnvironment 'modules/container-apps-environment.bicep' = {
  name: 'containerAppsEnvironment-deployment'
  params: {
    environmentName: containerAppsEnvironmentName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Deploy SPFx Development Container App
module spfxDevApp 'modules/container-app.bicep' = {
  name: 'spfxDevApp-deployment'
  params: {
    containerAppName: spfxDevAppName
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.environmentId
    containerRegistryName: containerRegistryName
    containerImage: '${containerRegistryName}.azurecr.io/spfx-dev:latest'
    tags: tags
    targetPort: 4321
    enableIngress: true
    externalIngress: true
    minReplicas: 0
    maxReplicas: 1
  }
  dependsOn: [
    containerRegistry
  ]
}

// Outputs
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.environmentId
output spfxDevAppFqdn string = spfxDevApp.outputs.fqdn
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
