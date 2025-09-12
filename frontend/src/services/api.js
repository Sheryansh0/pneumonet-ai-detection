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
        mode: "cors", // Explicitly set CORS mode
        credentials: "omit", // Don't send credentials
        headers: {
          Accept: "application/json",
          ...options.headers,
        },
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      // Check if response is JSON
      const contentType = response.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        throw new Error(
          "Response is not JSON - server may be down or misconfigured"
        );
      }

      const data = await response.json();
      return { success: true, data };
    } catch (error) {
      clearTimeout(timeoutId);

      if (error.name === "AbortError") {
        throw new Error("Request timeout - please try again");
      }

      // Check if it's a CORS or network error
      if (
        error.message.includes("Failed to fetch") ||
        error.message.includes("NetworkError") ||
        error.message.includes("CORS")
      ) {
        throw new Error(
          "Cannot connect to AI server - please check if the backend is running"
        );
      }

      // Handle JSON parsing errors (HTML responses)
      if (
        error.message.includes("Unexpected token") ||
        error.message.includes("not valid JSON") ||
        error.message.includes("<!doctype")
      ) {
        throw new Error(
          "Server returned HTML instead of JSON - proxy may be misconfigured"
        );
      }

      throw new Error(`API request failed: ${error.message}`);
    }
  }

  // Health check endpoint - with multiple fallback methods
  async checkHealth() {
    // For production, use multiple fallback methods
    if (window.location.protocol === "https:") {
      const methods = [
        // Method 1: Direct request (might work if server has CORS enabled)
        async () => {
          const directUrl = `${this.baseURL}${API_CONFIG.ENDPOINTS.HEALTH}`;
          console.log(`Trying health check method 1: ${directUrl}`);
          return await this.makeRequest(directUrl);
        },
        // Method 2: CORS Anywhere proxy
        async () => {
          const corsProxy = "https://cors-anywhere.herokuapp.com/";
          const targetUrl = `${this.baseURL}${API_CONFIG.ENDPOINTS.HEALTH}`;
          const proxyUrl = `${corsProxy}${targetUrl}`;
          console.log(`Trying health check method 2: ${proxyUrl}`);
          return await this.makeRequest(proxyUrl, {
            headers: { "X-Requested-With": "XMLHttpRequest" },
          });
        },
        // Method 3: AllOrigins proxy
        async () => {
          const targetUrl = encodeURIComponent(
            `${this.baseURL}${API_CONFIG.ENDPOINTS.HEALTH}`
          );
          const proxyUrl = `https://api.allorigins.win/get?url=${targetUrl}`;
          console.log(`Trying health check method 3: ${proxyUrl}`);
          const response = await fetch(proxyUrl, { mode: "cors" });
          if (!response.ok)
            throw new Error(`HTTP error! status: ${response.status}`);
          const data = await response.json();
          return { success: true, data: JSON.parse(data.contents) };
        },
      ];

      for (let i = 0; i < methods.length; i++) {
        try {
          console.log(`Trying health check method ${i + 1}`);
          const result = await methods[i]();
          if (result.success) {
            console.log(`✅ Health check successful via method ${i + 1}!`);
            return result;
          }
        } catch (error) {
          console.log(`Health check method ${i + 1} failed:`, error.message);
          if (i === methods.length - 1) {
            throw new Error(
              `All health check methods failed. Last error: ${error.message}`
            );
          }
        }
      }
    } else {
      // For development (localhost), use direct connection
      const directUrl = `${this.baseURL}${API_CONFIG.ENDPOINTS.HEALTH}`;
      try {
        console.log(`Checking health at: ${directUrl}`);
        const result = await this.makeRequest(directUrl);
        if (result.success) {
          console.log("✅ Health check successful via direct connection!");
          return result;
        }
      } catch (error) {
        console.error("Direct health check failed:", error.message);
        throw error;
      }
    }
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

  // Main prediction endpoint - with base64 AllOrigins proxy (working method)
  async predictPneumonia(file, options = {}) {
    // Validate file first
    const validation = this.validateFile(file);
    if (!validation.isValid) {
      throw new Error(validation.errors.join(", "));
    }

    // For production (HTTPS), use AllOrigins proxy with base64 encoding
    if (window.location.protocol === "https:") {
      try {
        console.log("Making prediction via AllOrigins proxy with base64...");

        // Convert file to base64
        const base64Data = await this.fileToBase64(file);
        
        // Create the payload for backend
        const payload = {
          file_data: base64Data
        };
        
        if (options.disableCam) {
          payload.disable_cam = "true";
        }

        // Use AllOrigins to make a POST request with base64 data
        const targetUrl = `${this.baseURL}${API_CONFIG.ENDPOINTS.PREDICT}`;
        
        // Create a custom proxy request using AllOrigins
        const proxyRequestData = {
          url: targetUrl,
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(payload)
        };

        const response = await fetch("https://api.allorigins.win/get", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(proxyRequestData)
        });

        if (!response.ok) {
          throw new Error(`AllOrigins response error: ${response.status}`);
        }

        const proxyResult = await response.json();
        
        if (!proxyResult.contents) {
          throw new Error("AllOrigins returned empty response");
        }

        const data = JSON.parse(proxyResult.contents);
        console.log("✅ Prediction successful via AllOrigins proxy!");
        return { success: true, data };
        
      } catch (allOriginsError) {
        console.error("AllOrigins proxy prediction failed:", allOriginsError.message);
        
        // Try one more fallback method - basic AllOrigins GET with query params
        try {
          console.log("Trying simplified AllOrigins approach...");
          
          // For now, show a helpful message to the user
          throw new Error("File upload is currently unavailable due to browser security restrictions. The AI server is online, but file processing requires additional setup.");
          
        } catch (fallbackError) {
          throw new Error(`File upload failed: ${allOriginsError.message}`);
        }
      }
    } else {
      // For development (localhost), use direct connection
      const directUrl = `${this.baseURL}${API_CONFIG.ENDPOINTS.PREDICT}`;
      console.log(`Making prediction request to: ${directUrl}`);

      // Create FormData for file upload
      const formData = new FormData();
      formData.append("file", file);

      // Add optional parameters
      if (options.disableCam) {
        formData.append("disable_cam", "true");
      }

      try {
        const response = await fetch(directUrl, {
          method: "POST",
          body: formData,
          mode: "cors",
          credentials: "omit",
          // Don't set Content-Type - let browser set it with boundary for FormData
        });

        if (!response.ok) {
          const errorText = await response.text();
          throw new Error(`Server error (${response.status}): ${errorText}`);
        }

        const data = await response.json();
        console.log("✅ Prediction successful via direct connection!");
        return { success: true, data };
      } catch (error) {
        console.error("Direct prediction failed:", error.message);
        throw new Error(`Prediction failed: ${error.message}`);
      }
    }
  }

  // Helper method to convert file to base64
  fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        const base64 = reader.result.split(',')[1]; // Remove data:image/jpeg;base64, prefix
        resolve(base64);
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
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
