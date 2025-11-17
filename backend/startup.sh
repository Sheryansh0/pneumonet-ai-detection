#!/bin/bash

set -euo pipefail

echo "[startup] Starting Pneumonia Detection API with Nginx reverse proxy..."

# Cloud Run provides the HTTP port via $PORT (default 8080 if not set)
export CR_PORT="${PORT:-8080}"
echo "[startup] Cloud Run target port: ${CR_PORT}"

# Ensure Python runs unbuffered and keep existing env for Grad-CAM
export PYTHONUNBUFFERED=${PYTHONUNBUFFERED:-1}
export DISABLE_CAM=${DISABLE_CAM:-0}

# Start Flask app on 5000 in background (Nginx will proxy to it)
echo "[startup] Starting Flask application on 0.0.0.0:5000..."
cd /app
python app.py &
FLASK_PID=$!

echo "[startup] Flask app started with PID: $FLASK_PID"

# Wait for Flask app to be ready
echo "[startup] Waiting for Flask app readiness on :5000/health ..."
for i in {1..40}; do
    if curl -sf http://127.0.0.1:5000/health >/dev/null 2>&1; then
        echo "[startup] Flask app is ready"
        break
    fi
    if [ $i -eq 40 ]; then
        echo "[startup] ERROR: Flask app failed to become ready in time"
        exit 1
    fi
    sleep 1
done

# Update Nginx to listen on Cloud Run's port (default config has `listen 80;`)
echo "[startup] Configuring Nginx to listen on port ${CR_PORT}..."
sed -i "s/listen 80;/listen ${CR_PORT};/g" /etc/nginx/nginx.conf

# Start Nginx in foreground
echo "[startup] Starting Nginx reverse proxy..."
nginx -g "daemon off;" &
NGINX_PID=$!

echo "[startup] Nginx started with PID: $NGINX_PID (listening on ${CR_PORT})"

# Graceful shutdown handler
shutdown() {
    echo "[startup] Shutting down services..."
    kill ${NGINX_PID} ${FLASK_PID} 2>/dev/null || true
    wait ${NGINX_PID} ${FLASK_PID} 2>/dev/null || true
    echo "[startup] Services stopped"
    exit 0
}

trap shutdown SIGTERM SIGINT

# Wait on both processes
wait