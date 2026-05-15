from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from datetime import datetime, timezone, timedelta
import os


def _build_service(access_token: str, refresh_token: str):
    creds = Credentials(
        token=access_token,
        refresh_token=refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=os.environ["GOOGLE_CLIENT_ID"],
        client_secret=os.environ["GOOGLE_CLIENT_SECRET"],
        scopes=["https://www.googleapis.com/auth/calendar.readonly"],
    )
    return build("calendar", "v3", credentials=creds, cache_discovery=False)


async def fetch_upcoming_events(access_token: str, refresh_token: str, days: int = 7) -> list[dict]:
    try:
        service = _build_service(access_token, refresh_token)
        now = datetime.now(timezone.utc)
        time_max = now + timedelta(days=days)

        result = service.events().list(
            calendarId="primary",
            timeMin=now.isoformat(),
            timeMax=time_max.isoformat(),
            maxResults=30,
            singleEvents=True,
            orderBy="startTime",
        ).execute()

        events = []
        for item in result.get("items", []):
            start = item.get("start", {})
            events.append({
                "id": item.get("id"),
                "title": item.get("summary", "(no title)"),
                "description": item.get("description", ""),
                "start": start.get("dateTime") or start.get("date", ""),
                "location": item.get("location", ""),
            })

        return events
    except HttpError as e:
        print(f"Calendar API error: {e}")
        return []
