# Azure App Service Deployment Script for Pneumonia Detection API
# More cost-effective than Container Instances with built-in HTTPS support

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
    [string]$DockerImage = "sheryansh/pneumonia-detection:latest",
    
    [Parameter(Mandatory=$false)]
    [string]$PricingTier = "B1"  # Basic tier - cost-effective
)

Write-Host "🚀 Deploying to Azure App Service (Cost-Effective Solution)" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

# Check Azure CLI
try {
    az --version | Out-Null
    Write-Host "✅ Azure CLI is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI is not installed" -ForegroundColor Red
    exit 1
}

# Check login status
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    } else {
        throw "Not logged in"
    }
} catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Create resource group if it doesn't exist
Write-Host "`nCreating/checking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName 2>$null
if ($rgExists -eq "false") {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Cyan
    az group create --name $ResourceGroupName --location $Location --output table
    Write-Host "✅ Resource group created" -ForegroundColor Green
} else {
    Write-Host "✅ Resource group already exists" -ForegroundColor Green
}

# Create App Service Plan
Write-Host "`nCreating App Service Plan..." -ForegroundColor Yellow
try {
    $planExists = az appservice plan show --name $AppServicePlanName --resource-group $ResourceGroupName 2>$null
    if (-not $planExists) {
        Write-Host "Creating App Service Plan: $AppServicePlanName ($PricingTier)" -ForegroundColor Cyan
        az appservice plan create `
            --name $AppServicePlanName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --sku $PricingTier `
            --is-linux `
            --output table
        
        Write-Host "✅ App Service Plan created" -ForegroundColor Green
    } else {
        Write-Host "✅ App Service Plan already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error creating App Service Plan: $_" -ForegroundColor Red
    exit 1
}

# Delete existing web app if it exists
Write-Host "`nChecking for existing web app..." -ForegroundColor Yellow
try {
    $existingApp = az webapp show --name $WebAppName --resource-group $ResourceGroupName 2>$null
    if ($existingApp) {
        Write-Host "Found existing web app. Deleting it..." -ForegroundColor Yellow
        az webapp delete --name $WebAppName --resource-group $ResourceGroupName --output table
        Write-Host "✅ Existing web app deleted" -ForegroundColor Green
        Start-Sleep -Seconds 10
    } else {
        Write-Host "✅ No existing web app found" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not check for existing web app (this is usually fine)" -ForegroundColor Yellow
}

# Create the web app with Docker container
Write-Host "`nCreating Azure Web App with Docker..." -ForegroundColor Yellow
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  - Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  - App Service Plan: $AppServicePlanName" -ForegroundColor White
Write-Host "  - Web App Name: $WebAppName" -ForegroundColor White
Write-Host "  - Location: $Location" -ForegroundColor White
Write-Host "  - Docker Image: $DockerImage" -ForegroundColor White
Write-Host "  - Pricing Tier: $PricingTier" -ForegroundColor White

try {
    az webapp create `
        --name $WebAppName `
        --resource-group $ResourceGroupName `
        --plan $AppServicePlanName `
        --deployment-container-image-name $DockerImage `
        --output table
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Web app created successfully!" -ForegroundColor Green
    } else {
        throw "Web app creation failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "❌ Web app creation failed: $_" -ForegroundColor Red
    exit 1
}

# Configure environment variables
Write-Host "`nConfiguring environment variables..." -ForegroundColor Yellow
az webapp config appsettings set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --settings `
        "DISABLE_CAM=0" `
        "PORT=80" `
        "WEBSITES_PORT=5000" `
    --output table

# Configure container settings
Write-Host "`nConfiguring container settings..." -ForegroundColor Yellow
az webapp config container set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --docker-custom-image-name $DockerImage `
    --output table

# Get web app details
Write-Host "`nRetrieving web app details..." -ForegroundColor Yellow
try {
    $appInfo = az webapp show --name $WebAppName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
    
    $httpsUrl = "https://$($appInfo.defaultHostName)"
    $httpUrl = "http://$($appInfo.defaultHostName)"
    
    Write-Host "`n🎉 AZURE APP SERVICE DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "Web App Name: $($appInfo.name)" -ForegroundColor White
    Write-Host "State: $($appInfo.state)" -ForegroundColor White
    Write-Host "Default Hostname: $($appInfo.defaultHostName)" -ForegroundColor White
    Write-Host "HTTPS URL: $httpsUrl" -ForegroundColor Yellow
    Write-Host "HTTP URL: $httpUrl" -ForegroundColor White
    
    Write-Host "`n🔒 HTTPS API Endpoints:" -ForegroundColor Cyan
    Write-Host "  Health Check: $httpsUrl/health" -ForegroundColor White
    Write-Host "  Home: $httpsUrl/" -ForegroundColor White
    Write-Host "  Prediction: $httpsUrl/predict" -ForegroundColor White
    
    # Save endpoint information to file
    $endpointInfo = @{
        "web_app_name" = $appInfo.name
        "resource_group" = $ResourceGroupName
        "default_hostname" = $appInfo.defaultHostName
        "https_url" = $httpsUrl
        "http_url" = $httpUrl
        "https_health_endpoint" = "$httpsUrl/health"
        "https_predict_endpoint" = "$httpsUrl/predict"
        "pricing_tier" = $PricingTier
        "deployment_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "cost_optimized" = $true
    }
    
    $endpointInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath "azure-appservice-deployment-info.json" -Encoding UTF8
    Write-Host "`n📄 Deployment info saved to: azure-appservice-deployment-info.json" -ForegroundColor Cyan
    
    # Display cost information
    Write-Host "`n💰 Cost Information:" -ForegroundColor Green
    Write-Host "  - Pricing Tier: $PricingTier (Basic)" -ForegroundColor White
    Write-Host "  - Estimated Cost: ~$13-15/month (much cheaper than Container Instances)" -ForegroundColor White
    Write-Host "  - Includes: HTTPS, Custom domains, Auto-scaling, Deployment slots" -ForegroundColor White
    
} catch {
    Write-Host "❌ Error retrieving web app details: $_" -ForegroundColor Red
    exit 1
}

# Test the deployment
Write-Host "`n🧪 Testing the deployed HTTPS API..." -ForegroundColor Yellow
try {
    Write-Host "Waiting for web app to start..." -ForegroundColor Cyan
    Start-Sleep -Seconds 45
    
    $response = Invoke-RestMethod -Uri "$httpsUrl/health" -Method Get -TimeoutSec 30
    Write-Host "✅ HTTPS Health check passed! Status: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not test the HTTPS API immediately (web app might still be starting)" -ForegroundColor Yellow
    Write-Host "   You can test manually in a few minutes at: $httpsUrl/health" -ForegroundColor White
}

Write-Host "`n✨ Cost-Effective HTTPS Deployment Completed!" -ForegroundColor Green
Write-Host "Your Pneumonia Detection API is now running on Azure App Service!" -ForegroundColor Cyan
Write-Host "Benefits: Lower cost, built-in HTTPS, better scaling options! 🎉" -ForegroundColor Green

Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update your frontend to use: $httpsUrl" -ForegroundColor White
Write-Host "2. Test the API endpoints" -ForegroundColor White
Write-Host "3. Monitor performance and costs in Azure portal" -ForegroundColor White
