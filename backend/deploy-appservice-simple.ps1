# Azure App Service Deployment - Simple Version
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "pneumonia-detection-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServicePlanName = "pneumonia-detection-plan",
    
    [Parameter(Mandatory=$false)]
    [string]$WebAppName = "pneumonia-detection-app",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "centralindia",
    
    [Parameter(Mandatory=$false)]
    [string]$DockerImage = "sheryansh/pneumonia-detection:latest"
)

Write-Host "Deploying to Azure App Service (Cost-Effective)..." -ForegroundColor Green

# Check Azure CLI
try {
    az --version | Out-Null
    Write-Host "Azure CLI is available" -ForegroundColor Green
} catch {
    Write-Host "Azure CLI is not installed" -ForegroundColor Red
    exit 1
}

# Create resource group
Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

# Create App Service Plan (B1 - Basic, cost-effective)
Write-Host "Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create --name $AppServicePlanName --resource-group $ResourceGroupName --location $Location --sku B1 --is-linux

# Create the web app with Docker
Write-Host "Creating Web App with Docker..." -ForegroundColor Yellow
az webapp create --name $WebAppName --resource-group $ResourceGroupName --plan $AppServicePlanName --deployment-container-image-name $DockerImage

# Configure environment variables
Write-Host "Configuring environment variables..." -ForegroundColor Yellow
az webapp config appsettings set --name $WebAppName --resource-group $ResourceGroupName --settings "DISABLE_CAM=0" "PORT=80" "WEBSITES_PORT=5000"

# Configure container
Write-Host "Configuring container..." -ForegroundColor Yellow
az webapp config container set --name $WebAppName --resource-group $ResourceGroupName --docker-custom-image-name $DockerImage

# Get the URL
Write-Host "Getting deployment details..." -ForegroundColor Yellow
$appInfo = az webapp show --name $WebAppName --resource-group $ResourceGroupName --output json | ConvertFrom-Json

$httpsUrl = "https://$($appInfo.defaultHostName)"

Write-Host ""
Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "HTTPS URL: $httpsUrl" -ForegroundColor Yellow
Write-Host "Health endpoint: $httpsUrl/health" -ForegroundColor Cyan
Write-Host "Predict endpoint: $httpsUrl/predict" -ForegroundColor Cyan

Write-Host ""
Write-Host "Cost Benefits:" -ForegroundColor Green
Write-Host "- App Service B1: ~$13-15/month" -ForegroundColor White
Write-Host "- Much cheaper than Container Instances" -ForegroundColor White
Write-Host "- Built-in HTTPS and scaling" -ForegroundColor White

# Test the deployment
Write-Host ""
Write-Host "Testing the API..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

try {
    $response = Invoke-RestMethod -Uri "$httpsUrl/health" -Method Get -TimeoutSec 30
    Write-Host "Health check passed! Status: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "Health check failed - web app might still be starting" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next step: Update frontend to use $httpsUrl" -ForegroundColor Cyan
