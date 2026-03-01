# Quick Start Guide - Azure Container Apps Dev Environment

## 🚀 Quick Setup (5 minutes)

### Prerequisites Check
```bash
# Verify you have the required tools
az --version          # Azure CLI
docker --version      # Docker
jq --version          # JSON processor
```

### 1. Login to Azure
```bash
az login
az account list -o table
az account set --subscription <your-subscription-id>
```

### 2. Configure Parameters
Edit `infra/bicep/parameters.dev.json`:
- Change `containerRegistryName` to a unique name (e.g., `pp365dev<yourname>`)
- Adjust `location` if needed (default: norwayeast)

### 3. Deploy Infrastructure
```bash
cd infra
./deploy.sh dev pp365-rg-dev <your-subscription-id>
```

Wait 5-10 minutes for deployment to complete.

### 4. Build and Push Docker Image
```bash
./build-and-push.sh dev
```

### 5. Access Your Environment
```bash
# Get the app URL
cat deployment-output-dev.json | jq -r .spfxDevAppFqdn

# Or visit Azure Portal
echo "https://portal.azure.com/#@/resource/subscriptions/<your-subscription-id>/resourceGroups/pp365-rg-dev/providers/Microsoft.App/containerApps/spfx-dev-app"
```

## 🏠 Local Development Alternative

If you don't want to use Azure yet:

```bash
cd infra

# Start local environment
docker-compose up -d

# Enter the container
docker exec -it pp365-spfx-dev bash

# Inside container - build and serve
cd /workspace/SharePointFramework/ProjectWebParts
pnpm install --shamefully-hoist
pnpm run serve
```

Access at: http://localhost:4321

## 📊 Common Commands

```bash
# View container logs
az containerapp logs show --name spfx-dev-app --resource-group pp365-rg-dev --follow

# Restart container app
az containerapp revision restart --name spfx-dev-app --resource-group pp365-rg-dev

# Scale to zero (save costs)
az containerapp update --name spfx-dev-app --resource-group pp365-rg-dev --min-replicas 0

# Delete everything
az group delete --name pp365-rg-dev --yes --no-wait
```

## 🎓 Next Steps

1. Read the full [README.md](./README.md) for detailed documentation
2. Customize the Dockerfile for your specific needs
3. Set up CI/CD pipeline for automatic deployments
4. Configure monitoring and alerting

## ❓ Need Help?

- Check [Troubleshooting](./README.md#-troubleshooting) section
- Review Azure Container Apps logs in Azure Portal
- Ensure all prerequisites are met
