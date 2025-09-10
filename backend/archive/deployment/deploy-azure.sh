#!/bin/bash

# Azure deployment script for Pneumonia Detection API
# Make sure you have Azure CLI installed and are logged in

set -e

# Configuration
RESOURCE_GROUP="pneumonia-detection-rg"
CONTAINER_GROUP_NAME="pneumonia-detection-api"
LOCATION="centralindia"
IMAGE_NAME="sheryansh/pneumonia-detection-api:latest"
DNS_NAME="pneumonia-detection-sheryansh"

echo "🚀 Starting Azure deployment for Pneumonia Detection API..."

# Check if logged in to Azure
echo "📋 Checking Azure login status..."
az account show > /dev/null 2>&1 || {
    echo "❌ Please login to Azure CLI first: az login"
    exit 1
}

# Create resource group if it doesn't exist
echo "📦 Creating resource group: $RESOURCE_GROUP"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output table

# Deploy container instance
echo "🐳 Deploying container instance: $CONTAINER_GROUP_NAME"
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_GROUP_NAME \
    --image $IMAGE_NAME \
    --dns-name-label $DNS_NAME \
    --ports 5000 \
    --cpu 2 \
    --memory 8 \
    --restart-policy Always \
    --environment-variables \
        PYTHONUNBUFFERED=1 \
        DISABLE_CAM=0 \
        PORT=5000 \
    --output table

# Get the FQDN
echo "🌐 Getting deployment information..."
FQDN=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_GROUP_NAME \
    --query ipAddress.fqdn \
    --output tsv)

echo ""
echo "✅ Deployment completed successfully!"
echo "🔗 Your API is available at: http://$FQDN:5000"
echo "🏥 Health check: http://$FQDN:5000/health"
echo "🔮 Prediction endpoint: http://$FQDN:5000/predict"
echo ""
echo "📊 To check logs:"
echo "   az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_GROUP_NAME"
echo ""
echo "🗑️  To delete the deployment:"
echo "   az group delete --name $RESOURCE_GROUP --yes --no-wait"
