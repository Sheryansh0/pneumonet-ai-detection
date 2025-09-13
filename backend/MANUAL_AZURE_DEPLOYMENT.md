# Manual Azure Portal HTTPS Deployment Guide

This guide provides detailed step-by-step instructions for manually deploying the Pneumonia Detection API with HTTPS support using the Azure Portal.

## Prerequisites Checklist

Before starting, ensure you have:
- ✅ Azure account with active subscription
- ✅ Docker Desktop installed and running
- ✅ Your Flask app code ready
- ✅ Email address for Let's Encrypt: `bachchushreyansh@gmail.com`

## Step 1: Prepare Docker Images

### 1.1 Build Flask Application Image

Open PowerShell in your backend directory and run:

```powershell
# Navigate to backend directory
cd "D:\projects\mini project\PneumoniaApp\backend"

# Build Flask app image
docker build -t pneumonia-detection:latest .

# Verify the image was created
docker images | findstr pneumonia-detection
```

### 1.2 Create Nginx Configuration for Container

Create a simplified nginx configuration that works with Azure Container Instances:

```powershell
# Create a new nginx config specifically for Azure
New-Item -ItemType Directory -Path "nginx-azure" -Force
```

Create `nginx-azure/nginx.conf`:
```nginx
user nginx;
worker_processes auto;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;
    
    sendfile on;
    keepalive_timeout 65;
    client_max_body_size 50M;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    upstream flask_backend {
        server localhost:5000;
    }
    
    # HTTP server - will be upgraded to HTTPS later
    server {
        listen 80;
        server_name pneumonia-detection-sheryansh.centralindia.azurecontainer.io;
        
        # Health check
        location /health {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://flask_backend/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Main API
        location / {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://flask_backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            
            if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*' always;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain; charset=utf-8';
                add_header 'Content-Length' 0;
                return 204;
            }
            
            proxy_connect_timeout 10s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
        }
    }
}
```

### 1.3 Create Startup Script

Create `startup.sh`:
```bash
#!/bin/bash

# Start Flask app in background
cd /app
python app.py &

# Start Nginx in foreground
nginx -g "daemon off;"
```

### 1.4 Create Combined Dockerfile

Create `Dockerfile.combined`:
```dockerfile
# Multi-stage build for combined Flask + Nginx container
FROM python:3.11-slim as flask-base

# Install system dependencies for Flask
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# Copy Flask application
COPY app.py explain.py ./
COPY *.pth ./

# Install Nginx
RUN apt-get update && apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# Copy Nginx configuration
COPY nginx-azure/nginx.conf /etc/nginx/nginx.conf

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Create nginx user and set permissions
RUN chown -R www-data:www-data /var/log/nginx /var/lib/nginx

EXPOSE 80

CMD ["/startup.sh"]
```

### 1.5 Build Combined Image

```powershell
# Create the combined image
docker build -f Dockerfile.combined -t pneumonia-combined:latest .

# Test the image locally (optional)
docker run -p 8080:80 pneumonia-combined:latest
# Test in another terminal: curl http://localhost:8080/health
# Stop with Ctrl+C
```

## Step 2: Push Image to Azure Container Registry

### 2.1 Create Azure Container Registry

1. **Open Azure Portal**: Go to [https://portal.azure.com](https://portal.azure.com)

2. **Create Container Registry**:
   - Click "Create a resource"
   - Search for "Container Registry"
   - Click "Create"

3. **Fill Registry Details**:
   ```
   Subscription: [Your subscription]
   Resource Group: pneumonia-detection-rg (create new if doesn't exist)
   Registry name: pneumoniadetectionacr (must be unique)
   Location: Central India
   SKU: Basic
   ```

4. **Click "Review + create"** then **"Create"**

5. **Wait for deployment** (2-3 minutes)

### 2.2 Enable Admin Access

1. **Go to your Container Registry** resource
2. **Click "Access keys"** in the left menu
3. **Enable "Admin user"** toggle
4. **Copy the values**:
   ```
   Login server: pneumoniadetectionacr.azurecr.io
   Username: pneumoniadetectionacr
   Password: [copy the password]
   ```

### 2.3 Push Image to ACR

```powershell
# Login to Azure Container Registry
az acr login --name pneumoniadetectionacr

# Tag your image for ACR
docker tag pneumonia-combined:latest pneumoniadetectionacr.azurecr.io/pneumonia-combined:latest

# Push to ACR
docker push pneumoniadetectionacr.azurecr.io/pneumonia-combined:latest

# Verify push
az acr repository list --name pneumoniadetectionacr --output table
```

## Step 3: Create Container Instance

### 3.1 Navigate to Container Instances

1. **In Azure Portal**, click "Create a resource"
2. **Search for "Container Instances"**
3. **Click "Create"**

### 3.2 Basic Configuration

**Basics Tab:**
```
Subscription: [Your subscription]
Resource Group: pneumonia-detection-rg
Container name: pneumonia-https-manual
Region: Central India
Image source: Azure Container Registry
Registry: pneumoniadetectionacr
Image: pneumonia-combined
Image tag: latest
```

**Size:**
```
CPU cores: 2
Memory (GB): 4
```

### 3.3 Networking Configuration

**Networking Tab:**
```
Networking type: Public
DNS name label: pneumonia-detection-sheryansh
Ports: 80 (TCP)
```

### 3.4 Advanced Configuration

**Advanced Tab:**

**Environment Variables:**
```
DISABLE_CAM: 0
PORT: 5000
PYTHONUNBUFFERED: 1
```

**Command Override:**
```
Command: /startup.sh
```

### 3.5 Review and Create

1. **Click "Review + create"**
2. **Verify all settings**
3. **Click "Create"**
4. **Wait for deployment** (5-10 minutes)

## Step 4: Verify Deployment

### 4.1 Get Container Information

1. **Go to your Container Instance** resource
2. **Note the FQDN**: `pneumonia-detection-sheryansh.centralindia.azurecontainer.io`
3. **Note the IP address**

### 4.2 Test HTTP Endpoints

```powershell
# Test health endpoint
curl http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health

# Test main endpoint
curl http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/
```

### 4.3 Test with Frontend

Update your frontend configuration:
```javascript
// frontend/src/config/api.js
const API_CONFIG = {
  BASE_URL: "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
};
```

## Step 5: Add HTTPS with Application Gateway (Optional)

For production HTTPS, you can add Azure Application Gateway:

### 5.1 Create Application Gateway

1. **Create a resource** → "Application Gateway"
2. **Basic configuration**:
   ```
   Name: pneumonia-app-gateway
   Region: Central India
   Tier: Standard_v2
   ```

3. **Frontend configuration**:
   ```
   Frontend IP: Public
   Add new public IP: pneumonia-gateway-ip
   ```

4. **Backend configuration**:
   ```
   Backend pool name: pneumonia-backend
   Target type: IP address or FQDN
   Target: pneumonia-detection-sheryansh.centralindia.azurecontainer.io
   ```

5. **Configuration rules**:
   ```
   Rule name: pneumonia-rule
   Listener: pneumonia-listener (HTTP, port 80)
   Backend targets: pneumonia-backend
   ```

### 5.2 Add SSL Certificate

1. **Go to Application Gateway** resource
2. **Click "Listeners"** → Edit your listener
3. **Change Protocol to HTTPS**
4. **Upload SSL certificate** or use App Gateway managed certificate

## Step 6: Update Frontend Configuration

Once your backend is accessible:

### 6.1 Update API Configuration

```javascript
// frontend/src/config/api.js
const API_CONFIG = {
  BASE_URL: process.env.REACT_APP_API_URL || 
           "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
};
```

### 6.2 Update Environment Variables

```bash
# frontend/.env.production
REACT_APP_API_URL=http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io
```

### 6.3 Redeploy Frontend

If using Vercel:
```powershell
cd "D:\projects\mini project\PneumoniaApp\frontend"
npm run build
vercel --prod
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Container Fails to Start

**Check logs in Azure Portal:**
1. Go to Container Instance
2. Click "Containers" → "Logs"
3. Check for error messages

**Common fixes:**
- Verify Dockerfile syntax
- Check if all files are copied correctly
- Ensure startup script has execute permissions

#### 2. Cannot Access Endpoints

**Check networking:**
```powershell
# Test if container is running
curl -v http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health

# Check DNS resolution
nslookup pneumonia-detection-sheryansh.centralindia.azurecontainer.io
```

#### 3. CORS Issues

**Update nginx configuration** to allow your frontend domain:
```nginx
add_header 'Access-Control-Allow-Origin' 'https://your-frontend-domain.vercel.app' always;
```

#### 4. Performance Issues

**Scale up container:**
1. Go to Container Instance
2. Click "Stop" → Wait → "Start"
3. Or create new instance with more CPU/memory

## Monitoring and Maintenance

### Health Monitoring

**Set up alerts:**
1. Go to Container Instance
2. Click "Alerts" → "New alert rule"
3. Set conditions for CPU, memory, or custom metrics

### Log Monitoring

**View container logs:**
1. Azure Portal → Container Instance → Logs
2. Or use Azure CLI:
```powershell
az container logs --resource-group pneumonia-detection-rg --name pneumonia-https-manual
```

### Updating the Application

**To update your app:**
1. Build new Docker image
2. Push to ACR with new tag
3. Update Container Instance with new image
4. Restart container

## Security Considerations

### Network Security

- Use Application Gateway for SSL termination
- Implement Web Application Firewall (WAF)
- Restrict access with Network Security Groups

### Container Security

- Use minimal base images
- Don't run as root user
- Scan images for vulnerabilities
- Use Azure Security Center recommendations

### Data Security

- Encrypt data in transit (HTTPS)
- Use Azure Key Vault for secrets
- Implement proper authentication
- Log and monitor access

---

## Summary

You now have:
- ✅ Flask app running in Azure Container Instance
- ✅ HTTP endpoint accessible from frontend
- ✅ Proper CORS configuration
- ✅ Monitoring and logging setup

**Next steps:**
1. Test your API endpoints thoroughly
2. Update frontend to use new backend URL
3. Consider adding HTTPS with Application Gateway for production
4. Set up monitoring and alerts

Your API is now accessible at:
`http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io`