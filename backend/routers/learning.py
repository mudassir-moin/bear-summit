import os
import json
from datetime import date, timedelta
from fastapi import APIRouter, HTTPException, Query, UploadFile, File, Form
from db.supabase_client import get_client
from services.pdf_service import extract_text_from_pdf
from services.ai_service import extract_memory

router = APIRouter(prefix="/learning", tags=["learning"])

DEMO_MATERIALS = [
    {
        "id": "demo-learn-0",
        "title": "Fourier Transforms — Week 6 Lecture",
        "summary": "Fourier transforms decompose signals into frequency components. They are essential in signal processing, image compression, and solving differential equations.",
        "key_concepts": [
            {"concept": "Fourier Series", "explanation": "Represents a periodic function as a sum of sine and cosine waves."},
            {"concept": "Frequency Domain", "explanation": "A representation of a signal in terms of its constituent frequencies rather than time."},
            {"concept": "DFT", "explanation": "Discrete Fourier Transform — applies Fourier analysis to sampled signals."},
            {"concept": "Convolution Theorem", "explanation": "Convolution in time domain equals multiplication in frequency domain."},
            {"concept": "Nyquist Theorem", "explanation": "A signal must be sampled at twice its highest frequency to avoid aliasing."},
        ],
        "review_questions": [
            {"question": "What does a Fourier transform convert a signal from?", "answer": "From the time domain to the frequency domain."},
            {"question": "What is the Nyquist sampling rate?", "answer": "At least twice the highest frequency in the signal."},
            {"question": "State the convolution theorem.", "answer": "Convolution in time = multiplication in frequency domain."},
            {"question": "What is aliasing?", "answer": "Distortion caused by undersampling a signal below the Nyquist rate."},
            {"question": "Name one real-world application of Fourier transforms.", "answer": "Audio/image compression (MP3, JPEG), signal processing, MRI scanning."},
        ],
        "next_review_date": str(date.today()),
        "review_interval_days": 1,
    }
]


def _next_review_date(interval_days: int) -> str:
    return str(date.today() + timedelta(days=interval_days))


def _next_interval(current: int) -> int:
    schedule = {1: 3, 3: 7, 7: 14, 14: 30}
    return schedule.get(current, min(current * 2, 30))


@router.post("/upload")
async def upload_material(
    user_id: str = Form(...),
    file: UploadFile = File(...),
):
    demo_mode = os.environ.get("DEMO_MODE", "false").lower() == "true"
    if demo_mode:
        return DEMO_MATERIALS[0]

    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large. Max 10 MB.")

    text = extract_text_from_pdf(content)
    if len(text.strip()) < 50:
        raise HTTPException(status_code=400, detail="Could not extract text from PDF.")

    result = await extract_memory(text)

    db = get_client()
    row = db.table("learning_materials").insert({
        "user_id": user_id,
        "title": result.get("title", file.filename),
        "source_text": text[:2000],
        "key_concepts": json.dumps(result.get("key_concepts", [])),
        "review_questions": json.dumps(result.get("review_questions", [])),
        "next_review_date": _next_review_date(1),
        "review_interval_days": 1,
    }).execute()

    saved = row.data[0]
    saved["summary"] = result.get("summary", "")
    saved["key_concepts"] = result.get("key_concepts", [])
    saved["review_questions"] = result.get("review_questions", [])
    return saved


@router.get("")
async def get_materials(user_id: str = Query(...)):
    demo_mode = os.environ.get("DEMO_MODE", "false").lower() == "true"
    if demo_mode:
        return DEMO_MATERIALS

    db = get_client()
    result = db.table("learning_materials").select(
        "id, title, summary, key_concepts, review_questions, next_review_date, review_interval_days, created_at"
    ).eq("user_id", user_id).order("created_at", desc=True).execute()

    materials = []
    for row in result.data:
        row["key_concepts"] = json.loads(row.get("key_concepts") or "[]")
        row["review_questions"] = json.loads(row.get("review_questions") or "[]")
        materials.append(row)
    return materials


@router.get("/due")
async def get_due_materials(user_id: str = Query(...)):
    demo_mode = os.environ.get("DEMO_MODE", "false").lower() == "true"
    if demo_mode:
        return DEMO_MATERIALS

    db = get_client()
    today = str(date.today())
    result = db.table("learning_materials").select("*").eq("user_id", user_id).lte(
        "next_review_date", today
    ).execute()

    materials = []
    for row in result.data:
        row["key_concepts"] = json.loads(row.get("key_concepts") or "[]")
        row["review_questions"] = json.loads(row.get("review_questions") or "[]")
        materials.append(row)
    return materials


@router.post("/complete/{material_id}")
async def complete_review(material_id: str, user_id: str = Query(...)):
    demo_mode = os.environ.get("DEMO_MODE", "false").lower() == "true"
    if demo_mode:
        return {"status": "ok", "next_review_date": _next_review_date(3)}

    db = get_client()
    row = db.table("learning_materials").select(
        "review_interval_days"
    ).eq("id", material_id).eq("user_id", user_id).execute()

    if not row.data:
        raise HTTPException(status_code=404, detail="Material not found")

    current_interval = row.data[0]["review_interval_days"]
    next_interval = _next_interval(current_interval)
    next_date = _next_review_date(next_interval)

    db.table("learning_materials").update({
        "review_interval_days": next_interval,
        "next_review_date": next_date,
    }).eq("id", material_id).execute()

    return {"status": "ok", "next_review_date": next_date, "next_interval_days": next_interval}


@router.delete("/{material_id}")
async def delete_material(material_id: str, user_id: str = Query(...)):
    demo_mode = os.environ.get("DEMO_MODE", "false").lower() == "true"
    if demo_mode:
        return {"status": "deleted"}

    db = get_client()
    db.table("learning_materials").delete().eq("id", material_id).eq(
        "user_id", user_id
    ).execute()
    return {"status": "deleted"}
