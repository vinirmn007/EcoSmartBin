import base64
from fastapi import APIRouter, UploadFile, File, HTTPException, Header

try:
    import logic
except ImportError:
    from . import logic

router = APIRouter()

@router.post("/predict")
async def predict_garbage(
    file: UploadFile = File(...),
    bin_id: str = None,
    x_bin_id: str = Header(None, alias="X-Bin-Id")
):
    """
    Procesa la imagen proveniente del ESP32-CAM o frontend, ejecuta inferencia
    manual y retorna las predicciones estructuradas con la imagen base64.
    
    Antes de clasificar, valida que el basurero tenga una sesión activa
    consultando al servicio de basureros. Si no la tiene, rechaza la petición.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Provided file payload is not an image.")

    # Determinar el ID del basurero (Cabecera X-Bin-Id > Parámetro > Variable de entorno)
    raw_bin_id = x_bin_id or bin_id or logic.BIN_ID
    effective_bin_id = raw_bin_id.lower().strip()

    # ── Validar sesión activa con servicio_basureros ──
    session_user_id = await logic.validate_bin_session(effective_bin_id)

    try:
        contents = await file.read()
        label, score, top_predictions = logic.classify_image(contents)

        image_base64 = base64.b64encode(contents).decode('utf-8')
        image_data_url = f"data:{file.content_type};base64,{image_base64}"

        result = {
            "success": True,
            "class": label,
            "confidence": round(score, 4),
            "top_predictions": top_predictions,
            "imagen_base64": image_data_url,
            "usuario_id": session_user_id
        }

        # ── Reenviar clasificación al servicio de puntos (fire-and-forget) ──
        await logic.forward_classification_to_points(
            effective_bin_id, label, score, image_data_url, session_user_id
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference pipeline failure: {str(e)}")


@router.get("/")
async def root():
    return {
        "status": "healthy",
        "engine": "pure-onnxruntime",
        "model_type": logic.active_model_type,
        "allowed_classes": logic.ALLOWED_CLASSES if logic.active_model_type == "yolo" else list(logic.labels.values())
    }
