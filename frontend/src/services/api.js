import API_CONFIG from "../config/api";

class PneumoniaAPI {
  constructor() {
    this.baseURL = API_CONFIG.BASE_URL;
    this.timeout = API_CONFIG.TIMEOUT;
  }

  // Helper method for making HTTP requests
  async makeRequest(url, options = {}) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return { success: true, data };
    } catch (error) {
      clearTimeout(timeoutId);

      if (error.name === "AbortError") {
        throw new Error("Request timeout - please try again");
      }

      throw new Error(`API request failed: ${error.message}`);
    }
  }

  // Health check endpoint
  async checkHealth() {
    const url = `${this.baseURL}${API_CONFIG.ENDPOINTS.HEALTH}`;
    return this.makeRequest(url);
  }

  // Home endpoint (API info)
  async getApiInfo() {
    const url = `${this.baseURL}${API_CONFIG.ENDPOINTS.HOME}`;
    return this.makeRequest(url);
  }

  // Validate file before upload
  validateFile(file) {
    const errors = [];

    if (!file) {
      errors.push("No file selected");
      return { isValid: false, errors };
    }

    // Check file type
    if (!API_CONFIG.SUPPORTED_FILE_TYPES.includes(file.type)) {
      errors.push(
        `Unsupported file type. Please use: ${API_CONFIG.SUPPORTED_FILE_TYPES.join(
          ", "
        )}`
      );
    }

    // Check file size
    if (file.size > API_CONFIG.MAX_FILE_SIZE) {
      const maxSizeMB = API_CONFIG.MAX_FILE_SIZE / (1024 * 1024);
      errors.push(`File too large. Maximum size: ${maxSizeMB}MB`);
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  // Main prediction endpoint
  async predictPneumonia(file, options = {}) {
    // Validate file first
    const validation = this.validateFile(file);
    if (!validation.isValid) {
      throw new Error(validation.errors.join(", "));
    }

    const url = `${this.baseURL}${API_CONFIG.ENDPOINTS.PREDICT}`;

    // Create FormData for file upload
    const formData = new FormData();
    formData.append("file", file);

    // Add optional parameters
    if (options.disableCam) {
      formData.append("disable_cam", "true");
    }

    const requestOptions = {
      method: "POST",
      body: formData,
    };

    return this.makeRequest(url, requestOptions);
  }

  // Convert base64 image to blob for display
  base64ToBlob(base64Data, contentType = "image/png") {
    const byteCharacters = atob(base64Data);
    const byteNumbers = new Array(byteCharacters.length);

    for (let i = 0; i < byteCharacters.length; i++) {
      byteNumbers[i] = byteCharacters.charCodeAt(i);
    }

    const byteArray = new Uint8Array(byteNumbers);
    return new Blob([byteArray], { type: contentType });
  }

  // Create object URL for base64 image
  createImageUrl(base64Data) {
    if (!base64Data) return null;

    try {
      const blob = this.base64ToBlob(base64Data);
      return URL.createObjectURL(blob);
    } catch (error) {
      console.error("Error creating image URL:", error);
      return null;
    }
  }
}

// Create singleton instance
const pneumoniaAPI = new PneumoniaAPI();
export default pneumoniaAPI;
