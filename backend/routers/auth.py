import os
import json
import httpx
from fastapi import APIRouter, HTTPException
from models.schemas import GoogleAuthRequest, UserProfile
from db.supabase_client import get_client

router = APIRouter(prefix="/auth", tags=["auth"])

GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"


@router.post("/google")
async def google_auth(body: GoogleAuthRequest):
    async with httpx.AsyncClient() as client:
        token_resp = await client.post(GOOGLE_TOKEN_URL, data={
            "code": body.code,
            "client_id": os.environ["GOOGLE_CLIENT_ID"],
            "client_secret": os.environ["GOOGLE_CLIENT_SECRET"],
            "redirect_uri": body.redirect_uri,
            "grant_type": "authorization_code",
        })

    if token_resp.status_code != 200:
        raise HTTPException(status_code=400, detail="Failed to exchange Google auth code")

    tokens = token_resp.json()
    access_token = tokens["access_token"]
    refresh_token = tokens.get("refresh_token", "")

    async with httpx.AsyncClient() as client:
        user_resp = await client.get(
            GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {access_token}"},
        )
    user_info = user_resp.json()

    db = get_client()
    existing = db.table("users").select("id").eq("email", user_info["email"]).execute()

    if existing.data:
        user_id = existing.data[0]["id"]
        db.table("users").update({
            "google_access_token": access_token,
            "google_refresh_token": refresh_token,
            "name": user_info.get("name"),
        }).eq("id", user_id).execute()
    else:
        result = db.table("users").insert({
            "email": user_info["email"],
            "name": user_info.get("name"),
            "google_access_token": access_token,
            "google_refresh_token": refresh_token,
        }).execute()
        user_id = result.data[0]["id"]

    return {
        "user_id": user_id,
        "email": user_info["email"],
        "name": user_info.get("name"),
        "access_token": access_token,
    }


@router.get("/me")
async def get_me(user_id: str):
    db = get_client()
    result = db.table("users").select("id,email,name,user_type").eq("id", user_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")
    return result.data[0]
