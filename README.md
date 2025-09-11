# 🫁 PneumoNet - AI-Powered Pneumonia Detection System

<div align="center">
  <img src="https://res.cloudinary.com/djfhbyk7a/image/upload/v1757540079/cropped_circle_image_mg7gem.png" alt="PneumoNet Logo" width="120" height="120">
  
  **Advanced AI-powered chest X-ray analysis for rapid and accurate pneumonia detection**
  
  [![React](https://img.shields.io/badge/React-18.2.0-blue.svg)](https://reactjs.org/)
  [![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://python.org/)
  [![TensorFlow](https://img.shields.io/badge/TensorFlow-2.x-orange.svg)](https://tensorflow.org/)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
</div>

## 🌟 Features

### 🔬 **AI-Powered Analysis**

- **88.9% Accuracy** in pneumonia detection
- **Dual Model Architecture**: EfficientNet + ConvNeXt ensemble
- **GradCAM Visualization** for explainable AI diagnostics
- **1.36s Average** analysis time

### 🎨 **Modern UI/UX**

- **Responsive Design** with Tailwind CSS
- **3D Gradient Animations** for immersive experience
- **Professional Medical Interface** with dark theme
- **Real-time Progress Tracking** during analysis

### 📊 **Comprehensive Reporting**

- **PDF Report Generation** with embedded X-ray images
- **GradCAM Heatmaps** showing AI focus areas
- **Medical Disclaimers** and professional formatting
- **Downloadable Results** for medical records

### 🚀 **Production Ready**

- **Azure Cloud Deployment** with container support
- **Vercel Frontend Hosting** for optimal performance
- **Docker Containerization** for easy deployment
- **Environment Configuration** for multiple stages

## 🏗️ Architecture

```
PneumoNet/
├── 🎨 frontend/          # React.js Frontend
│   ├── src/
│   │   ├── components/   # Reusable UI components
│   │   ├── pages/        # Main application pages
│   │   ├── hooks/        # Custom React hooks
│   │   └── utils/        # Utility functions
│   ├── public/           # Static assets
│   └── build/            # Production build
│
├── 🧠 backend/           # Python Flask API
│   ├── app.py            # Main Flask application
│   ├── models/           # AI model files (.pth)
│   ├── utils/            # Helper functions
│   └── deployment/       # Azure deployment configs
│
└── 📚 docs/              # Documentation
```

## 🚀 Quick Start

### Prerequisites

- **Node.js** 16+ and npm
- **Python** 3.8+ with pip
- **Git** for version control

### 🖥️ Frontend Setup

```bash
cd frontend
npm install
npm start
# Opens http://localhost:3000
```

### 🐍 Backend Setup

```bash
cd backend
pip install -r requirements.txt
python app.py
# API available at http://localhost:5000
```

## 🔧 Technology Stack

### Frontend

- **⚛️ React 18** - Modern UI framework
- **🎨 Tailwind CSS** - Utility-first styling
- **🧭 React Router** - Client-side routing
- **📄 jsPDF** - PDF report generation
- **🎯 Lucide React** - Beautiful icons

### Backend

- **🐍 Flask** - Python web framework
- **🧠 TensorFlow/PyTorch** - Deep learning models
- **🖼️ OpenCV** - Image processing
- **☁️ Azure** - Cloud deployment
- **🐳 Docker** - Containerization

### AI Models

- **📊 EfficientNet-B0** - Lightweight CNN architecture
- **🔄 ConvNeXt** - Modern vision transformer
- **👁️ GradCAM** - Explainable AI visualization
- **📈 Ensemble Method** - Combined model predictions

## 📊 Model Performance

| Metric    | EfficientNet | ConvNeXt | Ensemble  |
| --------- | ------------ | -------- | --------- |
| Accuracy  | 86.2%        | 87.4%    | **88.9%** |
| Precision | 84.1%        | 85.8%    | **87.2%** |
| Recall    | 88.3%        | 86.9%    | **89.1%** |
| F1-Score  | 86.1%        | 86.3%    | **88.1%** |

## 🌐 Deployment

### Frontend (Vercel)

```bash
# Automatic deployment on push to main
vercel --prod
```

### Backend (Azure)

```bash
# Deploy to Azure Container Instances
az container create --resource-group pneumonet-rg --file azure-arm-template.json
```

## 🔐 Environment Variables

### Frontend (.env.production)

```env
REACT_APP_API_URL=https://your-backend-url.com
GENERATE_SOURCEMAP=false
```

### Backend (.env)

```env
FLASK_ENV=production
MODEL_PATH=/path/to/models
ALLOWED_ORIGINS=https://your-frontend-url.com
```

## 📸 Screenshots

<div align="center">
  <img src="screenshots/homepage.png" alt="Homepage" width="45%">
  <img src="screenshots/upload.png" alt="Upload Page" width="45%">
  <img src="screenshots/results.png" alt="Results Page" width="45%">
  <img src="screenshots/report.png" alt="PDF Report" width="45%">
</div>

## 🧪 Testing

### Frontend Tests

```bash
cd frontend
npm test
```

### Backend Tests

```bash
cd backend
python -m pytest test_api.py
python comprehensive_test.py
```

## 📝 API Documentation

### POST /predict

Upload chest X-ray for pneumonia detection

**Request:**

```javascript
FormData: {
  "file": <image_file>
}
```

**Response:**

```json
{
  "prediction": "PNEUMONIA",
  "confidence": 0.89,
  "gradcam_image": "base64_encoded_heatmap",
  "processing_time": 1.36
}
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## ⚠️ Medical Disclaimer

**Important:** PneumoNet is designed for educational and research purposes only. This tool is **NOT** intended for clinical diagnosis or to replace professional medical judgment. Always consult qualified healthcare professionals for medical decisions.

## 🙏 Acknowledgments

- **Dataset**: NIH Chest X-ray Dataset
- **Models**: TensorFlow and PyTorch communities
- **UI Inspiration**: Modern medical interfaces
- **Icons**: Lucide React icon library

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/pneumonet/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/pneumonet/wiki)
- **Email**: your.email@domain.com

---

<div align="center">
  Made with ❤️ for better healthcare through AI
  
  **[Live Demo](https://pneumonet.vercel.app)** | **[Documentation](https://github.com/yourusername/pneumonet/wiki)**
</div>
