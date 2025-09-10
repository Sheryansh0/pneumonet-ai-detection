import pneumoniaAPI from "../src/services/api.js";

// Test the API connection
async function testConnection() {
  console.log("🧪 Testing Frontend → Azure Backend Connection");
  console.log("=" * 50);

  try {
    // Test health endpoint
    console.log("Testing health endpoint...");
    const healthResult = await pneumoniaAPI.checkHealth();
    console.log("✅ Health Check:", healthResult);

    // Test API info endpoint
    console.log("\nTesting API info endpoint...");
    const apiInfo = await pneumoniaAPI.getApiInfo();
    console.log("✅ API Info:", apiInfo);

    console.log("\n🎉 Frontend successfully connected to Azure backend!");
    console.log("You can now:");
    console.log("1. Visit http://localhost:3000 to use the frontend");
    console.log("2. Upload chest X-ray images for real AI analysis");
    console.log("3. Get predictions from your Azure Container Instance");
  } catch (error) {
    console.error("❌ Connection test failed:", error.message);
    console.log("\nTroubleshooting:");
    console.log("1. Check if Azure Container Instance is running");
    console.log("2. Verify the URL in src/config/api.js");
    console.log("3. Check CORS settings on the backend");
  }
}

// Run the test
testConnection();
