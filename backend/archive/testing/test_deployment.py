import requests
import time

def test_deployment(base_url):
    """Test the deployed API"""
    print(f"🧪 Testing deployment at: {base_url}")
    
    # Test health endpoint
    try:
        print("📊 Testing health endpoint...")
        response = requests.get(f"{base_url}/health", timeout=30)
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
    except Exception as e:
        print(f"   ❌ Health check failed: {e}")
        return False
    
    # Test home endpoint
    try:
        print("🏠 Testing home endpoint...")
        response = requests.get(f"{base_url}/", timeout=30)
        print(f"   Status: {response.status_code}")
        result = response.json()
        print(f"   Message: {result.get('message')}")
        print(f"   Status: {result.get('status')}")
    except Exception as e:
        print(f"   ❌ Home endpoint failed: {e}")
        return False
    
    print("✅ Deployment test completed successfully!")
    return True

if __name__ == "__main__":
    # Test different deployment URLs
    test_urls = [
        "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000",  # Azure ACI
        "https://your-app-name.railway.app",  # Railway
        "https://your-app-name.onrender.com"  # Render
    ]
    
    print("🚀 Pneumonia Detection API Deployment Tester")
    print("=" * 50)
    
    # You can test with your actual deployment URL
    deployment_url = input("Enter your deployment URL (or press Enter to skip): ").strip()
    
    if deployment_url:
        test_deployment(deployment_url)
    else:
        print("ℹ️  Example URLs to test once deployed:")
        for url in test_urls:
            print(f"   - {url}")
