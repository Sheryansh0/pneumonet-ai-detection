// Health check proxy for Azure backend
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

  console.log("Health endpoint called:", req.method, req.url);

  try {
    const backendUrl =
      "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000/health";
    console.log("Attempting to connect to:", backendUrl);

    const response = await fetch(backendUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      signal: AbortSignal.timeout(10000), // 10 second timeout
    });

    console.log("Backend response status:", response.status);

    if (!response.ok) {
      return res.status(response.status).json({
        status: "error",
        error: `Backend returned ${response.status}`,
        backend_url: backendUrl,
      });
    }

    const data = await response.json();

    console.log("Backend response data:", data);
    res.status(200).json({
      ...data,
      proxy_status: "success",
      backend_url: backendUrl,
      node_version: process.version,
    });
  } catch (error) {
    console.error("Health check failed:", error.message);
    res.status(503).json({
      status: "error",
      error: "Backend unavailable",
      message: error.message,
      backend_url:
        "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000/health",
      node_version: process.version,
    });
  }
}
