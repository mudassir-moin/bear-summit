from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from db.supabase_client import get_client
from services.telegram_service import verify_chat_id, get_bot_username
import os

router = APIRouter(prefix="/sources", tags=["sources"])


class TelegramLinkRequest(BaseModel):
    user_id: str
    chat_id: str


@router.get("/telegram/bot-info")
async def telegram_bot_info():
    """Returns the bot username so the frontend can show a deep-link."""
    try:
        username = await get_bot_username()
        return {"username": username, "link": f"https://t.me/{username}"}
    except Exception:
        # TELEGRAM_BOT_TOKEN may not be set yet
        return {"username": os.environ.get("TELEGRAM_BOT_USERNAME", "CogniOSBot"), "link": ""}


@router.post("/telegram/link")
async def link_telegram(body: TelegramLinkRequest):
    """
    Verify a Telegram chat_id is reachable then store it on the user record.
    The bot sends a confirmation message to the chat so the user knows it worked.
    """
    ok = await verify_chat_id(body.chat_id)
    if not ok:
        raise HTTPException(
            status_code=400,
            detail="Could not reach that chat. Make sure you started a conversation with the bot first.",
        )

    db = get_client()
    db.table("users").update({"telegram_chat_id": body.chat_id}).eq("id", body.user_id).execute()

    return {"status": "linked", "chat_id": body.chat_id}


@router.delete("/telegram/unlink")
async def unlink_telegram(user_id: str = Query(...)):
    db = get_client()
    db.table("users").update({"telegram_chat_id": None}).eq("id", user_id).execute()
    return {"status": "unlinked"}


@router.get("/status")
async def sources_status(user_id: str = Query(...)):
    """Returns which sources are connected for this user."""
    db = get_client()
    result = db.table("users").select(
        "google_access_token, telegram_chat_id"
    ).eq("id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    row = result.data[0]
    return {
        "gmail": bool(row.get("google_access_token")),
        "calendar": bool(row.get("google_access_token")),
        "telegram": bool(row.get("telegram_chat_id")),
        "pdf": False,
    }
