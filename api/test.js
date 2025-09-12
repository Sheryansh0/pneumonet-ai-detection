// Simple test endpoint to verify serverless functions are working
export default function handler(req, res) {
  // Enable CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  console.log(
    "Test endpoint called:",
    req.method,
    req.url,
    new Date().toISOString()
  );

  res.status(200).json({
    status: "success",
    message: "Vercel serverless function is working!",
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.url,
    node_version: process.version,
    environment: process.env.NODE_ENV || "unknown",
  });
}
