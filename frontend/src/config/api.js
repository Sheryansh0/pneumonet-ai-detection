// API Configuration
const API_CONFIG = {
  // Base URL - HTTPS Azure Container Apps endpoint (resolves Mixed Content Policy)
  BASE_URL:
    process.env.REACT_APP_API_URL ||
    "https://pneumonia-detection-app.agreeablegrass-90b85d63.centralindia.azurecontainerapps.io",

  // API Endpoints
  ENDPOINTS: {
    HEALTH: "/health",
    HOME: "/",
    PREDICT: "/predict",
  },

  // Request timeout (in milliseconds)
  TIMEOUT: 120000, // 2 minutes for prediction requests

  // Supported file types
  SUPPORTED_FILE_TYPES: ["image/jpeg", "image/jpg", "image/png"],

  // Max file size (in bytes) - 10MB
  MAX_FILE_SIZE: 10 * 1024 * 1024,
};

export default API_CONFIG;
