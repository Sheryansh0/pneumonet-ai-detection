# HTTPS Deployment Guide for Pneumonia Detection API

This guide provides complete instructions for deploying the Pneumonia Detection API with HTTPS support using Nginx reverse proxy and Let's Encrypt SSL certificates.

## Overview

The HTTPS implementation uses a multi-container setup:
- **Flask App Container**: Your existing pneumonia detection API
- **Nginx Container**: Reverse proxy with SSL termination
- **Certbot**: Automatic SSL certificate generation and renewal

## Prerequisites

Before starting, ensure you have:
- ✅ Docker and Docker Compose installed
- ✅ Azure CLI installed and configured
- ✅ Valid email address for Let's Encrypt
- ✅ Your domain pointing to Azure Container Instance

## Quick Start

### 1. Update Email Configuration
Edit the deployment scripts and update the email address:

**For Linux/Mac:**
```bash
nano scripts/deploy-azure-https.sh
# Change: LETSENCRYPT_EMAIL="your-email@example.com"
# To: LETSENCRYPT_EMAIL="your-actual-email@domain.com"
```

**For Windows:**
```powershell
# Edit scripts/deploy-azure-https.ps1
# Update the $Email parameter default value
```

### 2. Deploy to Azure

**Option A: Using Bash Script (Linux/Mac/WSL)**
```bash
# Make script executable
chmod +x scripts/deploy-azure-https.sh

# Deploy with HTTPS
./scripts/deploy-azure-https.sh
```

**Option B: Using PowerShell Script (Windows)**
```powershell
# Run deployment with your email
.\scripts\deploy-azure-https.ps1 -Email "your-email@domain.com"
```

### 3. Verify Deployment

After deployment (wait 5-10 minutes for SSL setup):

```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health

# Test HTTPS
curl -I https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health

# Test API prediction endpoint
curl -X POST https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/predict \
  -F "file=@test-image.jpg"
```

## Local Development with HTTPS

For local testing with the full HTTPS stack:

### 1. Start Local Stack
```bash
# Navigate to backend directory
cd backend

# Update docker-compose.yml email settings
nano docker-compose.yml

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 2. Generate Local SSL Certificate
```bash
# Run SSL setup script
./scripts/setup-ssl.sh
```

### 3. Test Local HTTPS
```bash
# Test local HTTPS endpoint
curl -k https://localhost/health
```

## Architecture Details

### Container Communication
```
Internet (HTTPS) → Nginx (Port 443) → Flask App (Port 5000)
Internet (HTTP)  → Nginx (Port 80)  → Redirect to HTTPS
```

### SSL Certificate Flow
1. **Initial Request**: Certbot requests certificate via HTTP-01 challenge
2. **Domain Validation**: Let's Encrypt validates domain ownership
3. **Certificate Installation**: SSL certificates stored in shared volume
4. **Nginx Configuration**: Nginx updated to use SSL certificates
5. **Auto-Renewal**: Certbot renews certificates every 12 hours

### Volume Mounts
- `/etc/letsencrypt`: SSL certificates and configuration
- `/var/www/certbot`: ACME challenge files
- `/var/log/nginx`: Nginx access and error logs

## Troubleshooting

### Common Issues and Solutions

#### 1. Domain Not Accessible
**Problem**: Domain doesn't resolve to container IP
```bash
# Check DNS resolution
nslookup pneumonia-detection-sheryansh.centralindia.azurecontainer.io

# Check Azure container IP
az container show --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --query "ipAddress.ip" -o tsv
```

#### 2. SSL Certificate Generation Failed
**Problem**: Let's Encrypt can't validate domain

**Solution 1: Check port accessibility**
```bash
# Test if port 80 is accessible
curl -I http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io
```

**Solution 2: Check container logs**
```bash
# Check nginx logs
az container logs --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --container-name nginx-proxy

# Check Flask app logs
az container logs --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --container-name flask-app
```

**Solution 3: Manual certificate generation**
```bash
# Connect to container and run certbot manually
az container exec --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --container-name nginx-proxy \
  --exec-command "/bin/sh"

# Inside container
certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@domain.com \
  --agree-tos \
  --no-eff-email \
  -d pneumonia-detection-sheryansh.centralindia.azurecontainer.io
```

#### 3. Mixed Content Errors
**Problem**: Frontend still makes HTTP requests

**Solution**: Verify frontend configuration
```javascript
// Check frontend/src/config/api.js
const API_CONFIG = {
  BASE_URL: "https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
  // Must use HTTPS, not HTTP
};
```

#### 4. CORS Issues
**Problem**: Cross-origin requests blocked

**Solution**: Check Nginx CORS configuration
```nginx
# In nginx/nginx.conf
add_header 'Access-Control-Allow-Origin' 'https://your-frontend-domain.com' always;
```

### Monitoring Commands

**Check all container logs:**
```bash
az container logs --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https
```

**Check specific container:**
```bash
# Nginx logs
az container logs --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --container-name nginx-proxy

# Flask app logs
az container logs --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --container-name flask-app
```

**Check container status:**
```bash
az container show --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --query "containers[].instanceView.currentState"
```

**Test SSL certificate:**
```bash
# Check certificate details
openssl s_client -connect pneumonia-detection-sheryansh.centralindia.azurecontainer.io:443 \
  -servername pneumonia-detection-sheryansh.centralindia.azurecontainer.io < /dev/null | \
  openssl x509 -noout -dates
```

## Frontend Updates

After successful HTTPS deployment, update your frontend:

### 1. Update API Configuration
```javascript
// frontend/src/config/api.js
const API_CONFIG = {
  BASE_URL: "https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
};
```

### 2. Update Environment Variables
```bash
# frontend/.env.production
REACT_APP_API_URL=https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io
```

### 3. Redeploy Frontend
```bash
# If using Vercel
npm run build
vercel --prod

# If using other platforms, deploy the updated build
```

## Security Features

### Implemented Security Measures
- ✅ **SSL/TLS Encryption**: End-to-end encryption using Let's Encrypt certificates
- ✅ **HSTS**: HTTP Strict Transport Security headers
- ✅ **Security Headers**: X-Frame-Options, X-Content-Type-Options, CSP
- ✅ **Rate Limiting**: API endpoint protection against abuse
- ✅ **CORS Configuration**: Proper cross-origin resource sharing setup
- ✅ **Automatic Renewal**: SSL certificates auto-renew before expiry

### Security Best Practices Applied
- Strong cipher suites (TLSv1.2/1.3 only)
- Secure cookie settings
- Content Security Policy headers
- No sensitive data exposure in logs
- Proper error handling without information leakage

## Performance Optimizations

### Nginx Optimizations
- **Gzip Compression**: Text content compressed for faster transfer
- **Keep-Alive Connections**: Reduces connection overhead
- **Worker Processes**: Auto-scaling based on CPU cores
- **Caching Headers**: Static content cached by browsers

### Load Testing
Test your HTTPS deployment:
```bash
# Simple load test
for i in {1..10}; do
  curl -s https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health &
done
wait
```

## Maintenance

### Regular Tasks

**Weekly:**
- Check SSL certificate expiry
- Monitor container resource usage
- Review access logs

**Monthly:**
- Update container images
- Review security configurations
- Backup configuration files

### Certificate Renewal
Certificates auto-renew, but you can manually trigger renewal:
```bash
az container exec --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --container-name nginx-proxy \
  --exec-command "certbot renew --force-renewal"
```

## Cleanup

To remove the HTTPS deployment:
```bash
# Delete container group
az container delete --resource-group pneumonia-detection-rg \
  --name pneumonia-detection-https \
  --yes

# Clean up Docker images (optional)
docker rmi sheryansh/pneumonia-detection:latest
docker rmi sheryansh/pneumonia-nginx:latest
```

## Support

If you encounter issues:

1. **Check logs**: Use the monitoring commands above
2. **Verify DNS**: Ensure domain points to correct IP
3. **Test connectivity**: Use curl commands for debugging
4. **Check certificates**: Verify SSL certificate validity
5. **Review configuration**: Double-check nginx.conf and docker-compose.yml

For additional help, check:
- Let's Encrypt documentation
- Nginx reverse proxy guides
- Azure Container Instances documentation

---

**Your API is now secure with HTTPS! 🔒**

Access your secure API at: `https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io`