// Vercel serverless function to proxy requests to Azure backend
export default async function handler(req, res) {
  // Enable CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  const AZURE_BACKEND =
    "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000";

  try {
    // Extract the path from the request
    const { path = "", ...queryParams } = req.query;
    const targetPath = Array.isArray(path) ? path.join("/") : path;

    // Construct the target URL
    const targetUrl = `${AZURE_BACKEND}/${targetPath}`;

    // Prepare request options
    const options = {
      method: req.method,
      headers: {
        "Content-Type": req.headers["content-type"] || "application/json",
      },
    };

    // Add body for POST requests
    if (req.method === "POST" && req.body) {
      if (req.headers["content-type"]?.includes("multipart/form-data")) {
        // For file uploads, we need to handle FormData differently
        options.body = JSON.stringify(req.body);
      } else {
        options.body =
          typeof req.body === "string" ? req.body : JSON.stringify(req.body);
      }
    }

    // Make request to Azure backend
    const response = await fetch(targetUrl, options);
    const data = await response.text();

    // Set response headers
    res.status(response.status);

    // Try to parse as JSON, fallback to text
    try {
      const jsonData = JSON.parse(data);
      res.json(jsonData);
    } catch {
      res.send(data);
    }
  } catch (error) {
    console.error("Proxy error:", error);
    res.status(500).json({
      error: "Proxy error",
      message: error.message,
      details: "Unable to connect to backend server",
    });
  }
}
