#!/bin/bash

# Azure Container Instances Deployment Script for Pneumonia Detection API with HTTPS
# This script deploys a multi-container setup with Nginx reverse proxy and SSL termination

set -e

# Configuration Variables
RESOURCE_GROUP="pneumonia-detection-rg"
CONTAINER_GROUP_NAME="pneumonia-detection-https"
LOCATION="centralindia"
DNS_NAME_LABEL="pneumonia-detection-sheryansh"
DOCKER_REGISTRY="sheryansh"
FLASK_IMAGE_TAG="pneumonia-detection:latest"
NGINX_IMAGE_TAG="pneumonia-nginx:latest"

# Email for Let's Encrypt (CHANGE THIS!)
LETSENCRYPT_EMAIL="your-email@example.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Azure Container Instances - HTTPS Deployment${NC}"
echo "=================================================="

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}🔐 Please log in to Azure CLI${NC}"
    az login
fi

echo -e "${BLUE}📋 Current Azure account:${NC}"
az account show --query "name" -o tsv

# Check if resource group exists
echo -e "${YELLOW}🏗️  Checking resource group...${NC}"
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}📦 Creating resource group: $RESOURCE_GROUP${NC}"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    echo -e "${GREEN}✅ Resource group exists${NC}"
fi

# Build and push Docker images
echo -e "${YELLOW}🐳 Building and pushing Docker images...${NC}"

# Build Flask app image
echo -e "${YELLOW}📦 Building Flask application image...${NC}"
docker build -t "$DOCKER_REGISTRY/$FLASK_IMAGE_TAG" .

# Build Nginx image with custom configuration
echo -e "${YELLOW}📦 Building Nginx image...${NC}"
cat > nginx.dockerfile << EOF
FROM nginx:alpine

# Install certbot and required tools
RUN apk add --no-cache certbot openssl curl

# Copy nginx configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Create necessary directories
RUN mkdir -p /var/www/certbot /var/log/nginx /etc/letsencrypt

# Create init script for SSL setup
COPY scripts/nginx-init.sh /docker-entrypoint.d/99-ssl-init.sh
RUN chmod +x /docker-entrypoint.d/99-ssl-init.sh

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
EOF

# Create nginx init script
cat > scripts/nginx-init.sh << 'EOF'
#!/bin/sh

DOMAIN="pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
EMAIL="your-email@example.com"

# Wait for flask app to be ready
echo "Waiting for Flask app to be ready..."
until curl -f http://flask-app:5000/health; do
    echo "Flask app not ready, waiting..."
    sleep 5
done

# Check if certificates exist
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "SSL certificates not found, generating..."
    
    # Create temporary nginx config for ACME challenge
    cat > /etc/nginx/nginx.conf << TEMP_EOF
events { worker_connections 1024; }
http {
    upstream flask_backend { server flask-app:5000; }
    server {
        listen 80;
        server_name $DOMAIN;
        location /.well-known/acme-challenge/ { root /var/www/certbot; }
        location / { proxy_pass http://flask_backend/; }
    }
}
TEMP_EOF
    
    # Reload nginx with temporary config
    nginx -s reload || nginx
    
    # Wait a bit for nginx to start
    sleep 5
    
    # Request certificate
    certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN" || echo "Certificate generation failed, using HTTP"
    
    # Restore full nginx config if certificate was generated
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        # Copy back the full config
        cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
        nginx -s reload
    fi
fi
EOF

# Update nginx init script with actual email
sed -i "s/your-email@example.com/$LETSENCRYPT_EMAIL/g" scripts/nginx-init.sh

# Backup original nginx config and create version without SSL for initial setup
cp nginx/nginx.conf nginx/nginx.conf.backup

docker build -f nginx.dockerfile -t "$DOCKER_REGISTRY/$NGINX_IMAGE_TAG" .

# Push images to Docker Hub
echo -e "${YELLOW}📤 Pushing images to Docker Hub...${NC}"
docker push "$DOCKER_REGISTRY/$FLASK_IMAGE_TAG"
docker push "$DOCKER_REGISTRY/$NGINX_IMAGE_TAG"

# Clean up temporary files
rm nginx.dockerfile

echo -e "${GREEN}✅ Images built and pushed${NC}"

# Delete existing container group if it exists
if az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" &> /dev/null; then
    echo -e "${YELLOW}🗑️  Deleting existing container group...${NC}"
    az container delete --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --yes
    
    # Wait for deletion to complete
    echo -e "${YELLOW}⏳ Waiting for deletion to complete...${NC}"
    while az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" &> /dev/null; do
        sleep 5
    done
fi

# Create container group with multi-container setup
echo -e "${YELLOW}🚀 Creating container group with HTTPS support...${NC}"

az container create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_GROUP_NAME" \
    --location "$LOCATION" \
    --dns-name-label "$DNS_NAME_LABEL" \
    --ports 80 443 \
    --cpu 3 \
    --memory 6 \
    --restart-policy Always \
    --environment-variables \
        DISABLE_CAM=0 \
        PORT=5000 \
        LETSENCRYPT_EMAIL="$LETSENCRYPT_EMAIL" \
    --yaml << EOF
apiVersion: '2021-07-01'
location: $LOCATION
name: $CONTAINER_GROUP_NAME
properties:
  containers:
  - name: flask-app
    properties:
      image: $DOCKER_REGISTRY/$FLASK_IMAGE_TAG
      resources:
        requests:
          cpu: 2
          memoryInGb: 4
      environmentVariables:
      - name: DISABLE_CAM
        value: '0'
      - name: PORT
        value: '5000'
      - name: PYTHONUNBUFFERED
        value: '1'
      ports: []
  - name: nginx-proxy
    properties:
      image: $DOCKER_REGISTRY/$NGINX_IMAGE_TAG
      resources:
        requests:
          cpu: 1
          memoryInGb: 2
      environmentVariables:
      - name: LETSENCRYPT_EMAIL
        value: '$LETSENCRYPT_EMAIL'
      ports:
      - port: 80
        protocol: TCP
      - port: 443
        protocol: TCP
      volumeMounts:
      - name: certbot-data
        mountPath: /etc/letsencrypt
      - name: certbot-www
        mountPath: /var/www/certbot
  ipAddress:
    type: Public
    dnsNameLabel: $DNS_NAME_LABEL
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
  osType: Linux
  restartPolicy: Always
  volumes:
  - name: certbot-data
    emptyDir: {}
  - name: certbot-www
    emptyDir: {}
tags: {}
EOF

# Wait for deployment to complete
echo -e "${YELLOW}⏳ Waiting for deployment to complete...${NC}"
az container wait --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --condition Running

# Get deployment information
echo -e "${YELLOW}📋 Getting deployment information...${NC}"
FQDN=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --query "ipAddress.fqdn" -o tsv)
IP_ADDRESS=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --query "ipAddress.ip" -o tsv)

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "=========================="
echo -e "${BLUE}🌐 FQDN:${NC} $FQDN"
echo -e "${BLUE}📍 IP Address:${NC} $IP_ADDRESS"
echo -e "${BLUE}🔗 HTTP URL:${NC} http://$FQDN"
echo -e "${BLUE}🔐 HTTPS URL:${NC} https://$FQDN (after SSL setup)"
echo ""

# Test deployment
echo -e "${YELLOW}🧪 Testing deployment...${NC}"
sleep 30  # Wait for services to start

if curl -f "http://$FQDN/health" &> /dev/null; then
    echo -e "${GREEN}✅ HTTP endpoint is working${NC}"
else
    echo -e "${RED}❌ HTTP endpoint test failed${NC}"
    echo "Checking container logs..."
    az container logs --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --container-name flask-app
fi

# SSL setup instructions
echo ""
echo -e "${YELLOW}📝 Next Steps for HTTPS:${NC}"
echo "1. Wait 5-10 minutes for SSL certificate generation"
echo "2. Test HTTPS: curl -I https://$FQDN/health"
echo "3. Update frontend to use: https://$FQDN"
echo "4. Monitor logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_GROUP_NAME"
echo ""
echo -e "${GREEN}🔒 Your secure API will be available at: https://$FQDN${NC}"

# Save deployment info
cat > azure-deployment-https-info.json << EOF
{
  "resourceGroup": "$RESOURCE_GROUP",
  "containerGroupName": "$CONTAINER_GROUP_NAME",
  "location": "$LOCATION",
  "fqdn": "$FQDN",
  "ipAddress": "$IP_ADDRESS",
  "httpUrl": "http://$FQDN",
  "httpsUrl": "https://$FQDN",
  "deploymentDate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo -e "${GREEN}✅ Deployment information saved to azure-deployment-https-info.json${NC}"