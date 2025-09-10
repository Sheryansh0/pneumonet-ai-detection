# Archive Directory

This directory contains files that are not needed for production deployment but are kept for reference and future development.

## Directory Structure

### `/training/`

- `train_convnext.py` - ConvNeXt model training script
- `train_efficientnet.py` - EfficientNet model training script
- `requirements-dev.txt` - Development and training dependencies

### `/testing/`

- `comprehensive_test.py` - Full test suite for API validation
- `comprehensive_test_results.json` - Detailed test results
- `test_report.md` - Comprehensive test report
- `test_deployment.py` - Deployment validation script
- `api_response_gradcam.png` - Sample GradCAM output

### `/deployment/`

- `azure-deploy.yaml` - Azure Container Instances YAML config
- `azure-arm-template.json` - Azure ARM template
- `deploy-azure.sh` - Bash deployment script
- `deploy-azure.ps1` - PowerShell deployment script

## Production Files (kept in root)

The following files remain in the root directory as they are essential for production:

- `app.py` - Main Flask application
- `explain.py` - GradCAM explanation functionality
- `test_api.py` - API testing script
- `requirements.txt` - Production dependencies
- `Dockerfile` - Container configuration
- `.dockerignore` - Docker build exclusions
- `web.config` - Azure App Service configuration
- `startup.sh` - Azure startup script
- `*.pth` - Trained model files
- `README.md` - Project documentation

## Dataset Location

The `chest_xray/` dataset remains in the root directory due to file permissions but is not needed for production deployment.

---

_Archive created on: 2025-09-09_
_Purpose: Clean separation of production vs development files_
