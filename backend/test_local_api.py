import requests
import base64
from PIL import Image
import io
import time
import sys
import os

# Test against local Flask app
LOCAL_API_URL = "http://localhost:5000"

# The path to the image you want to test
IMAGE_PATH = "archive/chest_xray/test/BACTERIAL PNEUMONIA/person100_bacteria_475.jpeg"

def test_health_endpoint():
    """Test the health endpoint"""
    try:
        print("Testing health endpoint...")
        response = requests.get(f"{LOCAL_API_URL}/health", timeout=10)
        print(f"Health Status Code: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Health Response: {result}")
            return True
        else:
            print(f"Health check failed with status: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"Health check error: {e}")
        return False

def test_home_endpoint():
    """Test the home endpoint"""
    try:
        print("\nTesting home endpoint...")
        response = requests.get(f"{LOCAL_API_URL}/", timeout=10)
        print(f"Home Status Code: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Home Response: {result}")
            return True
        else:
            print(f"Home endpoint failed with status: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"Home endpoint error: {e}")
        return False

def test_prediction_endpoint():
    """Test the prediction endpoint with an image"""
    try:
        if not os.path.exists(IMAGE_PATH):
            print(f"Error: Test image not found at '{IMAGE_PATH}'")
            return False
            
        # Prepare the image file to be sent with proper file handling
        with open(IMAGE_PATH, 'rb') as f:
            files = {'file': (IMAGE_PATH, f, 'image/jpeg')}
            
            # Send the POST request with timeout
            print(f"\nTesting prediction endpoint...")
            print(f"Sending request to {LOCAL_API_URL}/predict with image {IMAGE_PATH}...")
            response = requests.post(f"{LOCAL_API_URL}/predict", files=files, timeout=300)
            
        print(f"Prediction Status Code: {response.status_code}")
        
        if response.status_code == 200:
            # Print the JSON response from the server
            result = response.json()
            print("\n--- API Response ---")
            print(f"Prediction: {result.get('prediction')}")
            print(f"Confidence: {result.get('confidence')}")
            print(f"Risk Level: {result.get('risk_level')}")

            # To display the heatmap image (optional)
            if result.get('gradcam_image'):
                print("\nReceived GradCam image. Saving it as a file...")
                img_data = base64.b64decode(result['gradcam_image'])
                with open("api_response_gradcam.png", "wb") as fh:
                    fh.write(img_data)
                print("GradCam saved as api_response_gradcam.png")
            else:
                print("No GradCam image received")
            return True
        else:
            print(f"Prediction failed with status: {response.status_code}")
            try:
                error_response = response.json()
                print(f"Error response: {error_response}")
            except:
                print(f"Error response (text): {response.text}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"Prediction endpoint error: {e}")
        return False
    except FileNotFoundError:
        print(f"Error: The test image was not found at '{IMAGE_PATH}'")
        return False

def wait_for_server(max_retries=30, delay=2):
    """Wait for the Flask server to start"""
    print(f"Waiting for server to start at {LOCAL_API_URL}...")
    for i in range(max_retries):
        try:
            response = requests.get(f"{LOCAL_API_URL}/health", timeout=5)
            if response.status_code == 200:
                print("Server is ready!")
                return True
        except requests.exceptions.RequestException:
            pass
        
        print(f"Waiting... ({i+1}/{max_retries})")
        time.sleep(delay)
    
    print("Server failed to start or is not responding")
    return False

def main():
    """Run all tests"""
    print("=== Local Backend API Test ===")
    
    # Wait for server to be ready
    if not wait_for_server():
        print("Cannot connect to server. Make sure Flask app is running on localhost:5000")
        sys.exit(1)
    
    # Run tests
    tests_passed = 0
    total_tests = 3
    
    if test_health_endpoint():
        tests_passed += 1
    
    if test_home_endpoint():
        tests_passed += 1
        
    if test_prediction_endpoint():
        tests_passed += 1
    
    print(f"\n=== Test Results ===")
    print(f"Tests passed: {tests_passed}/{total_tests}")
    
    if tests_passed == total_tests:
        print("All tests passed! ✅")
        sys.exit(0)
    else:
        print("Some tests failed! ❌")
        sys.exit(1)

if __name__ == "__main__":
    main()
