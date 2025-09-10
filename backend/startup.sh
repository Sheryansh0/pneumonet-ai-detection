#!/bin/bash

# Azure App Service startup script
echo "Starting Pneumonia Detection API..."

# Set environment variables
export PYTHONUNBUFFERED=1
export DISABLE_CAM=0

# Start the application with gunicorn
exec gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 2 --timeout 300 --preload --access-logfile - --error-logfile - app:app
