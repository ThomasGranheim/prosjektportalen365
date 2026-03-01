#!/bin/bash

# Deployment script for Azure Container Apps Infrastructure
# Usage: ./deploy.sh <environment> <resource-group> <subscription-id>

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    print_error "Usage: $0 <environment> <resource-group> <subscription-id>"
    print_info "Example: $0 dev pp365-rg-dev 00000000-0000-0000-0000-000000000000"
    exit 1
fi

ENVIRONMENT=$1
RESOURCE_GROUP=$2
SUBSCRIPTION_ID=$3
LOCATION="norwayeast"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_DIR="${SCRIPT_DIR}/bicep"
PARAMETERS_FILE="${BICEP_DIR}/parameters.${ENVIRONMENT}.json"

# Validate parameters file exists
if [ ! -f "$PARAMETERS_FILE" ]; then
    print_error "Parameters file not found: $PARAMETERS_FILE"
    exit 1
fi

print_info "Starting deployment for environment: $ENVIRONMENT"
print_info "Resource Group: $RESOURCE_GROUP"
print_info "Subscription ID: $SUBSCRIPTION_ID"

# Set Azure subscription
print_info "Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
print_info "Ensuring resource group exists..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none || true

# Validate Bicep template
print_info "Validating Bicep template..."
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "${BICEP_DIR}/main.bicep" \
    --parameters "@${PARAMETERS_FILE}" \
    --output none

if [ $? -eq 0 ]; then
    print_info "Bicep template validation successful"
else
    print_error "Bicep template validation failed"
    exit 1
fi

# Deploy infrastructure
print_info "Deploying infrastructure..."
DEPLOYMENT_NAME="pp365-aca-deployment-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "${BICEP_DIR}/main.bicep" \
    --parameters "@${PARAMETERS_FILE}" \
    --name "$DEPLOYMENT_NAME" \
    --output json > /tmp/deployment-output.json

if [ $? -eq 0 ]; then
    print_info "Infrastructure deployment successful!"
    
    # Extract and display outputs
    print_info "Deployment Outputs:"
    echo "-----------------------------------"
    
    CONTAINER_REGISTRY=$(jq -r '.properties.outputs.containerRegistryLoginServer.value' /tmp/deployment-output.json)
    CONTAINER_ENV=$(jq -r '.properties.outputs.containerAppsEnvironmentId.value' /tmp/deployment-output.json)
    SPFX_APP_FQDN=$(jq -r '.properties.outputs.spfxDevAppFqdn.value' /tmp/deployment-output.json)
    LOG_ANALYTICS=$(jq -r '.properties.outputs.logAnalyticsWorkspaceId.value' /tmp/deployment-output.json)
    
    echo "Container Registry: $CONTAINER_REGISTRY"
    echo "Container Apps Environment ID: $CONTAINER_ENV"
    echo "SPFx Dev App URL: https://$SPFX_APP_FQDN"
    echo "Log Analytics Workspace ID: $LOG_ANALYTICS"
    echo "-----------------------------------"
    
    # Save outputs to file
    cat > "${SCRIPT_DIR}/deployment-output-${ENVIRONMENT}.json" <<EOF
{
  "containerRegistry": "$CONTAINER_REGISTRY",
  "containerAppsEnvironmentId": "$CONTAINER_ENV",
  "spfxDevAppFqdn": "$SPFX_APP_FQDN",
  "logAnalyticsWorkspaceId": "$LOG_ANALYTICS",
  "deploymentName": "$DEPLOYMENT_NAME",
  "deploymentTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    print_info "Deployment outputs saved to: deployment-output-${ENVIRONMENT}.json"
    
else
    print_error "Infrastructure deployment failed"
    exit 1
fi

print_info "Deployment completed successfully!"
print_warning "Note: You need to build and push the Docker image before the container app will work."
print_info "Run: ./build-and-push.sh $ENVIRONMENT"

exit 0
