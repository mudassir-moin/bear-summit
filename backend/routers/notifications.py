import os
import json
import httpx
from fastapi import APIRouter, Query
from pydantic import BaseModel
from db.supabase_client import get_client

router = APIRouter(prefix="/notifications", tags=["notifications"])

FCM_URL = "https://fcm.googleapis.com/fcm/send"


class FCMTokenRequest(BaseModel):
    user_id: str
    fcm_token: str


class NotificationPayload(BaseModel):
    user_id: str
    title: str
    body: str
    type: str = "general"


async def _send_fcm(token: str, title: str, body: str) -> bool:
    server_key = os.environ.get("FCM_SERVER_KEY", "")
    if not server_key:
        return False

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            FCM_URL,
            headers={
                "Authorization": f"key={server_key}",
                "Content-Type": "application/json",
            },
            json={
                "to": token,
                "notification": {"title": title, "body": body},
                "priority": "high",
            },
        )
    return resp.status_code == 200


@router.post("/register")
async def register_fcm_token(body: FCMTokenRequest):
    db = get_client()
    db.table("users").update({"fcm_token": body.fcm_token}).eq(
        "id", body.user_id
    ).execute()
    return {"status": "registered"}


@router.post("/send")
async def send_notification(body: NotificationPayload):
    db = get_client()
    user = db.table("users").select("fcm_token").eq("id", body.user_id).execute()
    if not user.data or not user.data[0].get("fcm_token"):
        return {"status": "no_token"}

    token = user.data[0]["fcm_token"]
    ok = await _send_fcm(token, body.title, body.body)

    db.table("notifications").insert({
        "user_id": body.user_id,
        "title": body.title,
        "body": body.body,
        "type": body.type,
    }).execute()

    return {"status": "sent" if ok else "fcm_not_configured"}


@router.get("/history")
async def get_notification_history(user_id: str = Query(...)):
    db = get_client()
    result = db.table("notifications").select("*").eq(
        "user_id", user_id
    ).order("sent_at", desc=True).limit(20).execute()
    return result.data
