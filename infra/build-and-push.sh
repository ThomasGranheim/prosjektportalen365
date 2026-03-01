#!/bin/bash

# Script to build and push Docker image to Azure Container Registry
# Usage: ./build-and-push.sh <environment>

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

if [ $# -lt 1 ]; then
    print_error "Usage: $0 <environment>"
    print_info "Example: $0 dev"
    exit 1
fi

ENVIRONMENT=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOYMENT_OUTPUT_FILE="${SCRIPT_DIR}/deployment-output-${ENVIRONMENT}.json"

# Check if deployment output exists
if [ ! -f "$DEPLOYMENT_OUTPUT_FILE" ]; then
    print_error "Deployment output file not found: $DEPLOYMENT_OUTPUT_FILE"
    print_info "Please run ./deploy.sh first"
    exit 1
fi

# Read deployment outputs
CONTAINER_REGISTRY=$(jq -r '.containerRegistry' "$DEPLOYMENT_OUTPUT_FILE")

print_info "Building and pushing Docker image for environment: $ENVIRONMENT"
print_info "Container Registry: $CONTAINER_REGISTRY"

# Extract registry name (remove .azurecr.io)
REGISTRY_NAME=$(echo "$CONTAINER_REGISTRY" | cut -d'.' -f1)

# Login to Azure Container Registry
print_info "Logging in to Azure Container Registry..."
az acr login --name "$REGISTRY_NAME"

# Build Docker image
IMAGE_TAG="spfx-dev:latest"
IMAGE_NAME="${CONTAINER_REGISTRY}/${IMAGE_TAG}"

print_info "Building Docker image: $IMAGE_NAME"
docker build \
    --file "${SCRIPT_DIR}/Dockerfile" \
    --target development \
    --tag "$IMAGE_NAME" \
    --tag "${CONTAINER_REGISTRY}/spfx-dev:$(date +%Y%m%d-%H%M%S)" \
    "$PROJECT_ROOT"

if [ $? -eq 0 ]; then
    print_info "Docker image built successfully"
else
    print_error "Docker build failed"
    exit 1
fi

# Push Docker image
print_info "Pushing Docker image to registry..."
docker push "$IMAGE_NAME"

if [ $? -eq 0 ]; then
    print_info "Docker image pushed successfully"
    docker push "${CONTAINER_REGISTRY}/spfx-dev:$(date +%Y%m%d-%H%M%S)"
else
    print_error "Docker push failed"
    exit 1
fi

print_info "Build and push completed successfully!"
print_info "The container app should now be able to pull the image"

exit 0
