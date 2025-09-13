# SSL Certificate Management for Pneumonia Detection API

This directory contains scripts and configuration for managing SSL certificates using Let's Encrypt.

## Files Overview

- **setup-ssl.sh**: Initial SSL certificate setup script
- **renew-ssl.sh**: Certificate renewal script
- **nginx.conf**: Nginx configuration with SSL termination

## Quick Setup

### 1. Prerequisites
- Docker and Docker Compose installed
- Domain pointing to your Azure Container Instance
- Port 80 and 443 accessible

### 2. Initial Setup
```bash
# Make scripts executable
chmod +x scripts/setup-ssl.sh
chmod +x scripts/renew-ssl.sh

# Update email in setup-ssl.sh
nano scripts/setup-ssl.sh  # Change EMAIL variable

# Run SSL setup
./scripts/setup-ssl.sh
```

### 3. Verify Setup
```bash
# Check services status
docker-compose ps

# Test HTTPS endpoint
curl -I https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health

# View logs
docker-compose logs nginx
```

## Certificate Management

### Manual Renewal
```bash
./scripts/renew-ssl.sh
```

### Automatic Renewal
The setup script configures a cron job for automatic renewal:
```bash
# Check cron job
crontab -l

# Manual cron setup if needed
(crontab -l; echo "0 12 * * * cd $(pwd) && ./scripts/renew-ssl.sh") | crontab -
```

## Troubleshooting

### Certificate Generation Issues
```bash
# Check domain accessibility
ping pneumonia-detection-sheryansh.centralindia.azurecontainer.io

# Check DNS configuration
nslookup pneumonia-detection-sheryansh.centralindia.azurecontainer.io

# View certbot logs
docker-compose logs certbot
```

### Nginx Issues
```bash
# Test nginx configuration
docker-compose exec nginx nginx -t

# Reload nginx
docker-compose exec nginx nginx -s reload

# View nginx logs
docker-compose logs nginx
```

### Service Health Check
```bash
# Check all services
docker-compose ps

# Check individual service logs
docker-compose logs flask-app
docker-compose logs nginx
docker-compose logs certbot
```

## Directory Structure
```
backend/
├── docker-compose.yml          # Multi-container setup
├── nginx/
│   ├── nginx.conf             # Nginx configuration
│   └── logs/                  # Nginx logs
├── certbot/
│   ├── conf/                  # Certificate storage
│   ├── www/                   # ACME challenge files
│   └── logs/                  # Certbot logs
├── scripts/
│   ├── setup-ssl.sh           # Initial setup
│   ├── renew-ssl.sh           # Renewal script
│   └── README.md              # This file
└── logs/                      # Application logs
```

## Security Features

### Nginx Security
- HSTS (HTTP Strict Transport Security)
- Security headers (X-Frame-Options, CSP, etc.)
- Rate limiting for API endpoints
- Secure SSL/TLS configuration

### Certificate Security
- Let's Encrypt trusted certificates
- Automatic renewal (30 days before expiry)
- Strong cipher suites (TLSv1.2/1.3)
- OCSP stapling support

## API Endpoints

After SSL setup, your API will be available at:
- **Health Check**: `https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health`
- **Prediction**: `https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/predict`
- **Root**: `https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/`

## Frontend Integration

Update your frontend configuration to use HTTPS:
```javascript
const API_BASE_URL = "https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io";
```

## Monitoring

### Log Monitoring
```bash
# Real-time logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f nginx
docker-compose logs -f flask-app
docker-compose logs -f certbot

# SSL renewal logs
tail -f logs/ssl-renewal.log
```

### Health Monitoring
```bash
# Check service health
curl -I https://pneumonia-detection-sheryansh.centralindia.azurecontainer.io/health

# Check certificate validity
openssl s_client -connect pneumonia-detection-sheryansh.centralindia.azurecontainer.io:443 -servername pneumonia-detection-sheryansh.centralindia.azurecontainer.io < /dev/null | openssl x509 -noout -dates
```

## Support

For issues:
1. Check service logs: `docker-compose logs`
2. Verify domain DNS: `nslookup domain`
3. Test HTTP connectivity: `curl -I http://domain/health`
4. Check certificate files exist in `./certbot/conf/live/domain/`