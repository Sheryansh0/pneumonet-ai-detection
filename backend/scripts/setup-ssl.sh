#!/bin/bash

# SSL Certificate Setup Script for Pneumonia Detection API
# This script initializes Let's Encrypt SSL certificates for HTTPS

set -e

# Configuration
DOMAIN="pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
EMAIL="your-email@example.com"  # Replace with your actual email
STAGING=0  # Set to 1 for testing with staging certificates

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔒 Pneumonia Detection API - SSL Certificate Setup${NC}"
echo "=================================================="

# Check if domain is reachable
echo -e "${YELLOW}📡 Checking domain accessibility...${NC}"
if ! ping -c 1 "$DOMAIN" &> /dev/null; then
    echo -e "${RED}❌ Domain $DOMAIN is not reachable. Please check your DNS configuration.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Domain is reachable${NC}"

# Create necessary directories
echo -e "${YELLOW}📁 Creating certificate directories...${NC}"
mkdir -p ./certbot/conf
mkdir -p ./certbot/www
mkdir -p ./certbot/logs
mkdir -p ./nginx/logs
mkdir -p ./logs

# Set proper permissions
chmod 755 ./certbot/conf
chmod 755 ./certbot/www

echo -e "${GREEN}✅ Directories created${NC}"

# Check if certificates already exist
if [ -d "./certbot/conf/live/$DOMAIN" ]; then
    echo -e "${YELLOW}⚠️  SSL certificates already exist for $DOMAIN${NC}"
    read -p "Do you want to renew them? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ Using existing certificates${NC}"
        exit 0
    fi
fi

# Determine staging flag
STAGING_FLAG=""
if [ $STAGING -eq 1 ]; then
    STAGING_FLAG="--staging"
    echo -e "${YELLOW}🧪 Using Let's Encrypt staging environment${NC}"
fi

# Start services without SSL first
echo -e "${YELLOW}🚀 Starting services for certificate generation...${NC}"
docker-compose up -d flask-app

# Wait for Flask app to be ready
echo -e "${YELLOW}⏳ Waiting for Flask app to start...${NC}"
for i in {1..30}; do
    if docker-compose exec flask-app curl -f http://localhost:5000/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Flask app is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Flask app failed to start${NC}"
        docker-compose logs flask-app
        exit 1
    fi
    sleep 2
done

# Start nginx with temporary config for HTTP validation
echo -e "${YELLOW}🌐 Starting Nginx for HTTP validation...${NC}"

# Create temporary nginx config for certificate generation
cat > ./nginx/nginx-temp.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream flask_backend {
        server flask-app:5000;
    }
    
    server {
        listen 80;
        server_name $DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location /health {
            proxy_pass http://flask_backend/health;
        }
        
        location / {
            proxy_pass http://flask_backend/;
        }
    }
}
EOF

# Start nginx with temporary config
docker run -d --name temp-nginx \
    --network pneumonia-network \
    -p 80:80 \
    -v $(pwd)/nginx/nginx-temp.conf:/etc/nginx/nginx.conf:ro \
    -v $(pwd)/certbot/www:/var/www/certbot:ro \
    nginx:alpine

echo -e "${GREEN}✅ Temporary Nginx started${NC}"

# Wait for nginx to be ready
sleep 5

# Request SSL certificate
echo -e "${YELLOW}🔐 Requesting SSL certificate from Let's Encrypt...${NC}"
docker run --rm \
    --network pneumonia-network \
    -v $(pwd)/certbot/conf:/etc/letsencrypt \
    -v $(pwd)/certbot/www:/var/www/certbot \
    -v $(pwd)/certbot/logs:/var/log/letsencrypt \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    $STAGING_FLAG \
    -d "$DOMAIN"

# Check if certificate was generated successfully
if [ ! -f "./certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${RED}❌ Failed to generate SSL certificate${NC}"
    docker stop temp-nginx
    docker rm temp-nginx
    exit 1
fi

echo -e "${GREEN}✅ SSL certificate generated successfully${NC}"

# Stop temporary nginx
docker stop temp-nginx
docker rm temp-nginx

# Update nginx configuration with HTTPS
echo -e "${YELLOW}🔄 Updating Nginx configuration for HTTPS...${NC}"

# Remove temporary config
rm ./nginx/nginx-temp.conf

# Start the full stack with SSL
echo -e "${YELLOW}🚀 Starting full stack with HTTPS...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 10

# Test HTTPS endpoint
echo -e "${YELLOW}🧪 Testing HTTPS endpoint...${NC}"
if curl -f -k "https://$DOMAIN/health" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ HTTPS endpoint is working!${NC}"
else
    echo -e "${RED}❌ HTTPS endpoint test failed${NC}"
    echo "Checking logs..."
    docker-compose logs nginx
    exit 1
fi

# Set up certificate renewal cron job
echo -e "${YELLOW}📅 Setting up automatic certificate renewal...${NC}"
(crontab -l 2>/dev/null; echo "0 12 * * * cd $(pwd) && docker-compose exec certbot certbot renew --quiet && docker-compose exec nginx nginx -s reload") | crontab -

echo -e "${GREEN}✅ Certificate renewal scheduled${NC}"

# Final status
echo ""
echo -e "${GREEN}🎉 SSL Setup Complete!${NC}"
echo "=================================================="
echo -e "✅ HTTPS is now enabled for: ${GREEN}https://$DOMAIN${NC}"
echo -e "✅ Certificates are automatically renewed"
echo -e "✅ HTTP requests are redirected to HTTPS"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update your frontend to use: https://$DOMAIN"
echo "2. Test the API endpoints"
echo "3. Monitor the logs: docker-compose logs -f"
echo ""
echo -e "${GREEN}🔒 Your API is now secure!${NC}"