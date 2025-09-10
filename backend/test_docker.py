import requests
import time

# Test the dockerized application
DOCKER_API_URL = "http://localhost:8080"

def test_docker_health():
    """Test the health endpoint of the dockerized app"""
    max_retries = 30
    for i in range(max_retries):
        try:
            print(f"Attempting to connect... ({i+1}/{max_retries})")
            response = requests.get(f"{DOCKER_API_URL}/health", timeout=10)
            if response.status_code == 200:
                print("✅ Docker container health check passed!")
                print(f"Response: {response.json()}")
                return True
        except requests.exceptions.RequestException as e:
            print(f"Connection attempt {i+1} failed: {e}")
            time.sleep(5)
    
    print("❌ Docker container failed to respond")
    return False

def test_docker_prediction():
    """Test prediction endpoint of the dockerized app"""
    try:
        image_path = "archive/chest_xray/test/BACTERIAL PNEUMONIA/person100_bacteria_475.jpeg"
        
        with open(image_path, 'rb') as f:
            files = {'file': (image_path, f, 'image/jpeg')}
            
            print("Testing prediction endpoint...")
            response = requests.post(f"{DOCKER_API_URL}/predict", files=files, timeout=60)
            
        if response.status_code == 200:
            result = response.json()
            print("✅ Docker prediction test passed!")
            print(f"Prediction: {result.get('prediction')}")
            print(f"Confidence: {result.get('confidence')}")
            print(f"Risk Level: {result.get('risk_level')}")
            return True
        else:
            print(f"❌ Prediction failed with status: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Prediction test failed: {e}")
        return False

if __name__ == "__main__":
    print("🐳 Testing Dockerized Pneumonia Detection API")
    print("=" * 50)
    
    if test_docker_health():
        test_docker_prediction()
    else:
        print("Health check failed, skipping prediction test")
