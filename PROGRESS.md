# CogniOS — Build Progress

> Always read this file first when resuming a session.
> Update checkboxes as each item is completed.

---  

## Status: PHASE 3 COMPLETE — LIVE DEPLOYMENT PIPELINE READY

---

## Completed

### Phase 0 — Setup
- [x] P0.1 Folder structure created (backend/, frontend/, supabase/)
- [x] P0.2 FastAPI backend scaffold with all routers/services
- [x] P0.3 Supabase schema written (supabase/schema.sql) — run in Supabase SQL editor
- [x] P0.6 .env.example created — copy to .env and fill in keys
- [x] P0.7 Pushed to branch claude/plan-mvp-implementation-3maww

### Phase 1 — Backend Core
- [x] P1.1 FastAPI entry point (backend/main.py) with CORS + health check
- [x] P1.2 Supabase client (backend/db/supabase_client.py)
- [x] P1.3 Google OAuth endpoint (backend/routers/auth.py)
- [x] P1.4 Gmail service (backend/services/gmail_service.py)
- [x] P1.5 Calendar service (backend/services/calendar_service.py)
- [x] P1.7 AI service (backend/services/ai_service.py)
- [x] P1.8 Briefing endpoint with caching (backend/routers/briefing.py)
- [x] P1.9 Demo mode with pre-canned realistic data (prompts/briefing_prompt.py)

### Flutter Frontend
- [x] App theme — dark mode, Linear-inspired palette (lib/theme/app_theme.dart)
- [x] Google Sign-In + auth service (lib/services/auth_service.dart)
- [x] API service / HTTP client (lib/services/api_service.dart)
- [x] Priority card widget + section header (lib/widgets/priority_card.dart)
- [x] Login screen with feature list (lib/screens/login_screen.dart)
- [x] Dashboard screen with sections + skeleton loader (lib/screens/dashboard_screen.dart)
- [x] Daily Briefing screen — markdown rendered (lib/screens/briefing_screen.dart)
- [x] Sources screen — Gmail/Calendar connection, coming-soon tiles (lib/screens/sources_screen.dart)
- [x] Main app + bottom nav (lib/main.dart)
- [x] pubspec.yaml with all dependencies

---

## In Progress
*(none — ready for local setup)*

---

## Blocked / Needs User Action

**Before you can run the app, you need:**

1. **Supabase project** — create at supabase.com, run `supabase/schema.sql` in the SQL editor
2. **Google Cloud project** — enable Gmail API + Calendar API + create OAuth 2.0 credentials
3. **Copy and fill .env** — `cp backend/.env.example backend/.env` then fill all values
4. **Flutter local run:**
   ```
   cd frontend
   flutter pub get
   flutter run
   ```
5. **Backend local run:**
   ```
   cd backend
   pip install -r requirements.txt
   uvicorn main:app --reload
   ```
6. **Demo mode** (skip live API for judges) — set `DEMO_MODE=true` in `.env`

---

### Phase 2 — Telegram
- [x] P2.1 .env.example updated with TELEGRAM_BOT_TOKEN setup instructions
- [x] P2.2 Telegram service (backend/services/telegram_service.py) — getUpdates polling, 24h filter, chat_id scoping, update offset tracking
- [x] P2.3 Telegram data fed into briefing aggregation (briefing.py updated)
- [x] Sources router (backend/routers/sources.py) — link/unlink/status endpoints
- [x] Sources screen updated — real Telegram linking UI with bottom sheet + step-by-step instructions
- [x] API service updated — getTelegramBotInfo, linkTelegram, unlinkTelegram, getSourcesStatus
- [x] Supabase schema updated — telegram_last_update_id column + migration statement

---

### Phase 3 — Live Deployment Pipeline
- [x] .github/workflows/deploy.yml — GitHub Actions: builds web → deploys to gh-pages; builds debug APK → uploads as artifact; triggers on every push
- [x] backend/render.yaml — Render free-tier web service config (DEMO_MODE=true default, real keys set in Render dashboard)
- [x] Demo mode in Flutter: "Try Demo" button on login screen, bypasses Google auth, returns local demo data (zero network needed)
- [x] api_service.dart: demo mode short-circuit + 30s timeout with graceful fallback to local data (handles Render cold starts)
- [x] auth_service.dart: signInAsDemo() stores demo user in SharedPreferences
- [x] SETUP.md: one-page guide for teammates (Pages, Render, Supabase, Google Cloud, OpenAI)

---

## Pending One-Time Setup (user actions)

1. **GitHub Pages**: repo Settings → Pages → branch: `gh-pages` → Save
2. **Render**: connect repo, Render reads render.yaml, set env vars in dashboard
3. **GitHub Secret `API_URL`**: add Render URL after deploy (triggers rebuild)
4. Supabase: run `supabase/schema.sql`
5. Google Cloud: enable Gmail + Calendar APIs, create OAuth credentials
6. OpenAI: add API key to Render, set DEMO_MODE=false

---

---

### Phase 4 — Jarvis Voice Assistant + Progressive Reminders
*(Planned, partially implemented — resume from here next session)*

**Backend (partially done):**
- [x] `backend/routers/jarvis.py` — `GET /jarvis/brief?user_id=X&category=all|urgent|academic|work|home`. Filters cached items by category using keyword matching, builds natural-language spoken_text from templates, full demo mode with pre-scripted responses for all 5 categories. No AI call needed.
- [ ] `backend/main.py` — register jarvis router (`from routers import jarvis` + `app.include_router(jarvis.router)`)
- [ ] `backend/services/reminder_service.py` — progressive reminder logic (>14d: none, 7–14d: weekly, 3–7d: every 2d, 1–3d: daily, <24h: 2x/day). Piggybacked on briefing fetch — no scheduler needed.
- [ ] `backend/routers/briefing.py` — call `check_and_send_reminders()` at end of briefing fetch (non-blocking asyncio.create_task)
- [ ] `supabase/schema.sql` — add `ALTER TABLE items ADD COLUMN IF NOT EXISTS last_reminded_at timestamptz;`

**Frontend (not started):**
- [ ] `frontend/pubspec.yaml` — add `flutter_tts: ^4.0.2`
- [ ] `frontend/lib/demo/demo_data.dart` — add Jarvis demo constants (kDemoJarvisGreeting, kDemoJarvisSpoken, kDemoJarvisUrgentCards, kDemoJarvisAcademicCards, kDemoJarvisWorkCards, kDemoJarvisHomeCards, kDemoJarvisAllSpoken)
- [ ] `frontend/lib/services/jarvis_service.dart` — fetchBrief(category), speak(text, rate), stop(). Uses `awaitSpeakCompletion(true)` so speak() awaits TTS completion. Speech rate from SharedPreferences key `jarvis_speech_rate`.
- [ ] `frontend/lib/widgets/jarvis_orb.dart` — animated pulsing circle (idle=slow, speaking=fast+glow, done=static) using AnimationController
- [ ] `frontend/lib/screens/jarvis_screen.dart` — 3-phase screen:
  - Phase 1: Greeting orb + personalized TTS greeting (time-of-day aware, shows urgentCount, top urgent title, nearest milestone, asks "What would you like to start with?"). Receives items list from DashboardScreen constructor arg.
  - Phase 2: Suggestion chips slide up (🔴 Urgent / 🎓 Academic / 💼 Work / 🏠 Home / ✨ Everything) + speed slider (0.3–0.7, default 0.45)
  - Phase 3: Orb pulses fast, TTS speaks spoken_text, cards fade in one by one (concurrent with TTS, staggered by text-length × 60ms). Done button + Ask another button.
- [ ] `frontend/lib/screens/dashboard_screen.dart` — add green mic FAB (bottom-right), passes `_items` list to JarvisScreen

---

## Next Up

- [ ] **Phase 4 Jarvis** — implement frontend files above (resume from dashboard_screen FAB → jarvis_screen → orb widget → jarvis_service)
- [ ] **Feature 8 — Grouped Notification Center** — bell icon + badge in dashboard AppBar; bottom sheet with collapsible ExpansionTile per category (Urgent/Academic/Work/Home/Events/Missed); "✓ Done" dismisses items; deadline auto-expiry moves items to Missed; Android OS grouped push via flutter_local_notifications. See PLAN.md Feature 8 for full spec.
- [ ] Learning screen — PDF upload + AI memory extraction + review cards
- [ ] Demo polish — smooth animations, loading states

---

## Notes / Decisions

- Demo mode (`DEMO_MODE=true`) bypasses all live API calls and serves pre-written realistic data.
  Use this during the actual demo at BEAR Summit to guarantee instant response.
- Briefing is cached for 4 hours in Supabase. Force-refresh via pull-down or the refresh icon.
- API base URL is configured via `--dart-define=API_URL=https://your-backend.com` at build time.
  Default is `http://10.0.2.2:8000` (Android emulator localhost).
