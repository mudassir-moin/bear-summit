from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import base64
import re


def _build_service(access_token: str, refresh_token: str):
    creds = Credentials(
        token=access_token,
        refresh_token=refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=__import__("os").environ["GOOGLE_CLIENT_ID"],
        client_secret=__import__("os").environ["GOOGLE_CLIENT_SECRET"],
        scopes=["https://www.googleapis.com/auth/gmail.readonly"],
    )
    return build("gmail", "v1", credentials=creds, cache_discovery=False)


def _extract_snippet(payload: dict) -> str:
    body = payload.get("body", {})
    if body.get("data"):
        try:
            return base64.urlsafe_b64decode(body["data"]).decode("utf-8")[:300]
        except Exception:
            pass
    for part in payload.get("parts", []):
        if part.get("mimeType") == "text/plain":
            data = part.get("body", {}).get("data", "")
            if data:
                try:
                    return base64.urlsafe_b64decode(data).decode("utf-8")[:300]
                except Exception:
                    pass
    return ""


async def fetch_recent_emails(access_token: str, refresh_token: str, max_results: int = 50) -> list[dict]:
    try:
        service = _build_service(access_token, refresh_token)
        result = service.users().messages().list(
            userId="me",
            maxResults=max_results,
            q="is:unread",
        ).execute()

        messages = result.get("messages", [])
        emails = []

        for msg in messages[:max_results]:
            detail = service.users().messages().get(
                userId="me",
                id=msg["id"],
                format="metadata",
                metadataHeaders=["Subject", "From", "Date"],
            ).execute()

            headers = {h["name"]: h["value"] for h in detail.get("payload", {}).get("headers", [])}
            emails.append({
                "id": msg["id"],
                "subject": headers.get("Subject", "(no subject)"),
                "from": headers.get("From", ""),
                "date": headers.get("Date", ""),
                "snippet": detail.get("snippet", ""),
            })

        return emails
    except HttpError as e:
        print(f"Gmail API error: {e}")
        return []
