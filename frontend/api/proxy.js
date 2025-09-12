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
    const { url } = req.query;

    if (!url) {
      return res.status(400).json({ error: "URL parameter is required" });
    }

    // Validate that we're only proxying to our Container Instance
    const allowedDomain =
      "pneumonia-detection-sheryansh.centralindia.azurecontainer.io";
    if (!url.includes(allowedDomain)) {
      return res.status(403).json({ error: "Unauthorized domain" });
    }

    console.log(`Proxying request to: ${url}`);

    // Make request to the HTTP backend
    const response = await fetch(url, {
      method: req.method,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
    });

    if (!response.ok) {
      throw new Error(`Backend responded with status: ${response.status}`);
    }

    const data = await response.json();

    // Return the data
    res.status(200).json(data);
  } catch (error) {
    console.error("Proxy error:", error);
    res.status(500).json({
      error: "Proxy error",
      message: error.message,
      details: "Unable to connect to backend server",
    });
  }
}
