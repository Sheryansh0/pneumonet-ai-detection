# Use Python 3.11 slim for smaller image size
FROM python:3.11-slim

# Install only essential system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
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

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    DISABLE_CAM=0 \
    PORT=5000 \
    PYTHONDONTWRITEBYTECODE=1

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

EXPOSE 5000

# Direct command without shell wrapper for better signal handling
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "2", "--timeout", "300", "app:app"]