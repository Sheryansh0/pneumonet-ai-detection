import requests
import base64
from PIL import Image
import io
import os

# The URL where your Flask app is running (Azure Container Instance)
API_URL = "http://pneumonia-detection-sheryansh.hah5ghbxfdeabpcw.centralindia.azurecontainer.io:5000/predict"

# The path to the image you want to test (using relative path)
IMAGE_PATH = "archive/chest_xray/test/BACTERIAL PNEUMONIA/person100_bacteria_475.jpeg"

try:
    # Check if the image file exists first
    if not os.path.exists(IMAGE_PATH):
        print(f"Error: Test image not found at '{IMAGE_PATH}'")
        exit(1)
        
    # Prepare the image file to be sent with proper file handling
    with open(IMAGE_PATH, 'rb') as f:
        files = {'file': (IMAGE_PATH, f, 'image/jpeg')}
        
        # Send the POST request with timeout
        print(f"Sending request to {API_URL} with image {IMAGE_PATH}...")
        response = requests.post(API_URL, files=files, timeout=300)
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)

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
        with open("api_response_gradcam_remote.png", "wb") as fh:
            fh.write(img_data)
        print("GradCam saved as api_response_gradcam_remote.png")
    else:
        print("No GradCam image received")

except requests.exceptions.RequestException as e:
    print(f"\nAn error occurred: {e}")
except FileNotFoundError:
    print(f"\nError: The test image was not found at '{IMAGE_PATH}'")
