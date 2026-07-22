import io
import os
import json
import base64
import numpy as np
import onnxruntime as ort
import httpx
from PIL import Image
from fastapi import HTTPException

# URL del servicio de puntos (configurable via variable de entorno)
PUNTOS_SERVICE_URL = os.getenv("PUNTOS_SERVICE_URL", "http://host.docker.internal:8081")
# URL del servicio de basureros para validar sesiones activas
BASUREROS_SERVICE_URL = os.getenv("BASUREROS_SERVICE_URL", "http://host.docker.internal:8082")
# ID del basurero asociado a este servicio de IA
BIN_ID = os.getenv("BIN_ID", "eco01")

# Variables de configuración del Modelo (YOLO vs ViT)
MODEL_TYPE = os.getenv("MODEL_TYPE", "yolo").lower().strip()
ALLOWED_CLASSES_RAW = os.getenv("ALLOWED_CLASSES", "paper,plastic,glass")
ALLOWED_CLASSES = [c.strip().lower() for c in ALLOWED_CLASSES_RAW.split(",") if c.strip()]
YOLO_CONFIDENCE_THRESHOLD = float(os.getenv("YOLO_CONFIDENCE_THRESHOLD", "0.40"))

# Estado global del modelo persistido en memoria
ort_session: ort.InferenceSession | None = None
labels: dict[int, str] | None = None
active_model_type: str = "yolo"

# Normalización estándar ImageNet para ViT
IMAGENET_MEAN = np.array([0.5, 0.5, 0.5], dtype=np.float32)
IMAGENET_STD = np.array([0.5, 0.5, 0.5], dtype=np.float32)


def resolve_model_path(model_type: str) -> tuple[str, str]:
    """
    Busca la ruta del modelo ONNX y su archivo de etiquetas correspondiente.
    """
    if model_type == "yolo":
        model_candidates = [
            os.getenv("MODEL_PATH", ""),
            "modelo.onnx",
            "models/modelo.onnx",
            "servicio_AI/modelo.onnx",
            "servicio_AI/models/modelo.onnx",
            "garbage_model.onnx",
            "models/garbage_model.onnx",
            "servicio_AI/garbage_model.onnx",
            "servicio_AI/models/garbage_model.onnx"
        ]
        label_candidates = [
            "yolo_labels.json",
            "servicio_AI/yolo_labels.json",
            "labels.json",
            "servicio_AI/labels.json"
        ]
    else:
        model_candidates = [
            os.getenv("MODEL_PATH", ""),
            "garbage_model.onnx",
            "models/garbage_model.onnx",
            "servicio_AI/garbage_model.onnx",
            "servicio_AI/models/garbage_model.onnx"
        ]
        label_candidates = [
            "labels.json",
            "servicio_AI/labels.json"
        ]

    model_path = next((p for p in model_candidates if p and os.path.exists(p)), None)
    label_path = next((p for p in label_candidates if p and os.path.exists(p)), "labels.json")

    if not model_path:
        raise FileNotFoundError(f"No se encontró archivo de modelo ONNX para type '{model_type}'")

    return model_path, label_path


def load_model():
    """
    Carga el modelo ONNX en memoria según la configuración activa.
    """
    global ort_session, labels, active_model_type
    print(f"Loading ONNX model components (Requested type: '{MODEL_TYPE}')...")

    sess_options = ort.SessionOptions()
    sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

    try:
        model_path, label_path = resolve_model_path(MODEL_TYPE)
        active_model_type = MODEL_TYPE
    except FileNotFoundError as err:
        print(f"[WARNING] {err}. Falling back to ViT default model...")
        active_model_type = "vit"
        model_path, label_path = resolve_model_path("vit")

    if active_model_type == "yolo":
        sess_options.intra_op_num_threads = 2
    else:
        sess_options.intra_op_num_threads = 1

    print(f"Loading model from: {model_path}")
    ort_session = ort.InferenceSession(model_path, sess_options)

    with open(label_path, "r") as f:
        labels = {int(k): v for k, v in json.load(f).items()}

    print(f"All ONNX components loaded successfully! (Engine: {active_model_type}, Labels: {len(labels)})")


def unload_model():
    """
    Libera los recursos del modelo.
    """
    global ort_session
    ort_session = None


def preprocess_image(image: Image.Image) -> np.ndarray:
    """
    Preprocesamiento para ViT (224x224, ImageNet norm).
    """
    img = image.resize((224, 224), Image.Resampling.BILINEAR)
    img_array = np.array(img, dtype=np.float32) / 255.0
    img_array = (img_array - IMAGENET_MEAN) / IMAGENET_STD
    img_array = img_array.transpose(2, 0, 1)
    return np.expand_dims(img_array, axis=0)


def preprocess_yolo(image: Image.Image, target_size: int = 640) -> np.ndarray:
    """
    Preprocesamiento para YOLO: Letterbox (640x640) y normalización [0, 1].
    """
    orig_w, orig_h = image.size
    scale = min(target_size / orig_w, target_size / orig_h)
    new_w, new_h = int(orig_w * scale), int(orig_h * scale)

    img_resized = image.resize((new_w, new_h), Image.Resampling.BILINEAR)

    img_padded = Image.new("RGB", (target_size, target_size), (114, 114, 114))
    pad_x = (target_size - new_w) // 2
    pad_y = (target_size - new_h) // 2
    img_padded.paste(img_resized, (pad_x, pad_y))

    img_array = np.array(img_padded, dtype=np.float32) / 255.0
    img_array = img_array.transpose(2, 0, 1)
    return np.expand_dims(img_array, axis=0)


def postprocess_yolo_as_classifier(
    outputs: list | np.ndarray,
    label_map: dict,
    allowed_classes: list[str],
    confidence_threshold: float
) -> dict:
    """
    Convierte las detecciones de YOLO (1, 300, 6) o (300, 6) en clasificación.
    """
    if isinstance(outputs, list):
        tensor = outputs[0]
    else:
        tensor = outputs

    if tensor.ndim == 3:
        detections = tensor[0]
    else:
        detections = tensor

    mask = detections[:, 4] >= confidence_threshold
    valid_dets = detections[mask]

    if len(valid_dets) == 0:
        return {
            "class": "trash",
            "confidence": 0.0,
            "top_predictions": [{"label": "trash", "confidence": 0.0}]
        }

    candidates = []
    for det in valid_dets:
        class_id = int(det[5])
        class_name = label_map.get(class_id, "trash").lower().strip()
        conf = float(det[4])

        if class_name in allowed_classes:
            candidates.append({"label": class_name, "confidence": conf})

    if not candidates:
        return {
            "class": "trash",
            "confidence": 0.0,
            "top_predictions": [{"label": "trash", "confidence": 0.0}]
        }

    candidates.sort(key=lambda x: x["confidence"], reverse=True)

    seen_classes = set()
    unique_top = []
    for c in candidates:
        if c["label"] not in seen_classes:
            seen_classes.add(c["label"])
            unique_top.append({"label": c["label"], "confidence": round(c["confidence"], 4)})

    best = unique_top[0]

    return {
        "class": best["label"],
        "confidence": best["confidence"],
        "top_predictions": unique_top[:3]
    }


async def validate_bin_session(effective_bin_id: str) -> str | None:
    """
    Consulta al servicio de basureros para verificar que exista una sesión activa.
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            session_resp = await client.get(
                f"{BASUREROS_SERVICE_URL}/internal/bins/{effective_bin_id}/session"
            )
            if session_resp.status_code == 200:
                try:
                    session_data = session_resp.json()
                except Exception:
                    session_data = {}
                session_user_id = session_data.get("usuario_id")
                print(f"[OK] Sesión activa encontrada para bin '{effective_bin_id}' -> usuario: {session_user_id}")
                return session_user_id
            else:
                try:
                    error_detail = session_resp.json().get("detail", "Sin sesión activa")
                except Exception:
                    error_detail = session_resp.text or "Sin sesión activa"
                print(f"[ERROR] No hay sesión activa para bin '{effective_bin_id}': {error_detail}")
                raise HTTPException(
                    status_code=403,
                    detail=f"No hay usuario conectado al basurero '{effective_bin_id}'. "
                           f"El usuario debe escanear el QR del basurero primero. Detalle: {error_detail}"
                )
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 404:
            raise HTTPException(
                status_code=403,
                detail=f"No hay usuario conectado al basurero '{effective_bin_id}'. Escanee el QR primero."
            )
        raise HTTPException(status_code=500, detail=f"Error al verificar la sesión del basurero: {str(e)}")
    except httpx.RequestError as e:
        print(f"[WARNING] No se pudo contactar al servicio de basureros: {e}")
        raise HTTPException(
            status_code=503,
            detail="No se pudo verificar la sesión del basurero. Servicio de basureros no disponible."
        )


async def forward_classification_to_points(
    effective_bin_id: str,
    label: str,
    score: float,
    image_data_url: str,
    session_user_id: str | None
):
    """
    Reenvía la clasificación procesada al servicio de puntos.
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            payload = {
                "binId": effective_bin_id,
                "tipoDetectado": label,
                "confianza": round(score, 4),
                "imagenBase64": image_data_url,
                "usuarioId": session_user_id
            }
            resp = await client.post(
                f"{PUNTOS_SERVICE_URL}/points/clasificacion-pendiente",
                json=payload
            )
            print(f"[POST] Clasificación enviada al servicio de puntos: {label} ({round(score*100, 1)}%) -> usuario: {session_user_id} -> HTTP {resp.status_code}")
    except Exception as fwd_err:
        print(f"[WARNING] No se pudo reenviar al servicio de puntos: {fwd_err}")


def classify_image(contents: bytes) -> tuple[str, float, list[dict]]:
    """
    Ejecuta la inferencia con el modelo activo (YOLO o ViT) sobre la imagen dada.
    """
    image = Image.open(io.BytesIO(contents)).convert("RGB")

    input_meta = ort_session.get_inputs()[0]
    input_name = input_meta.name
    input_type = input_meta.type

    if active_model_type == "yolo":
        input_data = preprocess_yolo(image)
        if "float16" in input_type:
            input_data = input_data.astype(np.float16)
        else:
            input_data = input_data.astype(np.float32)

        onnx_outputs = ort_session.run(None, {input_name: input_data})
        classification = postprocess_yolo_as_classifier(
            onnx_outputs, labels, ALLOWED_CLASSES, YOLO_CONFIDENCE_THRESHOLD
        )
        return classification["class"], classification["confidence"], classification["top_predictions"]
    else:
        input_data = preprocess_image(image)
        if "float16" in input_type:
            input_data = input_data.astype(np.float16)
        elif "float32" in input_type:
            input_data = input_data.astype(np.float32)

        onnx_inputs = {input_name: input_data}
        onnx_outputs = ort_session.run(None, onnx_inputs)
        logits = onnx_outputs[0]

        exp_logits = np.exp(logits - np.max(logits, axis=-1, keepdims=True))
        probs = exp_logits / np.sum(exp_logits, axis=-1, keepdims=True)

        idx = int(np.argmax(probs))
        label = labels[idx]
        score = float(probs[0][idx])

        probs_flat = probs[0]
        top_indices = np.argsort(probs_flat)[::-1][:3]
        top_predictions = [
            {"label": labels[int(i)], "confidence": round(float(probs_flat[i]), 4)}
            for i in top_indices
        ]
        return label, score, top_predictions
