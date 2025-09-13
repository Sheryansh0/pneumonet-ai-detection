#!/usr/bin/env python3
"""
Comprehensive API Test Suite for Pneumonia Detection Backend
Tests all endpoints with various scenarios including error cases
"""

import requests
import json
import base64
import os
import time
from PIL import Image
import io

# Configuration
API_BASE_URL = "http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000"  # Change this to your deployed URL if needed
TEST_IMAGE_PATH = None  # Will be set dynamically

class Colors:
    """ANSI color codes for colored output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_test_header(test_name):
    """Print a formatted test header"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}{'=' * 60}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{test_name.center(60)}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{'=' * 60}{Colors.END}")

def print_success(message):
    """Print success message in green"""
    print(f"{Colors.GREEN}✅ {message}{Colors.END}")

def print_error(message):
    """Print error message in red"""
    print(f"{Colors.RED}❌ {message}{Colors.END}")

def print_warning(message):
    """Print warning message in yellow"""
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.END}")

def print_info(message):
    """Print info message in cyan"""
    print(f"{Colors.CYAN}ℹ️  {message}{Colors.END}")

def create_test_image():
    """Create a simple test image for API testing"""
    # Create a simple 224x224 RGB image
    img = Image.new('RGB', (224, 224), color='gray')
    
    # Save to bytes
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    img_bytes.seek(0)
    
    return img_bytes.getvalue()

def test_health_endpoint():
    """Test the /health endpoint"""
    print_test_header("TESTING HEALTH ENDPOINT")
    
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"Health endpoint responded with status 200")
            print_info(f"Response: {json.dumps(data, indent=2)}")
            
            if data.get('status') == 'ok':
                print_success("API is healthy and models are loaded")
                return True
            elif data.get('status') == 'loading':
                print_warning("API is still loading models")
                return False
            else:
                print_error(f"Unexpected health status: {data.get('status')}")
                return False
        else:
            print_error(f"Health endpoint returned status {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Failed to connect to health endpoint: {e}")
        return False

def test_home_endpoint():
    """Test the / (home) endpoint"""
    print_test_header("TESTING HOME ENDPOINT")
    
    try:
        response = requests.get(f"{API_BASE_URL}/", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print_success("Home endpoint responded with status 200")
            print_info(f"Response: {json.dumps(data, indent=2)}")
            
            expected_fields = ['message', 'status', 'endpoints']
            for field in expected_fields:
                if field in data:
                    print_success(f"✓ Field '{field}' present")
                else:
                    print_error(f"✗ Field '{field}' missing")
            
            return True
        else:
            print_error(f"Home endpoint returned status {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Failed to connect to home endpoint: {e}")
        return False

def test_predict_endpoint_file_upload():
    """Test the /predict endpoint with file upload"""
    print_test_header("TESTING PREDICT ENDPOINT - FILE UPLOAD")
    
    try:
        # Create test image
        test_image_bytes = create_test_image()
        
        # Prepare file upload
        files = {'file': ('test_image.jpg', test_image_bytes, 'image/jpeg')}
        data = {'disable_cam': 'false'}
        
        print_info("Sending POST request with file upload...")
        response = requests.post(f"{API_BASE_URL}/predict", files=files, data=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            print_success("Predict endpoint responded with status 200")
            print_info(f"Response: {json.dumps(result, indent=2)}")
            
            # Check expected fields
            expected_fields = ['prediction', 'confidence', 'risk_level', 'gradcam_image']
            for field in expected_fields:
                if field in result:
                    print_success(f"✓ Field '{field}' present: {result[field] if field != 'gradcam_image' else 'Base64 data present' if result[field] else 'None'}")
                else:
                    print_error(f"✗ Field '{field}' missing")
            
            return True
        else:
            print_error(f"Predict endpoint returned status {response.status_code}")
            print_error(f"Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Failed to connect to predict endpoint: {e}")
        return False

def test_predict_endpoint_base64():
    """Test the /predict endpoint with base64 JSON data"""
    print_test_header("TESTING PREDICT ENDPOINT - BASE64 JSON")
    
    try:
        # Create test image and encode to base64
        test_image_bytes = create_test_image()
        base64_data = base64.b64encode(test_image_bytes).decode('utf-8')
        
        # Prepare JSON payload
        payload = {
            'file_data': base64_data,
            'disable_cam': 'false'
        }
        
        headers = {'Content-Type': 'application/json'}
        
        print_info("Sending POST request with base64 JSON data...")
        response = requests.post(f"{API_BASE_URL}/predict", json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            print_success("Predict endpoint (base64) responded with status 200")
            print_info(f"Response: {json.dumps(result, indent=2)}")
            
            # Check expected fields
            expected_fields = ['prediction', 'confidence', 'risk_level', 'gradcam_image']
            for field in expected_fields:
                if field in result:
                    print_success(f"✓ Field '{field}' present: {result[field] if field != 'gradcam_image' else 'Base64 data present' if result[field] else 'None'}")
                else:
                    print_error(f"✗ Field '{field}' missing")
            
            return True
        else:
            print_error(f"Predict endpoint (base64) returned status {response.status_code}")
            print_error(f"Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Failed to connect to predict endpoint (base64): {e}")
        return False

def test_predict_endpoint_with_cam_disabled():
    """Test the /predict endpoint with Grad-CAM disabled"""
    print_test_header("TESTING PREDICT ENDPOINT - CAM DISABLED")
    
    try:
        # Create test image and encode to base64
        test_image_bytes = create_test_image()
        base64_data = base64.b64encode(test_image_bytes).decode('utf-8')
        
        # Prepare JSON payload with CAM disabled
        payload = {
            'file_data': base64_data,
            'disable_cam': 'true'
        }
        
        headers = {'Content-Type': 'application/json'}
        
        print_info("Sending POST request with CAM disabled...")
        response = requests.post(f"{API_BASE_URL}/predict", json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            print_success("Predict endpoint (CAM disabled) responded with status 200")
            print_info(f"Response: {json.dumps(result, indent=2)}")
            
            # Check that gradcam_image is None
            if result.get('gradcam_image') is None:
                print_success("✓ Grad-CAM correctly disabled")
            else:
                print_warning("⚠️ Grad-CAM image present despite being disabled")
            
            return True
        else:
            print_error(f"Predict endpoint (CAM disabled) returned status {response.status_code}")
            print_error(f"Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Failed to connect to predict endpoint (CAM disabled): {e}")
        return False

def test_error_cases():
    """Test various error scenarios"""
    print_test_header("TESTING ERROR CASES")
    
    # Test 1: Empty file upload
    print_info("Testing empty file upload...")
    try:
        response = requests.post(f"{API_BASE_URL}/predict", files={}, timeout=10)
        if response.status_code == 400:
            print_success("✓ Empty file upload correctly rejected with 400")
        else:
            print_warning(f"Expected 400, got {response.status_code}")
    except Exception as e:
        print_error(f"Error testing empty file: {e}")
    
    # Test 2: Invalid base64 data
    print_info("Testing invalid base64 data...")
    try:
        payload = {'file_data': 'invalid_base64_data'}
        response = requests.post(f"{API_BASE_URL}/predict", json=payload, timeout=10)
        if response.status_code == 400:
            print_success("✓ Invalid base64 data correctly rejected with 400")
        else:
            print_warning(f"Expected 400, got {response.status_code}")
    except Exception as e:
        print_error(f"Error testing invalid base64: {e}")
    
    # Test 3: Missing file_data in JSON
    print_info("Testing missing file_data in JSON...")
    try:
        payload = {'other_field': 'value'}
        response = requests.post(f"{API_BASE_URL}/predict", json=payload, timeout=10)
        if response.status_code == 400:
            print_success("✓ Missing file_data correctly rejected with 400")
        else:
            print_warning(f"Expected 400, got {response.status_code}")
    except Exception as e:
        print_error(f"Error testing missing file_data: {e}")

def test_cors():
    """Test CORS headers"""
    print_test_header("TESTING CORS HEADERS")
    
    try:
        # Test preflight request
        headers = {
            'Origin': 'https://example.com',
            'Access-Control-Request-Method': 'POST',
            'Access-Control-Request-Headers': 'Content-Type'
        }
        
        response = requests.options(f"{API_BASE_URL}/predict", headers=headers, timeout=10)
        
        print_info(f"OPTIONS request status: {response.status_code}")
        print_info(f"Response headers: {dict(response.headers)}")
        
        cors_headers = [
            'Access-Control-Allow-Origin',
            'Access-Control-Allow-Methods',
            'Access-Control-Allow-Headers'
        ]
        
        for header in cors_headers:
            if header in response.headers:
                print_success(f"✓ CORS header '{header}' present")
            else:
                print_warning(f"⚠️ CORS header '{header}' missing")
        
        return True
        
    except Exception as e:
        print_error(f"Error testing CORS: {e}")
        return False

def run_performance_test():
    """Run a simple performance test"""
    print_test_header("PERFORMANCE TEST")
    
    try:
        test_image_bytes = create_test_image()
        base64_data = base64.b64encode(test_image_bytes).decode('utf-8')
        
        payload = {
            'file_data': base64_data,
            'disable_cam': 'true'  # Disable CAM for faster response
        }
        
        num_requests = 5
        response_times = []
        
        print_info(f"Sending {num_requests} requests to measure response time...")
        
        for i in range(num_requests):
            start_time = time.time()
            response = requests.post(f"{API_BASE_URL}/predict", json=payload, timeout=30)
            end_time = time.time()
            
            if response.status_code == 200:
                response_time = end_time - start_time
                response_times.append(response_time)
                print_info(f"Request {i+1}: {response_time:.2f}s")
            else:
                print_error(f"Request {i+1} failed with status {response.status_code}")
        
        if response_times:
            avg_time = sum(response_times) / len(response_times)
            min_time = min(response_times)
            max_time = max(response_times)
            
            print_success(f"Performance Results:")
            print_info(f"  Average response time: {avg_time:.2f}s")
            print_info(f"  Minimum response time: {min_time:.2f}s")
            print_info(f"  Maximum response time: {max_time:.2f}s")
            
            if avg_time < 5.0:
                print_success("✓ Good performance (< 5s average)")
            elif avg_time < 10.0:
                print_warning("⚠️ Moderate performance (5-10s average)")
            else:
                print_warning("⚠️ Slow performance (> 10s average)")
        
        return True
        
    except Exception as e:
        print_error(f"Error in performance test: {e}")
        return False

def main():
    """Run all tests"""
    print(f"{Colors.PURPLE}{Colors.BOLD}")
    print("██████╗ ███╗   ██╗███████╗██╗   ██╗███╗   ███╗ ██████╗ ███╗   ██╗██╗ █████╗")
    print("██╔══██╗████╗  ██║██╔════╝██║   ██║████╗ ████║██╔═══██╗████╗  ██║██║██╔══██╗")
    print("██████╔╝██╔██╗ ██║█████╗  ██║   ██║██╔████╔██║██║   ██║██╔██╗ ██║██║███████║")
    print("██╔═══╝ ██║╚██╗██║██╔══╝  ██║   ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║██╔══██║")
    print("██║     ██║ ╚████║███████╗╚██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║██║  ██║")
    print("╚═╝     ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝")
    print(f"{Colors.END}")
    print(f"{Colors.CYAN}API Test Suite - Pneumonia Detection Backend{Colors.END}")
    print(f"{Colors.WHITE}Testing API at: {API_BASE_URL}{Colors.END}\n")
    
    # Test results tracking
    tests = []
    
    # Run all tests
    tests.append(("Health Endpoint", test_health_endpoint()))
    tests.append(("Home Endpoint", test_home_endpoint()))
    tests.append(("Predict - File Upload", test_predict_endpoint_file_upload()))
    tests.append(("Predict - Base64 JSON", test_predict_endpoint_base64()))
    tests.append(("Predict - CAM Disabled", test_predict_endpoint_with_cam_disabled()))
    tests.append(("Error Cases", test_error_cases()))
    tests.append(("CORS Headers", test_cors()))
    tests.append(("Performance Test", run_performance_test()))
    
    # Print summary
    print_test_header("TEST SUMMARY")
    
    passed = sum(1 for _, result in tests if result)
    total = len(tests)
    
    for test_name, result in tests:
        if result:
            print_success(f"{test_name}: PASSED")
        else:
            print_error(f"{test_name}: FAILED")
    
    print(f"\n{Colors.BOLD}Results: {passed}/{total} tests passed{Colors.END}")
    
    if passed == total:
        print_success("🎉 All tests passed! Your API is working perfectly.")
    elif passed >= total * 0.8:
        print_warning(f"⚠️ Most tests passed. {total - passed} test(s) failed.")
    else:
        print_error(f"❌ Multiple tests failed. Please check your API implementation.")
    
    return passed == total

if __name__ == "__main__":
    # Allow custom API URL via environment variable
    if os.getenv("API_URL"):
        API_BASE_URL = os.getenv("API_URL")
    
    print(f"Testing API at: {API_BASE_URL}")
    success = main()
    exit(0 if success else 1)