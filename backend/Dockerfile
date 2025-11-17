# Multi-stage build for combined Flask + Nginx container
FROM python:3.11-slim

# Install system dependencies for Flask and Nginx
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    nginx \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install all Python dependencies in one layer with optimizations
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Copy application code and models
COPY app.py explain.py ./
COPY *.pth ./

# Copy Nginx configuration
COPY nginx-azure/nginx.conf /etc/nginx/nginx.conf

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Create nginx directories and set permissions
RUN mkdir -p /var/log/nginx /var/lib/nginx /var/cache/nginx /run/nginx && \
    chown -R www-data:www-data /var/log/nginx /var/lib/nginx /var/cache/nginx /run/nginx

# Create non-root user for Flask app
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    DISABLE_CAM=0 \
    PORT=5000 \
    PYTHONDONTWRITEBYTECODE=1

# Expose port 80 (Nginx)
EXPOSE 80

# Use startup script to run both Flask and Nginx
CMD ["/startup.sh"]