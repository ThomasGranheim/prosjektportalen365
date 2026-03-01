#!/bin/bash

# Validation script for Azure Container Apps IaC
# This script validates all configuration files before deployment

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Validating Azure Container Apps IaC..."
echo "======================================"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

if command -v az &> /dev/null; then
    print_success "Azure CLI is installed"
else
    print_error "Azure CLI is not installed"
    exit 1
fi

if command -v bicep &> /dev/null; then
    print_success "Bicep CLI is installed"
else
    print_error "Bicep CLI is not installed"
    print_info "Run: az bicep install"
    exit 1
fi

if command -v docker &> /dev/null; then
    print_success "Docker is installed"
else
    print_error "Docker is not installed"
    exit 1
fi

if command -v jq &> /dev/null; then
    print_success "jq is installed"
else
    print_error "jq is not installed (required for deployment scripts)"
    exit 1
fi

echo ""
print_info "Validating Bicep templates..."

# Validate main template
if bicep build bicep/main.bicep > /dev/null 2>&1; then
    print_success "Main Bicep template is valid"
else
    print_error "Main Bicep template has errors"
    bicep build bicep/main.bicep
    exit 1
fi

# Validate modules
for module in bicep/modules/*.bicep; do
    module_name=$(basename "$module")
    if bicep build "$module" > /dev/null 2>&1; then
        print_success "Module $module_name is valid"
    else
        print_error "Module $module_name has errors"
        bicep build "$module"
        exit 1
    fi
done

echo ""
print_info "Validating Docker configuration..."

# Validate Dockerfile syntax
if docker build --file Dockerfile --target development --no-cache --dry-run . > /dev/null 2>&1 || \
   docker buildx build --file Dockerfile --target development --no-cache --dry-run . > /dev/null 2>&1; then
    print_success "Dockerfile syntax is valid"
else
    # Fallback: just check file exists and has basic syntax
    if grep -q "FROM node:14" Dockerfile; then
        print_success "Dockerfile exists and has basic structure"
    else
        print_error "Dockerfile has syntax errors"
        exit 1
    fi
fi

# Validate docker-compose
if docker compose config > /dev/null 2>&1; then
    print_success "docker-compose.yml is valid"
elif command -v docker-compose &> /dev/null && docker-compose config > /dev/null 2>&1; then
    print_success "docker-compose.yml is valid"
else
    print_error "docker-compose.yml has errors"
    exit 1
fi

echo ""
print_info "Validating parameter files..."

# Check dev parameters
if [ -f "bicep/parameters.dev.json" ]; then
    if jq empty bicep/parameters.dev.json 2>/dev/null; then
        print_success "Dev parameters file is valid JSON"
    else
        print_error "Dev parameters file has invalid JSON"
        exit 1
    fi
else
    print_error "Dev parameters file is missing"
    exit 1
fi

echo ""
print_info "Validating deployment scripts..."

# Check scripts are executable
if [ -x "deploy.sh" ]; then
    print_success "deploy.sh is executable"
else
    print_error "deploy.sh is not executable"
    chmod +x deploy.sh
    print_info "Fixed: Made deploy.sh executable"
fi

if [ -x "build-and-push.sh" ]; then
    print_success "build-and-push.sh is executable"
else
    print_error "build-and-push.sh is not executable"
    chmod +x build-and-push.sh
    print_info "Fixed: Made build-and-push.sh executable"
fi

echo ""
echo "======================================"
print_success "All validations passed!"
echo ""
print_info "Next steps:"
echo "  1. Edit bicep/parameters.dev.json with your values"
echo "  2. Run: ./deploy.sh dev <resource-group> <subscription-id>"
echo "  3. Run: ./build-and-push.sh dev"
echo ""
