import io
import os
import json
import base64
import asyncio
import numpy as np
import onnxruntime as ort
import httpx
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from contextlib import asynccontextmanager

PUNTOS_SERVICE_URL = os.getenv("PUNTOS_SERVICE_URL", "https://servicio-puntos-229724129072.southamerica-west1.run.app")
BIN_ID = os.getenv("BIN_ID", "EcoSmartBin-Q04")

# Global instances
ort_session = None
labels = None
# Removed global http_client to prevent DNS caching issues on startup

IMAGENET_MEAN = np.array([0.5, 0.5, 0.5], dtype=np.float32)
IMAGENET_STD = np.array([0.5, 0.5, 0.5], dtype=np.float32)

def preprocess_image(image: Image.Image) -> np.ndarray:
    """Resizes and normalizes the image purely in-memory."""
    img = image.resize((224, 224), Image.Resampling.BILINEAR)
    img_array = np.array(img, dtype=np.float32) / 255.0
    img_array = (img_array - IMAGENET_MEAN) / IMAGENET_STD
    img_array = img_array.transpose(2, 0, 1)
    return np.expand_dims(img_array, axis=0)

async def send_to_points_service(payload: dict):
    """Background task to ensure true fire-and-forget behavior."""
    try:
        # Creating a fresh client per background task prevents DNS poisoning
        # and a 30-second timeout allows Cloud Run to cold-start properly.
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                f"{PUNTOS_SERVICE_URL}/points/clasificacion-pendiente",
                json=payload
            )
            print(f"📤 Background sync successful: HTTP {resp.status_code}")
    except Exception as fwd_err:
        print(f"⚠️ Background sync failed: {fwd_err}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manages start/stop lifecycles cleanly."""
    global ort_session, labels
    print("Loading lightweight ONNX model components...")
    
    # Configure ONNX Runtime for serverless constraints
    sess_options = ort.SessionOptions()
    sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    sess_options.intra_op_num_threads = 1  
    
    ort_session = ort.InferenceSession("garbage_model.onnx", sess_options)
    
    with open("labels.json", "r") as f:
        labels = {int(k): v for k, v in json.load(f).items()}
        
    print("All components initialized successfully!")
    yield
    # Cleanup
    ort_session = None

app = FastAPI(
    title="Optimized Garbage Classification API",
    description="Ultra-lightweight pure ONNX inference service.",
    lifespan=lifespan
)

@app.post("/predict")
async def predict_garbage(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Provided file payload is not an image.")

    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")

        # In-memory preprocessing
        input_data = preprocess_image(image)
        
        input_meta = ort_session.get_inputs()[0]
        input_name = input_meta.name
        input_type = input_meta.type
        
        if "float16" in input_type:
            input_data = input_data.astype(np.float16)
        elif "float32" in input_type:
            input_data = input_data.astype(np.float32)

        # Inferences
        onnx_outputs = ort_session.run(None, {input_name: input_data})
        logits = onnx_outputs[0]

        # Softmax
        exp_logits = np.exp(logits - np.max(logits, axis=-1, keepdims=True))
        probs = exp_logits / np.sum(exp_logits, axis=-1, keepdims=True)

        idx = int(np.argmax(probs))
        label = labels[idx]
        score = float(probs[0][idx])

        # Top 3 mapping
        probs_flat = probs[0]
        top_indices = np.argsort(probs_flat)[::-1][:3]
        top_predictions = [
            {"label": labels[int(i)], "confidence": round(float(probs_flat[i]), 4)}
            for i in top_indices
        ]

        result = {
            "success": True,
            "class": label,
            "confidence": round(score, 4),
            "top_predictions": top_predictions
        }

        # Memory optimization: Convert raw payload to base64
        image_base64 = base64.b64encode(contents).decode('utf-8')

        # True fire-and-forget: dispatch payload to event loop asynchronously 
        payload = {
            "binId": BIN_ID,
            "tipoDetectado": label,
            "confianza": round(score, 4),
            "imagenBase64": f"data:{file.content_type};base64,{image_base64}"
        }
        asyncio.create_task(send_to_points_service(payload))

        # Instantly return response to client without waiting for the POST request
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference pipeline failure: {str(e)}")

@app.get("/")
async def root():
    return {"status": "healthy", "engine": "pure-onnxruntime"}