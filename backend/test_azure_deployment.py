import requests
import json
import time
import os

def load_deployment_info():
    """Load deployment information from JSON file"""
    try:
        # Try simplified file first
        if os.path.exists('azure-deployment-simple.json'):
            with open('azure-deployment-simple.json', 'r') as f:
                return json.load(f)
        elif os.path.exists('azure-deployment-info.json'):
            with open('azure-deployment-info.json', 'r') as f:
                return json.load(f)
        else:
            print("❌ No deployment info file found. Please run the deployment script first.")
            return None
    except json.JSONDecodeError:
        print("❌ Error reading deployment info file.")
        return None

def test_azure_health(api_url, max_retries=30):
    """Test the health endpoint with retries"""
    print(f"🏥 Testing health endpoint: {api_url}/health")
    
    for i in range(max_retries):
        try:
            response = requests.get(f"{api_url}/health", timeout=30)
            print(f"Attempt {i+1}: Status Code {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                status = result.get('status', 'unknown')
                print(f"✅ Health check response! Status: {status}")
                
                # Accept both 'ok' and 'loading' as valid statuses
                if status in ['ok', 'loading']:
                    return True
                else:
                    print(f"⚠️ Unexpected status: {status}")
            else:
                print(f"⚠️ Health check returned status code: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"Attempt {i+1} failed: {e}")
        
        if i < max_retries - 1:
            print("Waiting 30 seconds before next attempt...")
            time.sleep(30)
    
    print(f"❌ Health check failed after {max_retries} attempts")
    return False

def test_azure_prediction(api_url):
    """Test the prediction endpoint"""
    image_path = "archive/chest_xray/test/BACTERIAL PNEUMONIA/person100_bacteria_475.jpeg"
    
    if not os.path.exists(image_path):
        print(f"❌ Test image not found: {image_path}")
        return False
    
    try:
        print(f"🧠 Testing prediction endpoint: {api_url}/predict")
        print(f"Using test image: {image_path}")
        
        with open(image_path, 'rb') as f:
            files = {'file': (image_path, f, 'image/jpeg')}
            
            response = requests.post(f"{api_url}/predict", files=files, timeout=120)
            
        if response.status_code == 200:
            result = response.json()
            print("✅ Prediction test passed!")
            print(f"  Prediction: {result.get('prediction')}")
            print(f"  Confidence: {result.get('confidence')}")
            print(f"  Risk Level: {result.get('risk_level')}")
            
            # Save prediction result
            with open('azure-prediction-test-result.json', 'w') as f:
                json.dump({
                    'test_time': time.strftime('%Y-%m-%d %H:%M:%S'),
                    'api_url': api_url,
                    'prediction_result': result,
                    'test_image': image_path
                }, f, indent=2)
            
            return True
        else:
            print(f"❌ Prediction failed with status code: {response.status_code}")
            try:
                error_result = response.json()
                print(f"Error: {error_result}")
            except:
                print(f"Error response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Prediction test failed: {e}")
        return False

def test_azure_home(api_url):
    """Test the home endpoint"""
    try:
        print(f"🏠 Testing home endpoint: {api_url}/")
        response = requests.get(f"{api_url}/", timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Home endpoint test passed!")
            print(f"  Message: {result.get('message')}")
            print(f"  Status: {result.get('status')}")
            return True
        else:
            print(f"❌ Home endpoint failed with status code: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Home endpoint test failed: {e}")
        return False

def main():
    """Main testing function"""
    print("🧪 Azure Container Instance API Test")
    print("=" * 40)
    
    # Load deployment info
    deployment_info = load_deployment_info()
    if not deployment_info:
        return
    
    api_url = deployment_info.get('api_url')
    if not api_url:
        print("❌ API URL not found in deployment info")
        return
    
    print(f"Testing Azure deployment:")
    print(f"  Container: {deployment_info.get('container_name')}")
    print(f"  Resource Group: {deployment_info.get('resource_group')}")
    print(f"  FQDN: {deployment_info.get('fqdn')}")
    print(f"  API URL: {api_url}")
    print()
    
    # Run tests
    tests_passed = 0
    total_tests = 3
    
    # Test health endpoint (this might take a while for the container to start)
    if test_azure_health(api_url):
        tests_passed += 1
        
        # Only test other endpoints if health check passes
        if test_azure_home(api_url):
            tests_passed += 1
            
        if test_azure_prediction(api_url):
            tests_passed += 1
    else:
        print("Skipping other tests since health check failed")
    
    print(f"\n📊 Test Results: {tests_passed}/{total_tests} tests passed")
    
    if tests_passed == total_tests:
        print("🎉 All tests passed! Your Azure deployment is working perfectly!")
    elif tests_passed > 0:
        print("⚠️ Some tests passed. The deployment might need more time to fully start.")
    else:
        print("❌ All tests failed. Check the Azure container logs for issues.")
        print(f"You can check logs with: az container logs --resource-group {deployment_info.get('resource_group')} --name {deployment_info.get('container_name')}")

if __name__ == "__main__":
    main()
