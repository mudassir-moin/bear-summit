# CogniOS — MVP Implementation Plan
## BEAR Summit 2026 Hackathon

> **Resume instruction**: If starting a new chat, read this file first and say:
> "I am resuming the CogniOS MVP build. Read PLAN.md and continue from the last completed checkpoint."

---

## Product Summary

**Name**: CogniOS (working title)
**Tagline**: *An AI second brain that prevents important things from slipping through the cracks.*

This is NOT a productivity app or reminder tool.
It is an **AI-powered cognitive operating system** that:
- Aggregates fragmented information (Gmail, Calendar, Telegram, PDFs)
- Filters noise and surfaces only what truly matters
- Proactively warns about forgotten commitments and hidden deadlines
- Reinforces long-term memory through spaced repetition
- Sends intelligent, context-aware alerts (not spam)

**Core emotional pitch**: Modern people aren't failing because of lack of information — they're failing because they can't manage the overwhelming volume of fragmented information competing for their attention.

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Frontend | Flutter | Cross-platform, APK export, fast UI |
| Backend | Python + FastAPI | Best AI integration, fast dev |
| Database | Supabase | Auth + PostgreSQL + storage, fast setup |
| AI | OpenAI API (GPT-4o) | Primary. Claude API optional later |
| Auth | Google Sign-In (OAuth2) | Required for Gmail/Calendar |
| Notifications | Firebase Cloud Messaging (FCM) | Android push, Flutter-friendly |
| Integrations | Gmail API, Google Calendar API, Telegram Bot API, PDF upload | Only these 4 |

---

## App Screens (5 total)

### Screen 1 — Dashboard (Hero Screen)
Sections:
- URGENT (red/high priority cards)
- IMPORTANT (amber cards)
- UPCOMING (next 24–48h events)
- MEMORY REVIEWS (spaced repetition prompts)
- MISSED / MAY SLIP (hidden/forgotten items)
- OPPORTUNITIES (scholarships, internships, events)

Design: calm, minimal, large spacing, dark mode, card-based, clear hierarchy.
Inspiration: Linear, Superhuman, Arc Browser, Perplexity AI, Headspace.

### Screen 2 — Daily Briefing
AI-generated morning briefing. Format:

```
Good morning, [Name].

URGENT
- Assignment deadline moved to tonight (from email)
- Scholarship application closes in 6 hours (Telegram)

IMPORTANT
- Professor uploaded new rubric (Gmail)
- Friend's birthday dinner tonight — conflicts with study session

LEARNING REVIEW
- You struggled with Fourier transforms last week. 5-min review ready.

MISSED YESTERDAY
- Networking event you didn't RSVP to

OPPORTUNITIES
- AI internship relevant to your profile opened today
```

### Screen 3 — Learning
- Upload PDFs / lecture notes
- AI-generated review prompts
- Mini quizzes
- Spaced repetition schedule
- "You're likely to forget this soon" alerts

### Screen 4 — Sources
Connected integrations:
- Gmail (OAuth toggle)
- Google Calendar (OAuth toggle)
- Telegram (Bot token / link)
- PDFs (file upload)

### Screen 5 — Settings / Profile
- Notification preferences
- User context (student / professional / founder)
- API key management (internal)

---

## Core Features (Build These Only)

### Feature 1: Unified Daily Briefing
- Backend aggregates all sources at scheduled time (or on-demand)
- AI prompt constructs structured briefing from raw data
- Frontend displays formatted briefing on Screen 2
- Briefing cached in Supabase, refreshed on pull-to-refresh

### Feature 2: Smart Priority Detection
- AI classifies each item: URGENT / IMPORTANT / UPCOMING / OPPORTUNITY / MISSED
- Uses urgency scoring (deadline proximity, keywords, sender importance)
- Items surfaced on Dashboard with appropriate card styling

### Feature 3: AI Memory Reinforcement
- User uploads PDF → backend extracts text → AI generates:
  - 5 key concepts
  - 5 review questions
  - Spaced repetition schedule (day 1, day 3, day 7, day 14)
- Daily learning notification if review is due

### Feature 4: "Did You Miss Something?" Engine
- Runs nightly (or on-demand)
- Checks: unread important emails, Telegram messages with deadlines, upcoming events not yet acknowledged
- Surfaces hidden/missed items in Dashboard and as push notification

### Feature 5: AI-Powered Intelligent Notifications
Types:
1. Urgent deadline alerts (deadline within 2–6 hours)
2. Commitment reminders (birthdays, events, appointments)
3. "You may have missed this" (hidden deadline in crowded group chat)
4. Learning reinforcement ("Review this concept now")
5. Opportunity detection (scholarship, internship, relevant event)

Philosophy: Few but meaningful. Never spam. Every notification must be actionable.
Implementation: Backend assigns urgency score (0–100). If score > threshold, trigger FCM push.

---

## DO NOT BUILD (Prototype Killers)

- WhatsApp / Instagram / Messenger integration
- Browser automation / autonomous agents
- Complex memory graphs or vector databases
- Real-time sync across all platforms simultaneously
- Voice INPUT (speech-to-text / microphone) ← do not implement; use tap chips instead
- Full offline support
- Multi-agent systems
- Local AI models

---

## Feature 8: Grouped Notification Center (Added 2026-05-17)

**Concept**: Replace per-item notification spam with a single, clean notification experience. A bell icon in the dashboard AppBar (with badge count) opens a bottom sheet showing tasks grouped into collapsible sections: 🔴 Urgent, 🎓 Academic, 💼 Work, 🏠 Home, 📅 Events, ❌ Missed. Each section header shows a count. Users tap to expand and see only the relevant tasks. Tapping "✓ Done" on any task removes it immediately. Once a task's deadline has passed it auto-moves to Missed and disappears from its original section.

**Why valuable**: Judges and users already have notification fatigue. One clean tray that self-cleans is dramatically better than 6 individual pings.

**Category rules**:
| Section | Logic |
|---|---|
| 🔴 Urgent | `priority == 'urgent'` OR `urgency_score > 75`, deadline not passed |
| 🎓 Academic | keyword match: assignment, exam, lecture, cs301, rubric, lms… |
| 💼 Work | keyword match: meeting, project, standup, client, presentation… |
| 🏠 Home | keyword match: birthday, dinner, appointment, grocery, doctor… |
| 📅 Events | `source == 'calendar'`, deadline not passed |
| ❌ Missed | deadline < now OR `priority == 'missed'` |

An item past its deadline appears **only** in Missed, regardless of other categories.

### New Files
```
frontend/lib/widgets/notification_center_sheet.dart  ← bottom sheet with ExpansionTile per category
frontend/lib/services/notification_center_service.dart  ← groupItems(), badgeCount(), isExpired(), acknowledgeItem()
frontend/lib/services/local_notification_service.dart   ← flutter_local_notifications wrapper (Android grouped push)
backend/routers/items.py                                ← POST /items/acknowledge (sets is_acknowledged=true)
```

### Modified Files
```
frontend/pubspec.yaml                        ← add flutter_local_notifications: ^17.2.2
frontend/lib/main.dart                       ← call LocalNotificationService.init() at startup
frontend/lib/screens/dashboard_screen.dart  ← add bell icon + badge in AppBar, wire acknowledge
frontend/lib/services/api_service.dart      ← add acknowledgeItem() method
backend/main.py                             ← register items router
backend/routers/briefing.py                 ← auto-expire items past deadline (set priority='missed')
```

### Mark as Done
- **Demo mode**: remove from local `_items` list immediately (no backend call)
- **Production**: `POST /items/acknowledge` → `is_acknowledged = true` in Supabase → item gone

### Android OS Notifications
Uses `flutter_local_notifications` with InboxStyle + notification groups. One notification per active category (expandable in Android notification shade). One notification channel per category registered at app startup with appropriate importance levels (Urgent = high, Missed = low).

---

## Feature 6: Jarvis Voice Assistant (Added 2026-05-16)

**Concept**: A mic FAB on the Dashboard opens a full-screen "Jarvis mode" overlay. The AI greets the user by name with a live summary of their day, then offers suggestion chips. The user taps a chip, and the AI speaks a natural-language summary while text detail cards fade in one by one in sync — like Iron Man's JARVIS.

**Why valuable**: Users don't want to read tabs. They want to hear a brief, human-sounding summary while seeing supporting detail cards appear. Zero typing needed.

**Credit cost**: Zero extra AI calls. Backend reformats already-cached briefing items using string templates. Demo mode returns pre-scripted spoken text.

### New Files
```
backend/routers/jarvis.py              ← GET /jarvis/brief?user_id=X&category=...
backend/services/reminder_service.py  ← progressive reminder logic (piggybacked on briefing)
frontend/lib/screens/jarvis_screen.dart
frontend/lib/widgets/jarvis_orb.dart
frontend/lib/services/jarvis_service.dart
```

### Modified Files
```
backend/main.py                        ← register jarvis router
backend/routers/briefing.py           ← call check_and_send_reminders() at end
supabase/schema.sql                   ← ALTER TABLE items ADD COLUMN last_reminded_at
frontend/pubspec.yaml                 ← add flutter_tts: ^4.0.2
frontend/lib/demo/demo_data.dart      ← add Jarvis demo constants
frontend/lib/screens/dashboard_screen.dart ← add mic FAB
```

### Jarvis UX — Three Phases

**Phase 1 — Personalized Greeting**
- Pulsing green orb in center
- Time-of-day greeting: "Good morning/afternoon/evening, [first name]."
- Built from already-loaded item list (no extra API call):
  - "Your [top urgent title] is due tonight — top priority."
  - "Your [nearest milestone] is in [N] days, worth preparing early."
  - "What would you like to start with?"
- TTS speaks all of this as one fluent sentence
- Demo: "Good morning. Your assignment is due tonight — top priority. Your CS301 midterm is in 3 days. You have 4 other items. What would you like to start with?"

**Phase 2 — Suggestion Chips**
- 5 chips slide up from bottom: 🔴 Urgent · 🎓 Academic · 💼 Work · 🏠 Home · ✨ Everything
- Speed slider shown: 🐢 ────── 🐇 (range 0.3–0.7, saved to SharedPreferences)
- User taps chip → Phase 3

**Phase 3 — Speaking + Cards**
- Orb pulses fast (speaking state)
- TTS speaks natural summary (from /jarvis/brief endpoint)
- Cards fade in + slide up one by one, concurrent with speech, staggered by text-length × 60ms
- "Ask another" + "Done" buttons at bottom

**Category filtering (backend)**:
- urgent: priority == "urgent" or urgency_score > 75
- academic: keywords → assignment, lecture, exam, study, course, professor, class, homework, rubric, lms
- work: meeting, deadline, project, client, standup, email, report, presentation
- home: birthday, dinner, appointment, bill, family, grocery, doctor
- all: everything sorted by urgency_score desc

---

## Feature 7: Progressive Preparation Reminders (Added 2026-05-16)

**Concept**: For upcoming events with deadlines, send FCM push notifications with increasing frequency as the event approaches — not every day, only often enough to give the user time to act.

**Reminder cadence**:
| Days until event | Remind every |
|---|---|
| > 14 days | No reminder yet |
| 7–14 days | Every 7 days |
| 3–7 days | Every 2 days |
| 1–3 days | Every day |
| < 24 hours | Morning (9 AM) + Evening (6 PM) |

**Implementation**: No scheduler needed. Piggybacked on `GET /briefing` — when user fetches briefing, backend checks each upcoming/important item with a deadline:
1. `days_until = (deadline_date - today).days`
2. Check `last_reminded_at` on item row
3. If overdue for reminder → send FCM push, update `last_reminded_at`

**FCM push format**: Title: `"Prepare: [item title]"` / Body: `"[N] days away. Tap to see your summary."`

**Supabase**: `ALTER TABLE items ADD COLUMN IF NOT EXISTS last_reminded_at timestamptz;`

---

## Folder Structure

```
bear-summit/
├── PLAN.md                  ← This file (always read first)
├── PROGRESS.md              ← Checkpoints (update as you build)
├── backend/
│   ├── main.py              ← FastAPI entry point
│   ├── routers/
│   │   ├── auth.py          ← OAuth, token management
│   │   ├── briefing.py      ← Daily briefing endpoint
│   │   ├── sources.py       ← Gmail, Calendar, Telegram, PDF
│   │   ├── learning.py      ← Memory reinforcement
│   │   └── notifications.py ← FCM push logic
│   ├── services/
│   │   ├── ai_service.py    ← Centralized OpenAI calls + prompt templates
│   │   ├── gmail_service.py
│   │   ├── calendar_service.py
│   │   ├── telegram_service.py
│   │   └── pdf_service.py
│   ├── models/
│   │   └── schemas.py       ← Pydantic models
│   ├── db/
│   │   └── supabase_client.py
│   ├── prompts/
│   │   ├── briefing_prompt.py
│   │   ├── priority_prompt.py
│   │   └── memory_prompt.py
│   ├── .env.example
│   └── requirements.txt
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── briefing_screen.dart
│   │   │   ├── learning_screen.dart
│   │   │   ├── sources_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── widgets/
│   │   │   ├── priority_card.dart
│   │   │   ├── briefing_section.dart
│   │   │   └── source_tile.dart
│   │   ├── services/
│   │   │   ├── api_service.dart    ← Backend HTTP client
│   │   │   └── auth_service.dart   ← Google Sign-In
│   │   └── theme/
│   │       └── app_theme.dart      ← Dark mode, colors, typography
│   └── pubspec.yaml
└── supabase/
    └── schema.sql               ← DB tables
```

---

## Database Schema (Supabase)

```sql
-- Users
create table users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  name text,
  user_type text default 'student', -- student | professional | founder
  google_access_token text,
  google_refresh_token text,
  telegram_chat_id text,
  fcm_token text,
  created_at timestamptz default now()
);

-- Aggregated items (emails, events, messages)
create table items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  source text not null, -- gmail | calendar | telegram | pdf
  title text not null,
  body text,
  priority text, -- urgent | important | upcoming | opportunity | missed
  urgency_score int default 0,
  action_required boolean default false,
  deadline timestamptz,
  is_acknowledged boolean default false,
  raw_data jsonb,
  created_at timestamptz default now()
);

-- Daily briefings
create table briefings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  content text not null, -- AI-generated markdown text
  generated_at timestamptz default now()
);

-- Learning materials
create table learning_materials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  title text,
  source_text text,
  key_concepts jsonb,  -- [{concept, explanation}]
  review_questions jsonb, -- [{question, answer}]
  next_review_date date,
  review_interval_days int default 1,
  created_at timestamptz default now()
);

-- Notification log
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  title text,
  body text,
  type text, -- deadline | commitment | missed | learning | opportunity
  sent_at timestamptz default now()
);
```

---

## Backend API Endpoints

```
POST   /auth/google          → Exchange Google OAuth code, store tokens
POST   /auth/refresh         → Refresh Google tokens

GET    /briefing             → Generate/return today's briefing
POST   /briefing/refresh     → Force regenerate briefing

GET    /items                → Get all prioritized items for user
POST   /items/acknowledge    → Mark item as seen

POST   /sources/telegram     → Link Telegram chat ID
GET    /sources/sync         → Trigger sync of all sources

POST   /learning/upload      → Upload PDF, returns extracted material
GET    /learning             → Get all learning materials
GET    /learning/due         → Get materials due for review today
POST   /learning/complete    → Mark review done, schedule next

POST   /notifications/register → Store FCM token
POST   /notifications/send   → Internal: trigger push (called by scheduler)
```

---

## AI Prompt Templates

### Briefing Prompt
```
You are an intelligent cognitive assistant. The user is a {user_type}.

Based on the following raw data from their digital sources, generate a structured daily briefing.
Categorize items as URGENT, IMPORTANT, UPCOMING, MEMORY REVIEW, MISSED, or OPPORTUNITIES.
Be concise. Prioritize ruthlessly. Highlight hidden deadlines and forgotten commitments.

Raw data:
{aggregated_data}

Output format (markdown):
## Good morning, {name}.

### URGENT
- ...

### IMPORTANT
- ...

### UPCOMING
- ...

### LEARNING REVIEW
- ...

### YOU MAY HAVE MISSED
- ...

### OPPORTUNITIES
- ...
```

### Priority Scoring Prompt
```
Score this item from 0-100 for urgency. Consider:
- Deadline proximity (within 2h = 95+, within 6h = 80+, within 24h = 60+)
- Keywords: deadline, urgent, ASAP, final, closes, expires, tonight, now
- Sender importance
- Action required vs informational

Item: {item_text}
Output: {"score": int, "reason": str, "priority": "urgent|important|upcoming|opportunity|missed"}
```

### Memory Extraction Prompt
```
Extract the most important learning content from this text.
Output JSON:
{
  "key_concepts": [{"concept": str, "explanation": str}],  // 5 items max
  "review_questions": [{"question": str, "answer": str}],  // 5 items max
  "summary": str  // 2-3 sentences
}

Text: {extracted_text}
```

---

## Build Order (Optimized for Speed)

Follow this exact order. Each step is a checkpoint in PROGRESS.md.

### Phase 0: Setup (30 min)
- [ ] P0.1 Initialize Flutter project: `flutter create frontend`
- [ ] P0.2 Initialize FastAPI backend with folder structure
- [ ] P0.3 Create Supabase project, run schema.sql
- [ ] P0.4 Set up Google Cloud project: enable Gmail API, Calendar API, configure OAuth
- [ ] P0.5 Set up Firebase project for FCM
- [ ] P0.6 Create `.env` with all keys (never commit)
- [ ] P0.7 Push empty scaffold to GitHub

### Phase 1: Backend Core (2–3 hours)
- [ ] P1.1 FastAPI entry point + CORS + health check
- [ ] P1.2 Supabase client setup
- [ ] P1.3 Google OAuth endpoint (exchange code → store tokens)
- [ ] P1.4 Gmail service (fetch last 50 unread emails)
- [ ] P1.5 Calendar service (fetch next 7 days events)
- [ ] P1.6 PDF service (extract text from uploaded PDF)
- [ ] P1.7 AI service (centralized OpenAI wrapper)
- [ ] P1.8 Briefing endpoint (aggregate → AI → return)
- [ ] P1.9 Priority scoring for items
- [ ] P1.10 Memory extraction endpoint

### Phase 2: Telegram Integration (1 hour)
- [ ] P2.1 Create Telegram Bot via BotFather
- [ ] P2.2 Telegram service (read messages from last 24h via bot)
- [ ] P2.3 Add Telegram data to briefing aggregation

### Phase 3: Notifications (1 hour)
- [ ] P3.1 FCM setup in Firebase
- [ ] P3.2 FCM token registration endpoint
- [ ] P3.3 Push notification sender service
- [ ] P3.4 Urgency threshold logic (score > 75 → push)
- [ ] P3.5 Scheduler (APScheduler) — run briefing nightly at 7am + missed check at 10pm

### Phase 4: Flutter Frontend (3–4 hours)
- [ ] P4.1 App theme (dark mode, colors, typography)
- [ ] P4.2 Google Sign-In flow
- [ ] P4.3 API service (http client, auth headers)
- [ ] P4.4 Dashboard screen with sections + priority cards
- [ ] P4.5 Daily Briefing screen (markdown rendered)
- [ ] P4.6 Learning screen (upload PDF, show review cards)
- [ ] P4.7 Sources screen (connection toggles)
- [ ] P4.8 Settings screen (basic)
- [ ] P4.9 Bottom navigation bar
- [ ] P4.10 FCM push notification handler in Flutter

### Phase 5: Polish + Demo Prep (1–2 hours)
- [ ] P5.1 Seed demo data (pre-load realistic Gmail/Calendar/Telegram data)
- [ ] P5.2 Demo mode toggle (bypass live API calls, use canned realistic data)
- [ ] P5.3 Animations and transitions
- [ ] P5.4 Test full flow end-to-end
- [ ] P5.5 Build APK: `flutter build apk --release`
- [ ] P5.6 Deploy backend to Railway or Render (free tier)
- [ ] P5.7 Record demo video as backup

---

## Environment Variables (backend/.env)

```env
# Supabase
SUPABASE_URL=
SUPABASE_SERVICE_KEY=

# OpenAI
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=

# Telegram
TELEGRAM_BOT_TOKEN=

# Firebase FCM
FIREBASE_SERVICE_ACCOUNT_JSON=

# App
SECRET_KEY=
ENVIRONMENT=development
```

---

## Design System

### Colors (Dark Mode)
```
Background:     #0D0D0D
Surface:        #1A1A1A
Surface2:       #242424
Urgent:         #FF3B30  (red)
Important:      #FF9500  (amber)
Upcoming:       #30D158  (green)
Opportunity:    #0A84FF  (blue)
Missed:         #FF6961  (soft red)
Text Primary:   #F5F5F5
Text Secondary: #8E8E93
```

### Typography
- Font: Inter or SF Pro (system default)
- Headlines: 28px, weight 700
- Section labels: 11px, weight 600, ALL CAPS, letter-spacing 1.2
- Body: 15px, weight 400
- Card title: 16px, weight 600

### Card Component
```
Priority Card:
- Left border accent (4px, color by priority type)
- Source icon top-right
- Title bold
- Subtitle/body muted
- Time/deadline bottom-right
- Rounded corners 12px
- Background: Surface (#1A1A1A)
- Padding: 16px
```

---

## Demo Script (For Judges)

1. Open app → Google Sign-In (or "Try Demo" — works offline)
2. Dashboard loads → URGENT cards visible immediately (pre-cached demo data)
3. **Tap mic FAB** (green, bottom-right) → Jarvis screen opens
4. Orb pulses, AI speaks: *"Good morning. Your assignment is due tonight — top priority. Your CS301 midterm is in 3 days. You have 4 other items. What would you like to start with?"*
5. Tap **🔴 Urgent** chip → orb pulses fast, AI speaks urgent summary, 2 red cards fade in as it speaks
6. Tap **🎓 Academic** → AI speaks academic summary, 2 blue cards appear
7. Tap **Done** → back to Dashboard
8. Show Sources screen — Gmail/Calendar connected, Telegram linked
9. Show Learning screen → review questions from uploaded PDF, spaced repetition schedule
10. Closing: *"Instead of checking 12 apps and still missing things — one briefing, zero slipping through the cracks. And now it talks to you."*

---

## Key Differentiators to Emphasize in Pitch

- NOT a productivity app — a **cognitive infrastructure layer**
- **Protects attention** instead of competing for it
- Combines **information management + memory reinforcement** (rare combination)
- AI decides what deserves interruption — no notification spam
- **"Did you miss something?"** engine is the killer demo moment
- Works across fragmented digital life in one unified view

---

## PROGRESS.md Checkpoint Format

When resuming, always check PROGRESS.md first. Format:

```
## Completed
- [P0.1] Flutter project initialized
- [P0.2] FastAPI scaffold created

## In Progress
- [P1.1] FastAPI entry point

## Blocked
- [P0.4] Waiting for Google Cloud OAuth credentials from user

## Next Up
- [P1.2] Supabase client setup
```

---

## Resuming in a New Chat

If you need to start a new Claude chat session, paste this at the start:

```
I am building CogniOS, an AI cognitive operating system for BEAR Summit 2026.
Read the file PLAN.md in the bear-summit repo for the full plan.
Read PROGRESS.md for current build state.
Continue building from the next uncompleted checkpoint.
Stack: Flutter + FastAPI + Supabase + OpenAI API.
Branch: claude/plan-mvp-implementation-3maww
```

---

*Last updated: 2026-05-16*
