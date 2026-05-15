import os
import json
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, HTTPException, Query
from models.schemas import BriefingResponse, PriorityItem
from db.supabase_client import get_client
from services.gmail_service import fetch_recent_emails
from services.calendar_service import fetch_upcoming_events
from services.telegram_service import fetch_recent_messages as fetch_telegram_messages
from services.ai_service import generate_briefing
from prompts.briefing_prompt import DEMO_BRIEFING, DEMO_ITEMS

router = APIRouter(prefix="/briefing", tags=["briefing"])

CACHE_TTL_HOURS = 4


def _is_cache_fresh(generated_at_str: str) -> bool:
    try:
        generated_at = datetime.fromisoformat(generated_at_str.replace("Z", "+00:00"))
        return datetime.now(timezone.utc) - generated_at < timedelta(hours=CACHE_TTL_HOURS)
    except Exception:
        return False


def _format_aggregated_data(
    emails: list[dict],
    events: list[dict],
    telegram_msgs: list[dict],
) -> str:
    lines = ["=== GMAIL (unread emails) ==="]
    for e in emails[:30]:
        lines.append(f"- From: {e['from']} | Subject: {e['subject']} | {e['snippet'][:100]}")

    lines.append("\n=== GOOGLE CALENDAR (next 7 days) ===")
    for ev in events:
        lines.append(f"- {ev['start']} | {ev['title']} | {ev.get('description', '')[:80]}")

    if telegram_msgs:
        lines.append("\n=== TELEGRAM (last 24h) ===")
        for msg in telegram_msgs[:40]:
            chat = msg.get("chat_title") or "DM"
            lines.append(f"- [{chat}] {msg['sender']}: {msg['text'][:120]}")

    return "\n".join(lines)


@router.get("", response_model=BriefingResponse)
async def get_briefing(user_id: str = Query(...), force: bool = Query(False)):
    demo_mode = os.environ.get("DEMO_MODE", "false").lower() == "true"

    if demo_mode:
        items = [PriorityItem(id=f"demo-{i}", **item) for i, item in enumerate(DEMO_ITEMS)]
        return BriefingResponse(
            content=DEMO_BRIEFING,
            items=items,
            generated_at=datetime.now(timezone.utc),
            from_cache=True,
        )

    db = get_client()

    if not force:
        cached = db.table("briefings").select("*").eq("user_id", user_id).order("generated_at", desc=True).limit(1).execute()
        if cached.data and _is_cache_fresh(cached.data[0]["generated_at"]):
            row = cached.data[0]
            raw_items = json.loads(row.get("items_json", "[]"))
            items = [PriorityItem(id=f"cached-{i}", **item) for i, item in enumerate(raw_items)]
            return BriefingResponse(
                content=row["content"],
                items=items,
                generated_at=datetime.fromisoformat(row["generated_at"].replace("Z", "+00:00")),
                from_cache=True,
            )

    user_row = db.table("users").select("*").eq("id", user_id).execute()
    if not user_row.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_row.data[0]
    access_token = user.get("google_access_token", "")
    refresh_token = user.get("google_refresh_token", "")
    telegram_chat_id = user.get("telegram_chat_id")
    last_update_id = user.get("telegram_last_update_id")

    emails, events, telegram_msgs = [], [], []

    if access_token:
        emails = await fetch_recent_emails(access_token, refresh_token)
        events = await fetch_upcoming_events(access_token, refresh_token)

    if telegram_chat_id and os.environ.get("TELEGRAM_BOT_TOKEN"):
        chat_ids = [cid.strip() for cid in telegram_chat_id.split(",") if cid.strip()]
        telegram_msgs, new_last_id = await fetch_telegram_messages(
            chat_ids=chat_ids,
            last_update_id=int(last_update_id) if last_update_id else None,
        )
        if new_last_id is not None:
            db.table("users").update(
                {"telegram_last_update_id": new_last_id}
            ).eq("id", user_id).execute()

    aggregated = _format_aggregated_data(emails, events, telegram_msgs)
    ai_result = await generate_briefing(
        aggregated_data=aggregated,
        user_name=user.get("name", "there"),
        user_type=user.get("user_type", "student"),
    )

    briefing_content = ai_result.get("briefing", "")
    raw_items = ai_result.get("items", [])
    now = datetime.now(timezone.utc)

    db.table("briefings").insert({
        "user_id": user_id,
        "content": briefing_content,
        "items_json": json.dumps(raw_items),
        "generated_at": now.isoformat(),
    }).execute()

    items = [PriorityItem(id=f"new-{i}", **item) for i, item in enumerate(raw_items)]
    return BriefingResponse(
        content=briefing_content,
        items=items,
        generated_at=now,
        from_cache=False,
    )


@router.post("/refresh")
async def refresh_briefing(user_id: str = Query(...)):
    return await get_briefing(user_id=user_id, force=True)
