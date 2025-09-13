# PowerShell script for Azure Container Instances deployment with HTTPS
# This script deploys the Pneumonia Detection API with Nginx reverse proxy and SSL

param(
    [Parameter(Mandatory=$false)]
    [string]$Email = "your-email@example.com"
)

# Configuration
$ResourceGroup = "pneumonia-detection-rg"
$ContainerGroupName = "pneumonia-detection-https"
$Location = "centralindia"
$DnsNameLabel = "pneumonia-detection-sheryansh"
$DockerRegistry = "sheryansh"
$FlaskImageTag = "pneumonia-detection:latest"
$NginxImageTag = "pneumonia-nginx:latest"

Write-Host "🚀 Azure Container Instances - HTTPS Deployment" -ForegroundColor Green
Write-Host "=================================================="

# Check Azure CLI
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI is not installed" -ForegroundColor Red
    exit 1
}

# Check if logged in to Azure
try {
    az account show | Out-Null
} catch {
    Write-Host "🔐 Please log in to Azure CLI" -ForegroundColor Yellow
    az login
}

Write-Host "📋 Current Azure account:" -ForegroundColor Blue
az account show --query "name" -o tsv

# Check if resource group exists
Write-Host "🏗️ Checking resource group..." -ForegroundColor Yellow
try {
    az group show --name $ResourceGroup | Out-Null
    Write-Host "✅ Resource group exists" -ForegroundColor Green
} catch {
    Write-Host "📦 Creating resource group: $ResourceGroup" -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location
}

# Build and push Docker images
Write-Host "🐳 Building and pushing Docker images..." -ForegroundColor Yellow

# Build Flask app image
Write-Host "📦 Building Flask application image..." -ForegroundColor Yellow
docker build -t "$DockerRegistry/$FlaskImageTag" .

# Create Nginx Dockerfile
$nginxDockerfile = @"
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
"@

$nginxDockerfile | Out-File -FilePath "nginx.dockerfile" -Encoding UTF8

# Create nginx init script
$nginxInitScript = @'
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
'@

# Ensure scripts directory exists
if (!(Test-Path "scripts")) {
    New-Item -ItemType Directory -Path "scripts"
}

$nginxInitScript.Replace("your-email@example.com", $Email) | Out-File -FilePath "scripts/nginx-init.sh" -Encoding UTF8

Write-Host "📦 Building Nginx image..." -ForegroundColor Yellow
docker build -f nginx.dockerfile -t "$DockerRegistry/$NginxImageTag" .

# Push images to Docker Hub
Write-Host "📤 Pushing images to Docker Hub..." -ForegroundColor Yellow
docker push "$DockerRegistry/$FlaskImageTag"
docker push "$DockerRegistry/$NginxImageTag"

# Clean up temporary files
Remove-Item "nginx.dockerfile" -Force

Write-Host "✅ Images built and pushed" -ForegroundColor Green

# Delete existing container group if it exists
try {
    az container show --resource-group $ResourceGroup --name $ContainerGroupName | Out-Null
    Write-Host "🗑️ Deleting existing container group..." -ForegroundColor Yellow
    az container delete --resource-group $ResourceGroup --name $ContainerGroupName --yes
    
    # Wait for deletion to complete
    Write-Host "⏳ Waiting for deletion to complete..." -ForegroundColor Yellow
    do {
        Start-Sleep 5
    } while (try { az container show --resource-group $ResourceGroup --name $ContainerGroupName | Out-Null; $true } catch { $false })
} catch {
    Write-Host "ℹ️ No existing container group to delete" -ForegroundColor Blue
}

# Create YAML configuration for multi-container deployment
$yamlConfig = @"
apiVersion: '2021-07-01'
location: $Location
name: $ContainerGroupName
properties:
  containers:
  - name: flask-app
    properties:
      image: $DockerRegistry/$FlaskImageTag
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
      image: $DockerRegistry/$NginxImageTag
      resources:
        requests:
          cpu: 1
          memoryInGb: 2
      environmentVariables:
      - name: LETSENCRYPT_EMAIL
        value: '$Email'
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
    dnsNameLabel: $DnsNameLabel
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
"@

$yamlConfig | Out-File -FilePath "deployment.yaml" -Encoding UTF8

# Create container group
Write-Host "🚀 Creating container group with HTTPS support..." -ForegroundColor Yellow
az container create --resource-group $ResourceGroup --file deployment.yaml

# Clean up deployment file
Remove-Item "deployment.yaml" -Force

# Wait for deployment to complete
Write-Host "⏳ Waiting for deployment to complete..." -ForegroundColor Yellow
az container wait --resource-group $ResourceGroup --name $ContainerGroupName --condition Running

# Get deployment information
Write-Host "📋 Getting deployment information..." -ForegroundColor Yellow
$Fqdn = az container show --resource-group $ResourceGroup --name $ContainerGroupName --query "ipAddress.fqdn" -o tsv
$IpAddress = az container show --resource-group $ResourceGroup --name $ContainerGroupName --query "ipAddress.ip" -o tsv

Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "=========================="
Write-Host "🌐 FQDN: $Fqdn" -ForegroundColor Blue
Write-Host "📍 IP Address: $IpAddress" -ForegroundColor Blue
Write-Host "🔗 HTTP URL: http://$Fqdn" -ForegroundColor Blue
Write-Host "🔐 HTTPS URL: https://$Fqdn (after SSL setup)" -ForegroundColor Blue
Write-Host ""

# Test deployment
Write-Host "🧪 Testing deployment..." -ForegroundColor Yellow
Start-Sleep 30  # Wait for services to start

try {
    $response = Invoke-WebRequest "http://$Fqdn/health" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ HTTP endpoint is working" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ HTTP endpoint test failed" -ForegroundColor Red
    Write-Host "Checking container logs..." -ForegroundColor Yellow
    az container logs --resource-group $ResourceGroup --name $ContainerGroupName --container-name flask-app
}

# SSL setup instructions
Write-Host ""
Write-Host "📝 Next Steps for HTTPS:" -ForegroundColor Yellow
Write-Host "1. Wait 5-10 minutes for SSL certificate generation"
Write-Host "2. Test HTTPS: curl -I https://$Fqdn/health"
Write-Host "3. Update frontend to use: https://$Fqdn"
Write-Host "4. Monitor logs: az container logs --resource-group $ResourceGroup --name $ContainerGroupName"
Write-Host ""
Write-Host "🔒 Your secure API will be available at: https://$Fqdn" -ForegroundColor Green

# Save deployment info
$deploymentInfo = @{
    resourceGroup = $ResourceGroup
    containerGroupName = $ContainerGroupName
    location = $Location
    fqdn = $Fqdn
    ipAddress = $IpAddress
    httpUrl = "http://$Fqdn"
    httpsUrl = "https://$Fqdn"
    deploymentDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 2

$deploymentInfo | Out-File -FilePath "azure-deployment-https-info.json" -Encoding UTF8

Write-Host "✅ Deployment information saved to azure-deployment-https-info.json" -ForegroundColor Green