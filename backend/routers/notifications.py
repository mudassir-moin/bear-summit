import os
import json
import httpx
from fastapi import APIRouter, Query
from pydantic import BaseModel
from db.supabase_client import get_client

router = APIRouter(prefix="/notifications", tags=["notifications"])


async def _get_access_token() -> str | None:
    """Get a short-lived OAuth2 token from the service account JSON."""
    sa_json = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "")
    if not sa_json:
        return None

    try:
        import google.auth
        import google.auth.transport.requests
        from google.oauth2 import service_account

        sa_info = json.loads(sa_json)
        credentials = service_account.Credentials.from_service_account_info(
            sa_info,
            scopes=["https://www.googleapis.com/auth/firebase.messaging"],
        )
        request = google.auth.transport.requests.Request()
        credentials.refresh(request)
        return credentials.token
    except Exception as e:
        print(f"FCM auth error: {e}")
        return None


async def _send_fcm_v1(token: str, title: str, body: str) -> bool:
    sa_json = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "")
    if not sa_json:
        return False

    try:
        project_id = json.loads(sa_json).get("project_id", "")
        access_token = await _get_access_token()
        if not access_token:
            return False

        url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                url,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                json={
                    "message": {
                        "token": token,
                        "notification": {"title": title, "body": body},
                        "android": {"priority": "HIGH"},
                    }
                },
            )
        return resp.status_code == 200
    except Exception as e:
        print(f"FCM send error: {e}")
        return False


class FCMTokenRequest(BaseModel):
    user_id: str
    fcm_token: str


class NotificationPayload(BaseModel):
    user_id: str
    title: str
    body: str
    type: str = "general"


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
    ok = await _send_fcm_v1(token, body.title, body.body)

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
