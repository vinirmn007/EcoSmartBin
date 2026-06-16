import io
import json
import numpy as np
import onnxruntime as ort
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from contextlib import asynccontextmanager

# Variables globales para persistir los elementos en memoria
ort_session = None
labels = None

# Valores de normalización estándar para modelos Vision Transformer (ImageNet)
IMAGENET_MEAN = np.array([0.5, 0.5, 0.5], dtype=np.float32)
IMAGENET_STD = np.array([0.5, 0.5, 0.5], dtype=np.float32)

def preprocess_image(image: Image.Image) -> np.ndarray:
    """
    Replica exactamente el comportamiento de AutoImageProcessor usando solo Pillow y NumPy.
    Garantiza compatibilidad con ViT ocupando cero espacio en disco.
    """
    # 1. Redimensionar a 224x224 (El tamaño estricto que exige el grafo ONNX)
    img = image.resize((224, 224), Image.Resampling.BILINEAR)
    
    # 2. Convertir a matriz de NumPy y normalizar a rango [0.0, 1.0]
    img_array = np.array(img, dtype=np.float32) / 255.0
    
    # 3. Aplicar estandarización: (pixel - mean) / std
    img_array = (img_array - IMAGENET_MEAN) / IMAGENET_STD
    
    # 4. Cambiar el orden de los ejes (HWC a CHW) -> De (224, 224, 3) a (3, 224, 224)
    img_array = img_array.transpose(2, 0, 1)
    
    # 5. Añadir la dimensión del Batch -> De (3, 224, 224) a (1, 3, 224, 224)
    img_array = np.expand_dims(img_array, axis=0)
    
    return img_array

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Maneja el ciclo de vida de la app cargando ONNX Runtime de manera optimizada.
    """
    global ort_session, labels
    print("Loading lightweight ONNX model components...")
    
    # Configuración estricta de hilos para mitigar picos de memoria en Cloud Run
    sess_options = ort.SessionOptions()
    sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    sess_options.intra_op_num_threads = 1 
    
    # Inicializar la sesión cargando el grafo principal
    ort_session = ort.InferenceSession("garbage_model.onnx", sess_options)
    
    # Cargar el mapeo de etiquetas de texto
    with open("labels.json", "r") as f:
        labels = {int(k): v for k, v in json.load(f).items()}
        
    print("All ONNX model components loaded successfully!")
    yield
    # Limpieza en el apagado
    ort_session = None

app = FastAPI(
    title="Optimized Garbage Classification API",
    description="Ultra-lightweight pure ONNX inference service.",
    lifespan=lifespan
)

@app.post("/predict")
async def predict_garbage(file: UploadFile = File(...)):
    """
    Procesa la imagen proveniente del ESP32-CAM o frontend, ejecuta inferencia
    manual y retorna las predicciones estructuradas.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Provided file payload is not an image.")

    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")

        # Preprocesamiento manual optimizado sin dependencias pesadas
        input_data = preprocess_image(image)
        
        # Detectar el nombre y tipo de la capa de entrada del ONNX
        input_meta = ort_session.get_inputs()[0]
        input_name = input_meta.name
        input_type = input_meta.type
        
        # Forzar cast de tipo según exija el modelo exportado (usualmente float32)
        if "float16" in input_type:
            input_data = input_data.astype(np.float16)
        elif "float32" in input_type:
            input_data = input_data.astype(np.float32)

        onnx_inputs = {input_name: input_data}

        # Ejecución de la inferencia matemática pura
        onnx_outputs = ort_session.run(None, onnx_inputs)
        logits = onnx_outputs[0]

        # Cálculo de Softmax usando NumPy estándar
        exp_logits = np.exp(logits - np.max(logits, axis=-1, keepdims=True))
        probs = exp_logits / np.sum(exp_logits, axis=-1, keepdims=True)

        # Extraer predicción principal
        idx = int(np.argmax(probs))
        label = labels[idx]
        score = float(probs[0][idx])

        # Construir Top 3 de predicciones
        probs_flat = probs[0]
        top_indices = np.argsort(probs_flat)[::-1][:3]
        top_predictions = [
            {"label": labels[int(i)], "confidence": round(float(probs_flat[i]), 4)}
            for i in top_indices
        ]

        return {
            "success": True,
            "class": label,
            "confidence": round(score, 4),
            "top_predictions": top_predictions
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference pipeline failure: {str(e)}")

@app.get("/")
async def root():
    return {"status": "healthy", "engine": "pure-onnxruntime"}