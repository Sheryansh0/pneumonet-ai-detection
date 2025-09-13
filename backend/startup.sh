#!/bin/bash

echo "Starting Pneumonia Detection API with Nginx reverse proxy..."

# Start Flask app in background
echo "Starting Flask application..."
cd /app
export PYTHONUNBUFFERED=1
export DISABLE_CAM=0
export PORT=5000

# Start Flask app in background
python app.py &
FLASK_PID=$!

echo "Flask app started with PID: $FLASK_PID"

# Wait for Flask app to be ready
echo "Waiting for Flask app to be ready..."
for i in {1..30}; do
    if curl -f http://localhost:5000/health >/dev/null 2>&1; then
        echo "Flask app is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Flask app failed to start within 30 seconds"
        exit 1
    fi
    sleep 1
done

# Start Nginx in foreground
echo "Starting Nginx reverse proxy..."
nginx -g "daemon off;" &
NGINX_PID=$!

echo "Nginx started with PID: $NGINX_PID"

# Function to handle shutdown
shutdown() {
    echo "Shutting down services..."
    kill $NGINX_PID $FLASK_PID
    wait $NGINX_PID $FLASK_PID
    echo "Services stopped"
    exit 0
}

# Trap signals
trap shutdown SIGTERM SIGINT

# Wait for either process to exit
wait