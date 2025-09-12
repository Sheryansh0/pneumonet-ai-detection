// Prediction proxy for Azure backend
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

  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed - use POST" });
    return;
  }

  console.log("Predict endpoint called:", req.method, req.url);

  try {
    const backendUrl =
      "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000/predict";

    console.log("Forwarding to:", backendUrl);

    // Forward the request to Azure backend
    const response = await fetch(backendUrl, {
      method: "POST",
      body: req.body,
      headers: {
        // Forward most headers but be careful with CORS
        "Content-Type": req.headers["content-type"] || "multipart/form-data",
      },
      signal: AbortSignal.timeout(30000), // 30 second timeout for predictions
    });

    console.log("Backend prediction response status:", response.status);

    if (!response.ok) {
      return res.status(response.status).json({
        error: `Backend returned ${response.status}`,
        message: "Prediction request failed",
        backend_url: backendUrl,
      });
    }

    const data = await response.json();
    console.log("Prediction successful");
    res.status(200).json({
      ...data,
      proxy_status: "success",
    });
  } catch (error) {
    console.error("Prediction failed:", error.message);
    res.status(500).json({
      error: "Prediction failed",
      message: error.message,
      backend_url:
        "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000/predict",
    });
  }
}
