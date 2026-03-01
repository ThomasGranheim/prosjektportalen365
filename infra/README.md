# Azure Container Apps Infrastructure for Prosjektportalen365 Dev Environment

This directory contains Infrastructure as Code (IaC) for setting up a development environment for Prosjektportalen365 using Azure Container Apps.

## 📋 Overview

The infrastructure includes:
- **Azure Container Apps Environment**: Managed environment for running containers
- **Azure Container Registry (ACR)**: Private container registry for storing Docker images
- **Log Analytics Workspace**: Centralized logging and monitoring
- **SPFx Development Container App**: Container app for SharePoint Framework development

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Resource Group                            │
│                                                               │
│  ┌──────────────────┐    ┌─────────────────────────────┐   │
│  │ Log Analytics    │◄───│  Container Apps Environment │   │
│  │ Workspace        │    │                             │   │
│  └──────────────────┘    │  ┌──────────────────────┐  │   │
│                           │  │  SPFx Dev App        │  │   │
│  ┌──────────────────┐    │  │  (Container App)     │  │   │
│  │ Azure Container  │◄───┤  └──────────────────────┘  │   │
│  │ Registry (ACR)   │    │                             │   │
│  └──────────────────┘    └─────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Directory Structure

```
infra/
├── bicep/
│   ├── main.bicep                           # Main Bicep template
│   ├── parameters.dev.json                  # Dev environment parameters
│   └── modules/
│       ├── log-analytics.bicep              # Log Analytics Workspace
│       ├── container-registry.bicep         # Azure Container Registry
│       ├── container-apps-environment.bicep # Container Apps Environment
│       └── container-app.bicep              # Container App
├── Dockerfile                               # Multi-stage Dockerfile for SPFx
├── docker-compose.yml                       # Local development setup
├── deploy.sh                                # Deployment script
├── build-and-push.sh                        # Build and push Docker image
└── README.md                                # This file
```

## 🚀 Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az --version
   az login
   ```

2. **Docker** installed (for building images)
   ```bash
   docker --version
   ```

3. **jq** installed (for parsing JSON)
   ```bash
   jq --version
   ```

4. **Azure Subscription** with appropriate permissions to create:
   - Resource Groups
   - Container Apps
   - Container Registry
   - Log Analytics Workspace

## 📝 Configuration

### Parameters File

Edit `bicep/parameters.dev.json` to customize your deployment:

```json
{
  "environmentName": "dev",
  "location": "norwayeast",
  "containerRegistryName": "pp365devacr",
  "containerAppsEnvironmentName": "pp365-dev-env",
  "spfxDevAppName": "spfx-dev-app",
  "logAnalyticsWorkspaceName": "pp365-dev-logs"
}
```

**Important Notes:**
- Container Registry name must be globally unique and contain only alphanumeric characters
- Choose a location close to your development team

## 🎯 Deployment Steps

### Step 1: Deploy Infrastructure

Deploy the Azure resources using the deployment script:

```bash
cd infra
./deploy.sh <environment> <resource-group> <subscription-id>
```

Example:
```bash
./deploy.sh dev pp365-rg-dev 12345678-1234-1234-1234-123456789abc
```

This will:
1. Validate your Azure subscription
2. Create the resource group (if it doesn't exist)
3. Validate the Bicep template
4. Deploy all Azure resources
5. Save deployment outputs to `deployment-output-dev.json`

### Step 2: Build and Push Docker Image

Build the SPFx development container and push it to ACR:

```bash
./build-and-push.sh dev
```

This will:
1. Build the Docker image from the Dockerfile
2. Login to Azure Container Registry
3. Push the image to ACR
4. Tag the image with latest and timestamp

### Step 3: Verify Deployment

Check the Container App status:

```bash
# Get the app URL from deployment outputs
cat deployment-output-dev.json

# Or check via Azure CLI
az containerapp show \
  --name spfx-dev-app \
  --resource-group pp365-rg-dev \
  --query "properties.configuration.ingress.fqdn" \
  -o tsv
```

## 🐳 Local Development with Docker Compose

For local development without deploying to Azure:

```bash
cd infra

# Start the development environment
docker-compose up -d

# Access the container
docker exec -it pp365-spfx-dev bash

# Inside the container, navigate and serve
cd /workspace/SharePointFramework/ProjectWebParts
pnpm install --shamefully-hoist
pnpm run serve
```

Access the SPFx workbench at: `http://localhost:4321`

To stop the local environment:
```bash
docker-compose down
```

## 🔧 Working with the Container App

### View Logs

```bash
# Stream logs from the container app
az containerapp logs show \
  --name spfx-dev-app \
  --resource-group pp365-rg-dev \
  --follow

# View logs in Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'spfx-dev-app' | order by TimeGenerated desc | take 100"
```

### Update Container Image

After making changes to the Dockerfile:

```bash
# Rebuild and push
./build-and-push.sh dev

# Update the container app (it will automatically pull the new image)
az containerapp update \
  --name spfx-dev-app \
  --resource-group pp365-rg-dev
```

### Scale the Container App

```bash
# Scale up
az containerapp update \
  --name spfx-dev-app \
  --resource-group pp365-rg-dev \
  --min-replicas 1 \
  --max-replicas 3

# Scale to zero (to save costs)
az containerapp update \
  --name spfx-dev-app \
  --resource-group pp365-rg-dev \
  --min-replicas 0 \
  --max-replicas 1
```

## 💰 Cost Optimization

- Container Apps scale to zero when not in use (configured with `minReplicas: 0`)
- Use Basic SKU for Container Registry in development
- Set up auto-shutdown for development environments
- Monitor costs with Azure Cost Management

Estimated monthly costs (Norway East):
- Container Apps Environment: ~$50-70/month
- Container Registry (Basic): ~$5/month
- Log Analytics: ~$2-10/month (depending on logs)
- Container App (when running): ~$10-30/month

## 🧹 Cleanup

To delete all resources:

```bash
# Delete the entire resource group
az group delete \
  --name pp365-rg-dev \
  --yes \
  --no-wait
```

## 🔐 Security Considerations

1. **Container Registry**: Admin user is enabled for simplicity. In production, use Managed Identity
2. **Secrets**: Store sensitive values in Azure Key Vault
3. **Network**: Currently using public endpoints. Consider VNet integration for production
4. **RBAC**: Implement proper role-based access control

## 📚 Additional Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [SharePoint Framework Documentation](https://learn.microsoft.com/en-us/sharepoint/dev/spfx/sharepoint-framework-overview)

## 🐛 Troubleshooting

### Container App Not Starting

```bash
# Check revision status
az containerapp revision list \
  --name spfx-dev-app \
  --resource-group pp365-rg-dev \
  -o table

# Check system logs
az containerapp logs show \
  --name spfx-dev-app \
  --resource-group pp365-rg-dev \
  --type system
```

### Cannot Pull Image from ACR

```bash
# Verify ACR credentials
az acr credential show \
  --name pp365devacr

# Test ACR connection
az acr login --name pp365devacr
docker pull pp365devacr.azurecr.io/spfx-dev:latest
```

### Bicep Validation Errors

```bash
# Validate Bicep template
az bicep build --file bicep/main.bicep

# Check for syntax errors
az deployment group validate \
  --resource-group pp365-rg-dev \
  --template-file bicep/main.bicep \
  --parameters @bicep/parameters.dev.json
```

## 📞 Support

For issues related to:
- **Infrastructure**: Check Azure Portal logs and Container Apps diagnostics
- **Prosjektportalen365**: See main repository README
- **SharePoint Framework**: Refer to Microsoft documentation

## 📄 License

This infrastructure code is part of Prosjektportalen365 and follows the same MIT license.
