# Manual Azure Deployment Helper Script
# This script guides you through the manual Azure deployment process step by step

param(
    [Parameter(Mandatory=$false)]
    [string]$Email = "bachchushreyansh@gmail.com",
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionName = "",
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "pneumonia-detection-rg"
)

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Green { Write-ColorOutput Green $args }
function Write-Yellow { Write-ColorOutput Yellow $args }
function Write-Red { Write-ColorOutput Red $args }
function Write-Blue { Write-ColorOutput Blue $args }

function Wait-ForUserInput($message) {
    Write-Yellow $message
    Write-Host "Press Enter to continue..." -NoNewline
    Read-Host
}

function Test-Command($command) {
    try {
        & $command --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

Write-Green "🚀 Pneumonia Detection API - Manual Azure Deployment Helper"
Write-Green "============================================================"
Write-Host ""

Write-Blue "This script will guide you through manually deploying your API to Azure."
Write-Blue "We'll go through each step and provide the commands you need to run."
Write-Host ""

# Step 1: Prerequisites Check
Write-Yellow "Step 1: Checking Prerequisites"
Write-Host "==============================="

$prerequisites = @()

# Check Docker
if (Test-Command "docker") {
    Write-Green "✅ Docker is installed"
} else {
    Write-Red "❌ Docker is not installed or not in PATH"
    $prerequisites += "Install Docker Desktop from https://docker.com/products/docker-desktop"
}

# Check Azure CLI
if (Test-Command "az") {
    Write-Green "✅ Azure CLI is installed"
} else {
    Write-Red "❌ Azure CLI is not installed"
    $prerequisites += "Install Azure CLI from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
}

# Check if logged in to Azure
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Green "✅ Logged in to Azure as: $($account.user.name)"
        Write-Blue "   Subscription: $($account.name)"
    }
} catch {
    Write-Red "❌ Not logged in to Azure"
    $prerequisites += "Run 'az login' to log in to Azure"
}

if ($prerequisites.Count -gt 0) {
    Write-Red "`nPlease complete the following prerequisites:"
    foreach ($prereq in $prerequisites) {
        Write-Red "  - $prereq"
    }
    Write-Host "`nPress Enter to exit..."
    Read-Host
    exit 1
}

Wait-ForUserInput "`nAll prerequisites met! Ready to proceed."

# Step 2: Build Docker Image
Write-Yellow "`nStep 2: Building Docker Images"
Write-Host "==============================="

Write-Blue "We'll build a combined Docker image with Flask + Nginx"
Write-Host ""

$buildCommands = @(
    "# Navigate to backend directory",
    "cd 'D:\projects\mini project\PneumoniaApp\backend'",
    "",
    "# Build the combined image",
    "docker build -f Dockerfile.combined -t pneumonia-combined:latest .",
    "",
    "# Verify the image was created",
    "docker images | findstr pneumonia-combined"
)

Write-Blue "Run these commands in PowerShell:"
foreach ($cmd in $buildCommands) {
    if ($cmd -like "#*" -or $cmd -eq "") {
        Write-Green $cmd
    } else {
        Write-Host "  $cmd"
    }
}

Wait-ForUserInput "`nAfter building the image, continue to the next step."

# Step 3: Test Image Locally (Optional)
Write-Yellow "`nStep 3: Test Image Locally (Optional)"
Write-Host "======================================"

Write-Blue "You can optionally test the image locally before deploying:"
Write-Host ""

$testCommands = @(
    "# Start the container locally",
    "docker run -d -p 8080:80 --name test-pneumonia pneumonia-combined:latest",
    "",
    "# Test the health endpoint",
    "curl http://localhost:8080/health",
    "",
    "# If working, stop and remove the test container",
    "docker stop test-pneumonia",
    "docker rm test-pneumonia"
)

foreach ($cmd in $testCommands) {
    if ($cmd -like "#*" -or $cmd -eq "") {
        Write-Green $cmd
    } else {
        Write-Host "  $cmd"
    }
}

Wait-ForUserInput "`nSkip local testing if you want, or test and then continue."

# Step 4: Azure Container Registry
Write-Yellow "`nStep 4: Azure Container Registry Setup"
Write-Host "======================================"

Write-Blue "Now we'll create an Azure Container Registry and push your image."
Write-Host ""

Write-Blue "4.1: Create Container Registry in Azure Portal"
Write-Host "  1. Go to https://portal.azure.com"
Write-Host "  2. Click 'Create a resource'"
Write-Host "  3. Search for 'Container Registry'"
Write-Host "  4. Click 'Create'"
Write-Host ""
Write-Host "  Fill in these details:"
Write-Host "    Subscription: [Your subscription]"
Write-Host "    Resource Group: $ResourceGroup (create new if doesn't exist)"
Write-Host "    Registry name: pneumoniadetectionacr (must be unique globally)"
Write-Host "    Location: Central India"
Write-Host "    SKU: Basic"
Write-Host ""
Write-Host "  5. Click 'Review + create' then 'Create'"
Write-Host "  6. Wait for deployment (2-3 minutes)"

Wait-ForUserInput "`nAfter creating the Container Registry, continue."

Write-Blue "4.2: Enable Admin Access"
Write-Host "  1. Go to your Container Registry resource"
Write-Host "  2. Click 'Access keys' in the left menu"
Write-Host "  3. Enable 'Admin user' toggle"
Write-Host "  4. Copy the Login server, Username, and Password"

Wait-ForUserInput "`nAfter enabling admin access, continue."

Write-Blue "4.3: Login and Push Image"
Write-Host ""

$acrCommands = @(
    "# Login to your Azure Container Registry",
    "az acr login --name pneumoniadetectionacr",
    "",
    "# Tag your image for ACR",
    "docker tag pneumonia-combined:latest pneumoniadetectionacr.azurecr.io/pneumonia-combined:latest",
    "",
    "# Push to ACR",
    "docker push pneumoniadetectionacr.azurecr.io/pneumonia-combined:latest",
    "",
    "# Verify the push",
    "az acr repository list --name pneumoniadetectionacr --output table"
)

Write-Blue "Run these commands:"
foreach ($cmd in $acrCommands) {
    if ($cmd -like "#*" -or $cmd -eq "") {
        Write-Green $cmd
    } else {
        Write-Host "  $cmd"
    }
}

Wait-ForUserInput "`nAfter pushing the image to ACR, continue."

# Step 5: Create Container Instance
Write-Yellow "`nStep 5: Create Azure Container Instance"
Write-Host "======================================="

Write-Blue "Now we'll create the Container Instance through Azure Portal."
Write-Host ""

Write-Blue "5.1: Navigate to Container Instances"
Write-Host "  1. In Azure Portal, click 'Create a resource'"
Write-Host "  2. Search for 'Container Instances'"
Write-Host "  3. Click 'Create'"

Write-Blue "`n5.2: Basic Configuration"
Write-Host "  Basics Tab:"
Write-Host "    Subscription: [Your subscription]"
Write-Host "    Resource Group: $ResourceGroup"
Write-Host "    Container name: pneumonia-https-manual"
Write-Host "    Region: Central India"
Write-Host "    Image source: Azure Container Registry"
Write-Host "    Registry: pneumoniadetectionacr"
Write-Host "    Image: pneumonia-combined"
Write-Host "    Image tag: latest"
Write-Host ""
Write-Host "  Size:"
Write-Host "    CPU cores: 2"
Write-Host "    Memory (GB): 4"

Write-Blue "`n5.3: Networking Configuration"
Write-Host "  Networking Tab:"
Write-Host "    Networking type: Public"
Write-Host "    DNS name label: pneumonia-detection-sheryansh"
Write-Host "    Ports: 80 (TCP)"

Write-Blue "`n5.4: Advanced Configuration"
Write-Host "  Advanced Tab:"
Write-Host ""
Write-Host "  Environment Variables:"
Write-Host "    DISABLE_CAM: 0"
Write-Host "    PORT: 5000"
Write-Host "    PYTHONUNBUFFERED: 1"
Write-Host ""
Write-Host "  Command Override:"
Write-Host "    /startup.sh"

Write-Blue "`n5.5: Create Container"
Write-Host "  1. Click 'Review + create'"
Write-Host "  2. Verify all settings"
Write-Host "  3. Click 'Create'"
Write-Host "  4. Wait for deployment (5-10 minutes)"

Wait-ForUserInput "`nAfter creating the Container Instance, continue."

# Step 6: Test Deployment
Write-Yellow "`nStep 6: Test Your Deployment"
Write-Host "============================="

Write-Blue "Your API should now be accessible at:"
Write-Green "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
Write-Host ""

$testingCommands = @(
    "# Test health endpoint",
    "curl http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health",
    "",
    "# Test main endpoint",
    "curl http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/",
    "",
    "# Test with a simple prediction (if you have a test image)",
    "curl -X POST http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/predict -F 'file=@test-image.jpg'"
)

Write-Blue "Test your deployment with these commands:"
foreach ($cmd in $testingCommands) {
    if ($cmd -like "#*" -or $cmd -eq "") {
        Write-Green $cmd
    } else {
        Write-Host "  $cmd"
    }
}

Wait-ForUserInput "`nAfter testing your deployment, continue."

# Step 7: Update Frontend
Write-Yellow "`nStep 7: Update Frontend Configuration"
Write-Host "====================================="

Write-Blue "Now update your frontend to use the new backend URL."
Write-Host ""

Write-Blue "7.1: Update API Configuration"
Write-Host "  Edit: frontend/src/config/api.js"
Write-Host "  Change BASE_URL to:"
Write-Green "  http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"

Write-Blue "`n7.2: Update Environment Variables"
Write-Host "  Edit: frontend/.env.production"
Write-Host "  Change REACT_APP_API_URL to:"
Write-Green "  http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"

Write-Blue "`n7.3: Redeploy Frontend"
Write-Host "  If using Vercel:"
Write-Host "    cd 'D:\projects\mini project\PneumoniaApp\frontend'"
Write-Host "    npm run build"
Write-Host "    vercel --prod"

Wait-ForUserInput "`nAfter updating and redeploying your frontend, continue."

# Step 8: Troubleshooting
Write-Yellow "`nStep 8: Troubleshooting Tips"
Write-Host "============================"

Write-Blue "If you encounter issues:"
Write-Host ""

Write-Blue "8.1: Check Container Logs"
Write-Host "  In Azure Portal:"
Write-Host "  1. Go to your Container Instance"
Write-Host "  2. Click 'Containers' in left menu"
Write-Host "  3. Click 'Logs' tab"
Write-Host "  4. Check for error messages"

Write-Blue "`n8.2: Common Issues"
Write-Host "  - Container fails to start: Check Dockerfile and startup script"
Write-Host "  - Can't access endpoints: Verify networking configuration"
Write-Host "  - CORS errors: Check nginx configuration allows your frontend domain"
Write-Host "  - Performance issues: Consider scaling up CPU/memory"

Write-Blue "`n8.3: Useful Commands"
$troubleshootCommands = @(
    "# Check container status",
    "az container show --resource-group $ResourceGroup --name pneumonia-https-manual --query 'instanceView.state'",
    "",
    "# Get container logs",
    "az container logs --resource-group $ResourceGroup --name pneumonia-https-manual",
    "",
    "# Get container IP and FQDN",
    "az container show --resource-group $ResourceGroup --name pneumonia-https-manual --query 'ipAddress'"
)

foreach ($cmd in $troubleshootCommands) {
    if ($cmd -like "#*" -or $cmd -eq "") {
        Write-Green $cmd
    } else {
        Write-Host "  $cmd"
    }
}

# Final Summary
Write-Green "`n🎉 Deployment Complete!"
Write-Green "======================="
Write-Host ""
Write-Blue "Your API should now be accessible at:"
Write-Green "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io"
Write-Host ""
Write-Blue "Next steps:"
Write-Host "  1. Test all API endpoints thoroughly"
Write-Host "  2. Update and redeploy your frontend"
Write-Host "  3. Monitor container performance and logs"
Write-Host "  4. Consider adding HTTPS with Application Gateway for production"
Write-Host ""
Write-Green "Your mixed content error should now be resolved!"
Write-Host ""

Write-Host "Press Enter to exit..."
Read-Host