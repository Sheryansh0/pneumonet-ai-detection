# Azure deployment script for Pneumonia Detection API (PowerShell)
# Make sure you have Azure CLI installed and are logged in

param(
    [string]$ResourceGroup = "pneumonia-detection-rg",
    [string]$ContainerGroupName = "pneumonia-detection-api",
    [string]$Location = "centralindia",
    [string]$ImageName = "sheryansh/pneumonia-detection-api:latest",
    [string]$DnsName = "pneumonia-detection-sheryansh"
)

Write-Host "🚀 Starting Azure deployment for Pneumonia Detection API..." -ForegroundColor Green

# Check if logged in to Azure
Write-Host "📋 Checking Azure login status..." -ForegroundColor Yellow
try {
    az account show | Out-Null
} catch {
    Write-Host "❌ Please login to Azure CLI first: az login" -ForegroundColor Red
    exit 1
}

# Create resource group if it doesn't exist
Write-Host "📦 Creating resource group: $ResourceGroup" -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output table

# Deploy container instance
Write-Host "🐳 Deploying container instance: $ContainerGroupName" -ForegroundColor Yellow
az container create `
    --resource-group $ResourceGroup `
    --name $ContainerGroupName `
    --image $ImageName `
    --dns-name-label $DnsName `
    --ports 5000 `
    --cpu 2 `
    --memory 8 `
    --restart-policy Always `
    --environment-variables `
        PYTHONUNBUFFERED=1 `
        DISABLE_CAM=0 `
        PORT=5000 `
    --output table

# Get the FQDN
Write-Host "🌐 Getting deployment information..." -ForegroundColor Yellow
$FQDN = az container show `
    --resource-group $ResourceGroup `
    --name $ContainerGroupName `
    --query ipAddress.fqdn `
    --output tsv

Write-Host ""
Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host "🔗 Your API is available at: http://$FQDN`:5000" -ForegroundColor Cyan
Write-Host "🏥 Health check: http://$FQDN`:5000/health" -ForegroundColor Cyan
Write-Host "🔮 Prediction endpoint: http://$FQDN`:5000/predict" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 To check logs:" -ForegroundColor Yellow
Write-Host "   az container logs --resource-group $ResourceGroup --name $ContainerGroupName" -ForegroundColor White
Write-Host ""
Write-Host "🗑️  To delete the deployment:" -ForegroundColor Yellow
Write-Host "   az group delete --name $ResourceGroup --yes --no-wait" -ForegroundColor White
