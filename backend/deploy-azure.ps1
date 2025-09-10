# Azure Container Instance Deployment Script for Pneumonia Detection API
# Make sure you have Azure CLI installed and are logged in

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "pneumonia-detection-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerInstanceName = "pneumonia-detection-sheryansh",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "centralindia",
    
    [Parameter(Mandatory=$false)]
    [string]$DockerImage = "sheryansh/pneumonia-detection:latest",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5000,
    
    [Parameter(Mandatory=$false)]
    [double]$CpuCores = 2.0,
    
    [Parameter(Mandatory=$false)]
    [double]$MemoryGb = 4.0
)

Write-Host "🚀 Starting Azure Container Instance Deployment" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Check if Azure CLI is installed
Write-Host "Checking Azure CLI installation..." -ForegroundColor Yellow
try {
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
        Write-Host "   Subscription: $($account.name)" -ForegroundColor Cyan
    } else {
        throw "Not logged in"
    }
} catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Create resource group if it doesn't exist
Write-Host "`nCreating/checking resource group..." -ForegroundColor Yellow
try {
    $rgExists = az group exists --name $ResourceGroupName 2>$null
    if ($rgExists -eq "false") {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Cyan
        az group create --name $ResourceGroupName --location $Location --output table
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Resource group created successfully" -ForegroundColor Green
        } else {
            throw "Failed to create resource group"
        }
    } else {
        Write-Host "✅ Resource group already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error with resource group: $_" -ForegroundColor Red
    exit 1
}

# Delete existing container instance if it exists
Write-Host "`nChecking for existing container instance..." -ForegroundColor Yellow
try {
    $existingContainer = az container show --resource-group $ResourceGroupName --name $ContainerInstanceName 2>$null
    if ($existingContainer) {
        Write-Host "Found existing container instance. Deleting it..." -ForegroundColor Yellow
        az container delete --resource-group $ResourceGroupName --name $ContainerInstanceName --yes --output table
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Existing container deleted" -ForegroundColor Green
            Start-Sleep -Seconds 10  # Wait for deletion to complete
        }
    } else {
        Write-Host "✅ No existing container found" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not check for existing container (this is usually fine)" -ForegroundColor Yellow
}

# Deploy the container instance
Write-Host "`nDeploying container instance..." -ForegroundColor Yellow
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  - Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  - Container Name: $ContainerInstanceName" -ForegroundColor White
Write-Host "  - Location: $Location" -ForegroundColor White
Write-Host "  - Docker Image: $DockerImage" -ForegroundColor White
Write-Host "  - CPU Cores: $CpuCores" -ForegroundColor White
Write-Host "  - Memory: ${MemoryGb}GB" -ForegroundColor White
Write-Host "  - Port: $Port" -ForegroundColor White

try {
    $deployCommand = @"
az container create \
  --resource-group $ResourceGroupName \
  --name $ContainerInstanceName \
  --image $DockerImage \
  --dns-name-label $ContainerInstanceName \
  --ports $Port \
  --cpu $CpuCores \
  --memory $MemoryGb \
  --restart-policy Always \
  --environment-variables DISABLE_CAM=0 PORT=$Port \
  --location $Location \
  --output table
"@

    Write-Host "`nExecuting deployment command..." -ForegroundColor Cyan
    Invoke-Expression $deployCommand.Replace('\', '')
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Container instance deployed successfully!" -ForegroundColor Green
    } else {
        throw "Deployment failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    exit 1
}

# Get container instance details
Write-Host "`nRetrieving container instance details..." -ForegroundColor Yellow
try {
    $containerInfo = az container show --resource-group $ResourceGroupName --name $ContainerInstanceName --output json | ConvertFrom-Json
    
    Write-Host "`n🎉 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    Write-Host "Container Name: $($containerInfo.name)" -ForegroundColor White
    Write-Host "State: $($containerInfo.containers[0].instanceView.currentState.state)" -ForegroundColor White
    Write-Host "FQDN: $($containerInfo.ipAddress.fqdn)" -ForegroundColor Yellow
    Write-Host "IP Address: $($containerInfo.ipAddress.ip)" -ForegroundColor White
    Write-Host "Port: $($containerInfo.ipAddress.ports[0].port)" -ForegroundColor White
    
    $apiUrl = "http://$($containerInfo.ipAddress.fqdn):$($containerInfo.ipAddress.ports[0].port)"
    Write-Host "`n🌐 API Endpoints:" -ForegroundColor Cyan
    Write-Host "  Health Check: $apiUrl/health" -ForegroundColor White
    Write-Host "  Home: $apiUrl/" -ForegroundColor White
    Write-Host "  Prediction: $apiUrl/predict" -ForegroundColor White
    
    # Save endpoint information to file
    $endpointInfo = @{
        "container_name" = $containerInfo.name
        "resource_group" = $ResourceGroupName
        "fqdn" = $containerInfo.ipAddress.fqdn
        "ip_address" = $containerInfo.ipAddress.ip
        "port" = $containerInfo.ipAddress.ports[0].port
        "api_url" = $apiUrl
        "health_endpoint" = "$apiUrl/health"
        "predict_endpoint" = "$apiUrl/predict"
        "deployment_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $endpointInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath "azure-deployment-info.json" -Encoding UTF8
    Write-Host "`n📄 Deployment info saved to: azure-deployment-info.json" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error retrieving container details: $_" -ForegroundColor Red
    exit 1
}

# Test the deployment
Write-Host "`n🧪 Testing the deployed API..." -ForegroundColor Yellow
try {
    $healthUrl = "$apiUrl/health"
    Write-Host "Testing health endpoint: $healthUrl" -ForegroundColor Cyan
    
    # Wait a bit for container to fully start
    Start-Sleep -Seconds 30
    
    $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 30
    if ($response.status -eq "ok" -or $response.status -eq "loading") {
        Write-Host "✅ Health check passed! Status: $($response.status)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Health check returned: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not test the API immediately (container might still be starting)" -ForegroundColor Yellow
    Write-Host "   You can test manually in a few minutes at: $apiUrl/health" -ForegroundColor White
}

Write-Host "`n✨ Deployment completed successfully!" -ForegroundColor Green
Write-Host "Your Pneumonia Detection API is now running on Azure!" -ForegroundColor Cyan
