# app.py

from flask import Flask, request, jsonify
from flask_cors import CORS
import torch
import torch.nn as nn
from torchvision.models import convnext_tiny, efficientnet_v2_s
from PIL import Image
import base64
import io
import cv2
import numpy as np
from torchvision import transforms
import os
import traceback

# Import our Grad-CAM function
from explain import get_grad_cam
import uuid

# --- 1. Initialize Flask App ---
print("[INFO] Starting Flask server...")
app = Flask(__name__)

# --- 2. Enable CORS for all routes ---
CORS(app, resources={
    r"/*": {
        "origins": ["*"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
print("[INFO] CORS enabled for all routes")

# --- Global variables for the models and other settings ---
MODEL_CONVNEXT = None
MODEL_EFFICIENTNET = None
DEVICE = os.getenv("DEVICE", "cpu")
CLASS_NAMES = ['BACTERIAL_PNEUMONIA', 'NORMAL', 'VIRAL_PNEUMONIA']
CONVNEXT_WEIGHT = 0.4
EFFICIENTNET_WEIGHT = 0.6
DISABLE_CAM = os.getenv("DISABLE_CAM", "0") == "1"

def load_models():
    """Load both trained models from disk (idempotent)."""
    global MODEL_CONVNEXT, MODEL_EFFICIENTNET
    if MODEL_CONVNEXT is not None and MODEL_EFFICIENTNET is not None:
        return
    print("[INFO] Loading models...")
    try:
        # --- Load ConvNeXt-Tiny ---
        MODEL_CONVNEXT = convnext_tiny(weights=None)
        num_ftrs1 = MODEL_CONVNEXT.classifier[2].in_features
        MODEL_CONVNEXT.classifier[2] = nn.Linear(num_ftrs1, len(CLASS_NAMES))
        MODEL_CONVNEXT.load_state_dict(torch.load('convnext_pneumonia.pth', map_location=torch.device('cpu'), weights_only=True))
        MODEL_CONVNEXT = MODEL_CONVNEXT.to(DEVICE)
        MODEL_CONVNEXT.eval()
        print("  - ConvNeXt model loaded.")

        # --- Load EfficientNetV2-S ---
        MODEL_EFFICIENTNET = efficientnet_v2_s(weights=None)
        num_ftrs2 = MODEL_EFFICIENTNET.classifier[1].in_features
        MODEL_EFFICIENTNET.classifier[1] = nn.Linear(num_ftrs2, len(CLASS_NAMES))
        MODEL_EFFICIENTNET.load_state_dict(torch.load('efficientnet_pneumonia.pth', map_location=torch.device('cpu'), weights_only=True))
        MODEL_EFFICIENTNET = MODEL_EFFICIENTNET.to(DEVICE)
        MODEL_EFFICIENTNET.eval()
        print("  - EfficientNetV2 model loaded.")
        print("[INFO] All models loaded successfully.")
    except Exception as e:
        print("[ERROR] Failed to load models:", e)
        traceback.print_exc()
        raise

# --- NEW: Define Risk Level Logic ---
def get_risk_level(predicted_class, confidence_score):
    """Determines a risk level based on the prediction and confidence."""
    if confidence_score < 70.0:
        return "Indeterminate (Low Confidence)"
    
    if predicted_class == 'NORMAL':
        return "No Risk"
    elif predicted_class == 'VIRAL_PNEUMONIA':
        return "Medium Risk"
    elif predicted_class == 'BACTERIAL_PNEUMONIA':
        return "High Risk"
    else:
        return "Unknown"

# --- 2. Define the Ensemble Prediction Function ---
def predict(image_bytes, disable_cam_override=False):
    """Takes image bytes, returns prediction, confidence, risk level, and (optional) Grad-CAM."""
    try:
        if MODEL_CONVNEXT is None or MODEL_EFFICIENTNET is None:
            load_models()

        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        input_tensor = transform(image).unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            outputs1 = MODEL_CONVNEXT(input_tensor)
            probs1 = torch.nn.functional.softmax(outputs1, dim=1)
            outputs2 = MODEL_EFFICIENTNET(input_tensor)
            probs2 = torch.nn.functional.softmax(outputs2, dim=1)
            avg_probs = (CONVNEXT_WEIGHT * probs1) + (EFFICIENTNET_WEIGHT * probs2)
            confidence, predicted_idx = torch.max(avg_probs, 1)

        predicted_class = CLASS_NAMES[predicted_idx.item()]
        confidence_score = confidence.item() * 100
        
        # --- Call the new risk level function ---
        risk_level = get_risk_level(predicted_class, confidence_score)

        gradcam_overlay = None
        if not DISABLE_CAM and not disable_cam_override:
            try:
                target_layer_efficientnet = MODEL_EFFICIENTNET.features[-1]
                gradcam_overlay = get_grad_cam(MODEL_EFFICIENTNET, image_bytes, target_layer_efficientnet)
            except Exception as cam_err:
                print(f"[PREDICT] WARN: Grad-CAM generation failed: {cam_err}")
                traceback.print_exc()
                gradcam_overlay = None

        return predicted_class, confidence_score, risk_level, gradcam_overlay
    except Exception as e:
        print(f"[PREDICT] ERROR in predict function: {e}")
        traceback.print_exc()
        raise

# --- 3. Define the API Endpoints ---

@app.route("/", methods=["GET"])
def home():
    """Home endpoint."""
    return jsonify({
        "message": "Pneumonia Detection API",
        "status": "running",
        "endpoints": {
            "/health": "GET - Health check",
            "/predict": "POST - Predict pneumonia from X-ray image"
        }
    }), 200

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    status = (MODEL_CONVNEXT is not None) and (MODEL_EFFICIENTNET is not None)
    return jsonify({"status": "ok" if status else "loading"}), 200

@app.route("/predict", methods=["POST"])
def handle_prediction():
    req_id = uuid.uuid4().hex[:8]
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file part in the request"}), 400
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected for uploading"}), 400

        image_bytes = file.read()
        disable_cam_request = request.form.get('disable_cam', 'false').lower() == 'true'
        
        # --- Get the new risk_level from the predict function ---
        predicted_class, confidence, risk_level, gradcam_overlay = predict(image_bytes, disable_cam_request)

        gradcam_base64 = None
        if gradcam_overlay is not None:
            try:
                _, buffer = cv2.imencode('.png', cv2.cvtColor(gradcam_overlay, cv2.COLOR_RGB2BGR))
                gradcam_base64 = base64.b64encode(buffer).decode('utf-8')
            except Exception as e:
                print(f"[REQ {req_id}] WARN: Failed to encode Grad-CAM image: {e}")
                traceback.print_exc()

        # Format prediction text by removing underscores
        formatted_prediction = predicted_class.replace("_", " ")
        
        resp = {
            "prediction": formatted_prediction,
            "confidence": f"{confidence:.2f}%",
            # --- Add the new risk_level to the response ---
            "risk_level": risk_level,
            "gradcam_image": gradcam_base64
        }
        return jsonify(resp), 200
    except Exception as e:
        print(f"[REQ {req_id}] ERROR: Unhandled exception in /predict: {e}")
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# --- 4. Run the App ---
if __name__ == "__main__":
    load_models()
    port = int(os.getenv("PORT", 5000))
    app.run(debug=False, use_reloader=False, host='0.0.0.0', port=port, threaded=True)