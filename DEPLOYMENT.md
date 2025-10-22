# 🚀 Current Deployment Configuration

**Last Updated:** October 22, 2025  
**Status:** ✅ Production Ready

---

## 📊 Production System Overview

### 🎨 Frontend

- **Platform:** Vercel Edge Network
- **URL:** https://www.pneumonet.me
- **Backup URL:** https://pneumonet-frontend.vercel.app
- **Status:** ✅ Live (99.9% uptime)

### 🧠 Backend

- **Platform:** Azure Container Instance
- **URL:** http://pneumonia-api-live-2025.centralindia.azurecontainer.io
- **Container:** pneumonia-api-live
- **Region:** Central India
- **Resources:** 2 vCPU, 4GB RAM
- **Status:** ✅ Running

### 🐋 Docker Image

- **Registry:** Docker Hub (Public)
- **Image:** sheryansh/pneumonia-detection:latest
- **URL:** https://hub.docker.com/r/sheryansh/pneumonia-detection
- **Size:** 3.21GB
- **Digest:** sha256:2bbc7d9e6a5cf440f07fc2aefbca360edeecc2073d8a2d566dadb4ec8c790ef3

---

## 🔧 Deployment Configuration

### Container Instance (ACI)

```yaml
apiVersion: 2023-05-01
location: centralindia
name: pneumonia-api-live
properties:
  containers:
    - name: pneumonia-app
      properties:
        image: sheryansh/pneumonia-detection:latest
        resources:
          requests:
            cpu: 2
            memoryInGb: 4
        ports:
          - port: 80
            protocol: TCP
        environmentVariables:
          - name: PORT
            value: "5000"
          - name: PYTHONUNBUFFERED
            value: "1"
          - name: DISABLE_CAM
            value: "0"
  osType: Linux
  restartPolicy: Always
  ipAddress:
    type: Public
    dnsNameLabel: pneumonia-api-live-2025
    ports:
      - protocol: TCP
        port: 80
```

### Vercel Configuration

```json
{
  "rewrites": [
    {
      "source": "/api/(.*)",
      "destination": "http://pneumonia-api-live-2025.centralindia.azurecontainer.io:5000/$1"
    }
  ]
}
```

---

## 🔄 Update Deployment Workflow

### Build & Deploy Backend

```powershell
# 1. Navigate to backend folder
cd "d:\projects\mini project\PneumoniaApp\backend"

# 2. Build Docker image
docker build -f Dockerfile.combined -t pneumonia-detection .

# 3. Tag for Docker Hub
docker tag pneumonia-detection sheryansh/pneumonia-detection:latest

# 4. Push to Docker Hub
docker push sheryansh/pneumonia-detection:latest

# 5. Restart Azure Container Instance to pull new image
az container restart --name pneumonia-api-live --resource-group pneumonia-detection-rg

# 6. Verify deployment
az container show --name pneumonia-api-live --resource-group pneumonia-detection-rg --query "instanceView.state"

# 7. Test health endpoint
curl http://pneumonia-api-live-2025.centralindia.azurecontainer.io/health
```

### Deploy Frontend

```bash
# Frontend auto-deploys via Vercel on git push
cd frontend
git add .
git commit -m "Update frontend"
git push origin main
# Vercel automatically builds and deploys
```

---

## 🔍 Health Checks

### Backend Health

```bash
# Health endpoint
curl http://pneumonia-api-live-2025.centralindia.azurecontainer.io/health

# Expected response
{"status":"ok"}
```

### Container Status

```powershell
# Check container status
az container show --name pneumonia-api-live --resource-group pneumonia-detection-rg --query "instanceView.state"

# View logs
az container logs --name pneumonia-api-live --resource-group pneumonia-detection-rg
```

---

## 💰 Cost Breakdown

| Service                  | Tier                   | Monthly Cost      |
| ------------------------ | ---------------------- | ----------------- |
| Azure Container Instance | Standard (2 vCPU, 4GB) | ~$30-40           |
| Docker Hub               | Free (Public)          | $0                |
| Vercel                   | Hobby (Non-commercial) | $0                |
| **Total**                |                        | **~$30-40/month** |

**Savings from ACR Migration:** $5/month ($60/year)

---

## 📚 Repository Structure

```
PneumoniaApp/
├── backend/
│   ├── app.py                          # Flask API
│   ├── explain.py                      # Grad-CAM implementation
│   ├── Dockerfile.combined             # Production Docker image
│   ├── deployment-new-dns.yaml         # Azure ACI config
│   ├── convnext_pneumonia.pth         # ConvNeXt model weights
│   ├── efficientnet_pneumonia.pth     # EfficientNet weights
│   └── requirements.txt                # Python dependencies
├── frontend/
│   ├── src/
│   │   ├── pages/                      # React pages
│   │   ├── components/                 # UI components
│   │   └── config/api.js              # API configuration
│   ├── vercel.json                     # Vercel proxy config
│   └── package.json                    # Node dependencies
├── archive/
│   ├── chest_xray/                     # Dataset (for local dev)
│   └── deployment/                     # Old deployment configs
├── README.md                           # Main documentation
├── PROJECT_INTERVIEW_GUIDE.md          # Technical interview guide
└── PneumoNet_Conference_Paper_IEEE.md  # Research paper
```

---

## 🔗 Important Links

- **Live Frontend:** https://www.pneumonet.me
- **Backend API:** http://pneumonia-api-live-2025.centralindia.azurecontainer.io
- **GitHub Main:** https://github.com/Sheryansh0/pneumonet-ai-detection
- **GitHub Frontend:** https://github.com/Sheryansh0/pneumonet-frontend
- **Docker Hub:** https://hub.docker.com/r/sheryansh/pneumonia-detection

---

## ⚠️ Notes

1. **No ACR:** Azure Container Registry has been removed to save costs
2. **Public Image:** Docker image is now publicly available on Docker Hub
3. **No Credentials:** Container pulls from Docker Hub don't require authentication
4. **Same Performance:** No change in application performance or functionality
5. **Cost Optimized:** Saving $5/month by using Docker Hub instead of ACR

---

**Deployment Status:** ✅ Fully Operational  
**Last Verified:** October 22, 2025
