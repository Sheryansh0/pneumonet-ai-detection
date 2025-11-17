// API Configuration
const API_CONFIG = {
  // Base URL - Use Vercel proxy in production to avoid mixed content issues
  // Local development now uses Cloud Run backend
  BASE_URL:
    process.env.NODE_ENV === "production"
      ? "" // Use relative URLs for Vercel proxy
      : process.env.REACT_APP_API_URL ||
        "https://pneumonet-api-926412293290.us-central1.run.app",

  // API Endpoints - will be proxied through Vercel in production
  ENDPOINTS: {
    HEALTH: process.env.NODE_ENV === "production" ? "/api/health" : "/health",
    HOME: process.env.NODE_ENV === "production" ? "/api/" : "/",
    PREDICT:
      process.env.NODE_ENV === "production" ? "/api/predict" : "/predict",
  },

  // Request timeout (in milliseconds)
  TIMEOUT: 120000, // 2 minutes for prediction requests

  // Supported file types
  SUPPORTED_FILE_TYPES: ["image/jpeg", "image/jpg", "image/png"],

  // Max file size (in bytes) - 10MB
  MAX_FILE_SIZE: 10 * 1024 * 1024,
};

export default API_CONFIG;
