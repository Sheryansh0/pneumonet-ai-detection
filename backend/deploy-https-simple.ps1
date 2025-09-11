# Azure Container Apps Deployment with HTTPS - Simple Version
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "pneumonia-detection-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerAppName = "pneumonia-detection-app",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerAppEnvName = "pneumonia-detection-env",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "centralindia",
    
    [Parameter(Mandatory=$false)]
    [string]$DockerImage = "sheryansh/pneumonia-detection:latest"
)

Write-Host "Deploying Azure Container Apps with HTTPS..." -ForegroundColor Green

# Check Azure CLI
try {
    az --version | Out-Null
    Write-Host "Azure CLI is available" -ForegroundColor Green
} catch {
    Write-Host "Azure CLI is not installed" -ForegroundColor Red
    exit 1
}

# Install Container Apps extension
Write-Host "Installing Container Apps extension..." -ForegroundColor Yellow
az extension add --name containerapp --yes

# Register providers
Write-Host "Registering providers..." -ForegroundColor Yellow
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

# Create resource group
Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

# Create Container Apps environment
Write-Host "Creating Container Apps environment..." -ForegroundColor Yellow
az containerapp env create --name $ContainerAppEnvName --resource-group $ResourceGroupName --location $Location

# Deploy the container app
Write-Host "Deploying container app..." -ForegroundColor Yellow
az containerapp create --name $ContainerAppName --resource-group $ResourceGroupName --environment $ContainerAppEnvName --image $DockerImage --target-port 5000 --ingress external --transport http --cpu 2.0 --memory 4.0Gi --min-replicas 1 --max-replicas 3 --env-vars "DISABLE_CAM=0" "PORT=5000"

# Get the URL
Write-Host "Getting deployment details..." -ForegroundColor Yellow
$appInfo = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --output json | ConvertFrom-Json

$fqdn = $appInfo.properties.configuration.ingress.fqdn
$httpsUrl = "https://$fqdn"

Write-Host ""
Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "HTTPS URL: $httpsUrl" -ForegroundColor Yellow
Write-Host "Health endpoint: $httpsUrl/health" -ForegroundColor Cyan
Write-Host "Predict endpoint: $httpsUrl/predict" -ForegroundColor Cyan

# Test the deployment
Write-Host ""
Write-Host "Testing the API..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

try {
    $response = Invoke-RestMethod -Uri "$httpsUrl/health" -Method Get -TimeoutSec 30
    Write-Host "Health check passed! Status: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "Health check failed - container might still be starting" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next step: Update your frontend to use $httpsUrl" -ForegroundColor Cyan
