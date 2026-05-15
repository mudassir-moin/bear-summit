import os
import httpx
from datetime import datetime, timezone, timedelta

_BASE = "https://api.telegram.org/bot{token}/{method}"


def _url(method: str) -> str:
    return _BASE.format(token=os.environ["TELEGRAM_BOT_TOKEN"], method=method)


async def get_bot_username() -> str:
    async with httpx.AsyncClient() as client:
        resp = await client.get(_url("getMe"))
    data = resp.json()
    return data.get("result", {}).get("username", "CogniOSBot")


async def send_message(chat_id: str, text: str) -> bool:
    async with httpx.AsyncClient() as client:
        resp = await client.post(_url("sendMessage"), json={"chat_id": chat_id, "text": text})
    return resp.status_code == 200


async def fetch_recent_messages(
    chat_ids: list[str],
    last_update_id: int | None,
    hours: int = 24,
) -> tuple[list[dict], int | None]:
    """
    Fetch unread bot updates, filter to last `hours` hours and to the given
    chat_ids.  Returns (messages, new_last_update_id).
    The caller should persist new_last_update_id so the next call only sees
    fresh updates.
    """
    params: dict = {"limit": 100, "allowed_updates": ["message"]}
    if last_update_id is not None:
        params["offset"] = last_update_id + 1

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(_url("getUpdates"), params=params)

    if resp.status_code != 200:
        return [], last_update_id

    updates = resp.json().get("result", [])
    if not updates:
        return [], last_update_id

    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    messages = []
    new_last_id = last_update_id

    for update in updates:
        new_last_id = update["update_id"]
        msg = update.get("message")
        if not msg:
            continue

        msg_time = datetime.fromtimestamp(msg["date"], tz=timezone.utc)
        if msg_time < cutoff:
            continue

        chat_id_str = str(msg["chat"]["id"])
        if chat_ids and chat_id_str not in chat_ids:
            continue

        sender = msg.get("from", {})
        messages.append({
            "chat_id": chat_id_str,
            "chat_type": msg["chat"].get("type", "private"),
            "chat_title": msg["chat"].get("title") or msg["chat"].get("first_name", ""),
            "sender": sender.get("first_name", "") + (" " + sender.get("last_name", "")).rstrip(),
            "text": msg.get("text", ""),
            "date": msg_time.isoformat(),
        })

    return messages, new_last_id


async def verify_chat_id(chat_id: str) -> bool:
    """Send a verification message to confirm the chat_id is reachable."""
    ok = await send_message(
        chat_id,
        "✅ CogniOS linked successfully! Your messages will now be included in your daily briefing.",
    )
    return ok
