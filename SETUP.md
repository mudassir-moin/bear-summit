# CogniOS — Setup Guide

## Live Demo Links (update these once deployed) 

| | URL |
|---|---|
| **Web app** | https://mudassir-moin.github.io/bear-summit/ |
| **APK download** | GitHub → Actions tab → latest run → Artifacts → `cognios-debug-*.apk` |
| **Backend API** | https://cognios-api.onrender.com |

---

## 1 — Enable GitHub Pages (one-time, 2 minutes)

1. Go to `github.com/mudassir-moin/bear-summit` → **Settings** → **Pages**
2. Source: **Deploy from a branch**
3. Branch: **`gh-pages`** / root
4. Save

After every push to the dev branch, GitHub Actions auto-rebuilds the web app.
The APK is downloadable from the **Actions** tab → latest run → **Artifacts**.

---

## 2 — Deploy Backend to Render (one-time, 5 minutes)

1. Go to [render.com](https://render.com) → **New Web Service**
2. Connect your `mudassir-moin/bear-summit` GitHub repo
3. Render reads `render.yaml` automatically and configures everything
4. Set the following environment variables in the Render dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_KEY`
   - `OPENAI_API_KEY`
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET`
   - `GOOGLE_REDIRECT_URI` → `https://cognios-api.onrender.com/auth/google/callback`
   - `TELEGRAM_BOT_TOKEN` (optional)
5. Leave `DEMO_MODE=true` until you're ready to use real credentials

**After deploy:** Copy your Render URL (e.g. `https://cognios-api.onrender.com`)  
→ Add it as a GitHub secret: **Settings → Secrets → `API_URL`**  
→ Re-trigger GitHub Actions to rebuild web + APK with the live backend URL

---

## 3 — Supabase (one-time, 5 minutes)

1. Create a free project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** → paste the contents of `supabase/schema.sql` → Run
3. Copy your **Project URL** and **service_role key** (Settings → API)
4. Add both to Render environment variables

---

## 4 — Google Cloud (Gmail + Calendar + OAuth)

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project: **CogniOS**
3. Enable APIs:
   - Gmail API
   - Google Calendar API
   - Google People API
4. OAuth consent screen → External → fill in app name/email
5. Credentials → Create OAuth 2.0 Client ID → Web application
   - Authorized redirect URIs: `https://cognios-api.onrender.com/auth/google/callback`
6. Copy Client ID and Client Secret → add to Render env vars

---

## 5 — OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com) → API Keys → Create
2. Add to Render as `OPENAI_API_KEY`
3. Set `DEMO_MODE=false` in Render to enable live AI briefings
4. **Credit tip:** Briefings are cached 4 hours — one AI call per user per 4h max

---

## Running Locally

```bash
# Backend
cd backend
cp .env.example .env     # fill in your keys
pip install -r requirements.txt
uvicorn main:app --reload

# Frontend
cd frontend
flutter pub get
flutter run              # emulator or connected phone

# Build web locally
flutter build web --base-href /bear-summit/

# Build APK locally
flutter build apk --debug
```

---

## Demo Mode (zero credentials needed)

Set `DEMO_MODE=true` in `.env` or Render → all API calls return pre-written  
realistic demo data instantly. The Flutter app also has a **"Try Demo"** button  
on the login screen that bypasses Google auth entirely and shows the same data  
from local storage — no network call needed.
