#!/bin/bash

# SSL Certificate Renewal Script for Pneumonia Detection API
# This script renews Let's Encrypt SSL certificates and reloads Nginx

set -e

# Configuration
DOMAIN="pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 SSL Certificate Renewal${NC}"
echo "=========================="

# Check if Docker Compose is running
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}❌ Docker Compose services are not running${NC}"
    exit 1
fi

# Check certificate expiry
echo -e "${YELLOW}📅 Checking certificate expiry...${NC}"
EXPIRY_DATE=$(docker-compose exec certbot openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -enddate | cut -d= -f2)
EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))

echo -e "${YELLOW}Certificate expires in: ${DAYS_UNTIL_EXPIRY} days${NC}"

# Renew if less than 30 days
if [ $DAYS_UNTIL_EXPIRY -le 30 ]; then
    echo -e "${YELLOW}🔐 Renewing SSL certificate...${NC}"
    
    # Attempt renewal
    if docker-compose exec certbot certbot renew --quiet --no-self-upgrade; then
        echo -e "${GREEN}✅ Certificate renewed successfully${NC}"
        
        # Reload Nginx to use new certificate
        echo -e "${YELLOW}🔄 Reloading Nginx...${NC}"
        if docker-compose exec nginx nginx -s reload; then
            echo -e "${GREEN}✅ Nginx reloaded successfully${NC}"
        else
            echo -e "${RED}❌ Failed to reload Nginx${NC}"
            exit 1
        fi
        
        # Test HTTPS endpoint
        echo -e "${YELLOW}🧪 Testing HTTPS endpoint...${NC}"
        if curl -f -k "https://$DOMAIN/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ HTTPS endpoint is working with new certificate${NC}"
        else
            echo -e "${RED}❌ HTTPS endpoint test failed${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}🎉 SSL renewal completed successfully!${NC}"
    else
        echo -e "${RED}❌ Certificate renewal failed${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Certificate is still valid (${DAYS_UNTIL_EXPIRY} days remaining)${NC}"
fi

# Log renewal attempt
echo "$(date): SSL renewal check completed. Days until expiry: $DAYS_UNTIL_EXPIRY" >> ./logs/ssl-renewal.log