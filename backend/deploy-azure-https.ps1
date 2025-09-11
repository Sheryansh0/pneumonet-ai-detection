# Azure Container Apps Deployment with HTTPS
# This replaces Azure Container Instances with Container Apps which supports HTTPS natively

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

Write-Host "🚀 Starting Azure Container Apps Deployment with HTTPS" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# Check if Azure CLI is installed and logged in
Write-Host "Checking Azure CLI installation..." -ForegroundColor Yellow
try {
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if containerapp extension is installed
Write-Host "Checking Container Apps extension..." -ForegroundColor Yellow
$extensions = az extension list --output json | ConvertFrom-Json
$containerAppExt = $extensions | Where-Object { $_.name -eq "containerapp" }

if (-not $containerAppExt) {
    Write-Host "Installing Container Apps extension..." -ForegroundColor Cyan
    az extension add --name containerapp --yes
    Write-Host "✅ Container Apps extension installed" -ForegroundColor Green
} else {
    Write-Host "✅ Container Apps extension already installed" -ForegroundColor Green
}

# Register providers
Write-Host "Registering required providers..." -ForegroundColor Yellow
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait
Write-Host "✅ Providers registered" -ForegroundColor Green

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
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
    Write-Host "✅ Resource group created successfully" -ForegroundColor Green
} else {
    Write-Host "✅ Resource group already exists" -ForegroundColor Green
}

# Create Container Apps environment
Write-Host "`nCreating Container Apps environment..." -ForegroundColor Yellow
try {
    $envExists = az containerapp env show --name $ContainerAppEnvName --resource-group $ResourceGroupName 2>$null
    if (-not $envExists) {
        Write-Host "Creating Container Apps environment: $ContainerAppEnvName" -ForegroundColor Cyan
        az containerapp env create `
            --name $ContainerAppEnvName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --output table
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Container Apps environment created successfully" -ForegroundColor Green
        } else {
            throw "Failed to create Container Apps environment"
        }
    } else {
        Write-Host "✅ Container Apps environment already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error with Container Apps environment: $_" -ForegroundColor Red
    exit 1
}

# Delete existing container app if it exists
Write-Host "`nChecking for existing container app..." -ForegroundColor Yellow
try {
    $existingApp = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName 2>$null
    if ($existingApp) {
        Write-Host "Found existing container app. Deleting it..." -ForegroundColor Yellow
        az containerapp delete --name $ContainerAppName --resource-group $ResourceGroupName --yes --output table
        Write-Host "✅ Existing container app deleted" -ForegroundColor Green
        Start-Sleep -Seconds 10
    } else {
        Write-Host "✅ No existing container app found" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not check for existing container app (this is usually fine)" -ForegroundColor Yellow
}

# Create the container app with HTTPS
Write-Host "`nDeploying container app with HTTPS..." -ForegroundColor Yellow
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  - Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  - Container App Name: $ContainerAppName" -ForegroundColor White
Write-Host "  - Environment: $ContainerAppEnvName" -ForegroundColor White
Write-Host "  - Location: $Location" -ForegroundColor White
Write-Host "  - Docker Image: $DockerImage" -ForegroundColor White

try {
    az containerapp create `
        --name $ContainerAppName `
        --resource-group $ResourceGroupName `
        --environment $ContainerAppEnvName `
        --image $DockerImage `
        --target-port 5000 `
        --ingress external `
        --transport http `
        --cpu 2.0 `
        --memory 4.0Gi `
        --min-replicas 1 `
        --max-replicas 3 `
        --env-vars "DISABLE_CAM=0" "PORT=5000" `
        --output table
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Container app deployed successfully!" -ForegroundColor Green
    } else {
        throw "Deployment failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    exit 1
}

# Get container app details
Write-Host "`nRetrieving container app details..." -ForegroundColor Yellow
try {
    $appInfo = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
    
    Write-Host "`n🎉 HTTPS DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Green
    Write-Host "Container App Name: $($appInfo.name)" -ForegroundColor White
    Write-Host "State: $($appInfo.properties.runningStatus)" -ForegroundColor White
    Write-Host "HTTPS URL: https://$($appInfo.properties.configuration.ingress.fqdn)" -ForegroundColor Yellow
    Write-Host "HTTP URL: http://$($appInfo.properties.configuration.ingress.fqdn)" -ForegroundColor White
    
    $httpsApiUrl = "https://$($appInfo.properties.configuration.ingress.fqdn)"
    $httpApiUrl = "http://$($appInfo.properties.configuration.ingress.fqdn)"
    
    Write-Host "`n🔒 HTTPS API Endpoints:" -ForegroundColor Cyan
    Write-Host "  Health Check: $httpsApiUrl/health" -ForegroundColor White
    Write-Host "  Home: $httpsApiUrl/" -ForegroundColor White
    Write-Host "  Prediction: $httpsApiUrl/predict" -ForegroundColor White
    
    Write-Host "`n🌐 HTTP API Endpoints (also available):" -ForegroundColor Cyan
    Write-Host "  Health Check: $httpApiUrl/health" -ForegroundColor White
    Write-Host "  Home: $httpApiUrl/" -ForegroundColor White
    Write-Host "  Prediction: $httpApiUrl/predict" -ForegroundColor White
    
    # Save endpoint information to file
    $endpointInfo = @{
        "container_app_name" = $appInfo.name
        "resource_group" = $ResourceGroupName
        "fqdn" = $appInfo.properties.configuration.ingress.fqdn
        "https_api_url" = $httpsApiUrl
        "http_api_url" = $httpApiUrl
        "https_health_endpoint" = "$httpsApiUrl/health"
        "https_predict_endpoint" = "$httpsApiUrl/predict"
        "http_health_endpoint" = "$httpApiUrl/health"
        "http_predict_endpoint" = "$httpApiUrl/predict"
        "deployment_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "supports_https" = $true
    }
    
    $endpointInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath "azure-https-deployment-info.json" -Encoding UTF8
    Write-Host "`n📄 HTTPS deployment info saved to: azure-https-deployment-info.json" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error retrieving container app details: $_" -ForegroundColor Red
    exit 1
}

# Test the HTTPS deployment
Write-Host "`n🧪 Testing the deployed HTTPS API..." -ForegroundColor Yellow
try {
    $httpsHealthUrl = "$httpsApiUrl/health"
    Write-Host "Testing HTTPS health endpoint: $httpsHealthUrl" -ForegroundColor Cyan
    
    # Wait for container to fully start
    Start-Sleep -Seconds 45
    
    $response = Invoke-RestMethod -Uri $httpsHealthUrl -Method Get -TimeoutSec 30
    if ($response.status -eq "ok" -or $response.status -eq "loading") {
        Write-Host "✅ HTTPS Health check passed! Status: $($response.status)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ HTTPS Health check returned: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not test the HTTPS API immediately (container might still be starting)" -ForegroundColor Yellow
    Write-Host "   You can test manually in a few minutes at: $httpsApiUrl/health" -ForegroundColor White
}

Write-Host "`n✨ HTTPS Deployment completed successfully!" -ForegroundColor Green
Write-Host "Your Pneumonia Detection API now supports HTTPS!" -ForegroundColor Cyan
Write-Host "No more Mixed Content Policy issues! 🎉" -ForegroundColor Green

# Display next steps
Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update your frontend to use the HTTPS URL: $httpsApiUrl" -ForegroundColor White
Write-Host "2. Test the API endpoints to ensure they're working" -ForegroundColor White
Write-Host "3. Update any environment variables in your frontend" -ForegroundColor White
