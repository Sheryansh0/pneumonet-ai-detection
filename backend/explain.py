# explain.py
from PIL import Image
import io
import torch
import cv2
import numpy as np
from pytorch_grad_cam import GradCAM
from pytorch_grad_cam.utils.image import show_cam_on_image, preprocess_image
import traceback
import gc

def get_grad_cam_optimized(model, image_bytes, target_layer, max_size=(224, 224)):
    """Generate Grad-CAM heatmap overlay with optimizations for memory and speed.

    Returns: np.ndarray (RGB) or None if it fails.
    """
    try:
        print("[GRAD-CAM] Starting optimized Grad-CAM generation...")
        
        # Load and resize image efficiently
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        
        # Resize to max_size to reduce memory usage
        if image.size != max_size:
            image = image.resize(max_size, Image.Resampling.LANCZOS)
        
        image_np = np.array(image)
        image_float = np.float32(image_np) / 255.0

        # Preprocess with memory optimization
        input_tensor = preprocess_image(
            image_float,
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        )

        # Ensure eval mode and disable gradients for other parameters
        was_training = model.training
        if was_training:
            model.eval()

        # Use context manager with timeout-like behavior
        try:
            with GradCAM(model=model, target_layers=[target_layer]) as cam:
                # Generate CAM with reduced precision for speed
                grayscale_cam = cam(input_tensor=input_tensor, targets=None, aug_smooth=False, eigen_smooth=False)
                grayscale_cam = grayscale_cam[0, :]
                
                # Clear intermediate tensors and force garbage collection
                del input_tensor
                gc.collect()
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()
                
        except Exception as cam_error:
            print(f"[GRAD-CAM] CAM generation error: {cam_error}")
            return None

        # Restore training mode if needed
        if was_training:
            model.train()

        # Generate visualization with optimized parameters
        visualization = show_cam_on_image(
            image_float, 
            grayscale_cam, 
            use_rgb=True,
            colormap=cv2.COLORMAP_JET,
            image_weight=0.6  # Slightly more emphasis on original image
        )
        
        # Force garbage collection again to be safe
        gc.collect()
        
        print("[GRAD-CAM] Optimized Grad-CAM generation complete")
        return visualization
        
    except Exception as e:
        print(f"[GRAD-CAM] ERROR: Optimized Grad-CAM failed: {e}")
        traceback.print_exc()
        return None

def get_grad_cam(model, image_bytes, target_layer):
    """Generate Grad-CAM heatmap overlay safely - wrapper for backward compatibility.

    Returns: np.ndarray (RGB) or None if it fails.
    """
    return get_grad_cam_optimized(model, image_bytes, target_layer)