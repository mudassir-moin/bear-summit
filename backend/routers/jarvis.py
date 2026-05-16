import os
from fastapi import APIRouter, Query

router = APIRouter(prefix="/jarvis", tags=["jarvis"])

_CATEGORY_KEYWORDS = {
    "academic": {"assignment", "lecture", "exam", "study", "course", "professor", "class", "homework", "rubric", "lms", "cs301", "midterm"},
    "work": {"meeting", "deadline", "project", "client", "standup", "email", "report", "presentation"},
    "home": {"birthday", "dinner", "appointment", "bill", "family", "grocery", "doctor"},
}

_DEMO_URGENT = {
    "greeting": "Hello. Here's your urgent summary for today.",
    "spoken_text": (
        "You have two urgent items. First, your assignment deadline has been moved to tonight "
        "by Professor Smith. Second, the KFAS scholarship application closes in four hours. "
        "Don't miss it. That's everything urgent."
    ),
    "cards": [
        {"title": "Assignment deadline moved to tonight", "body": "Prof. Smith updated the submission portal. Was due Friday.", "priority": "urgent", "source": "gmail"},
        {"title": "Scholarship application closes in 4 hours", "body": "KFAS Engineering Grant — link in email body.", "priority": "urgent", "source": "gmail"},
    ],
}

_DEMO_BY_CATEGORY = {
    "urgent": _DEMO_URGENT,
    "academic": {
        "greeting": "Here's your academic summary.",
        "spoken_text": (
            "You have two academic items. First, the CS301 midterm is tomorrow at 10 AM — time to review. "
            "Second, a new grading rubric has been uploaded to the LMS. That's everything academic."
        ),
        "cards": [
            {"title": "CS301 midterm — tomorrow 10 AM", "body": "Review lecture notes and past exams tonight.", "priority": "upcoming", "source": "calendar"},
            {"title": "New grading rubric uploaded", "body": "CS301 midterm — check LMS.", "priority": "important", "source": "gmail"},
        ],
    },
    "work": {
        "greeting": "Here's your work summary.",
        "spoken_text": "You have one work item. Team standup is Monday at 9 AM. That's everything for work.",
        "cards": [
            {"title": "Team standup — Monday 9 AM", "body": "Be prepared with your weekly update.", "priority": "upcoming", "source": "calendar"},
        ],
    },
    "home": {
        "greeting": "Here's your home summary.",
        "spoken_text": "You have one home item. Your friend's birthday dinner is tonight at 8 PM, which conflicts with your study block. That's everything for home.",
        "cards": [
            {"title": "Friend's birthday dinner — 8 PM", "body": "Conflicts with your 7 PM study block.", "priority": "important", "source": "calendar"},
        ],
    },
    "all": {
        "greeting": "Here's everything for today.",
        "spoken_text": (
            "You have six items today. Two are urgent: your assignment deadline moved to tonight, "
            "and the KFAS scholarship closes in four hours. "
            "Two are important: the AI networking event at 6 PM and a birthday dinner at 8 PM. "
            "One you may have missed: the Google STEP internship closes Sunday. "
            "And one opportunity: an AI research position from Dr. Al-Rashid. That's everything."
        ),
        "cards": [
            {"title": "Assignment deadline moved to tonight", "body": "Prof. Smith updated the submission portal.", "priority": "urgent", "source": "gmail"},
            {"title": "Scholarship application closes in 4 hours", "body": "KFAS Engineering Grant.", "priority": "urgent", "source": "gmail"},
            {"title": "AI & Society networking event — 6 PM", "body": "KFAS auditorium. Relevant to your career interests.", "priority": "important", "source": "calendar"},
            {"title": "Friend's birthday dinner — 8 PM", "body": "Conflicts with your 7 PM study block.", "priority": "important", "source": "calendar"},
            {"title": "Google STEP internship — closes Sunday", "body": "Mentioned in Telegram group 6 hours ago.", "priority": "missed", "source": "telegram"},
            {"title": "AI research assistant position — Dr. Al-Rashid", "body": "Open to undergraduates. Apply before end of semester.", "priority": "opportunity", "source": "gmail"},
        ],
    },
}


def _matches_category(item: dict, category: str) -> bool:
    if category == "all":
        return True
    if category == "urgent":
        return item.get("priority") == "urgent" or (item.get("urgency_score") or 0) > 75
    keywords = _CATEGORY_KEYWORDS.get(category, set())
    text = f"{item.get('title', '')} {item.get('body', '')}".lower()
    return any(kw in text for kw in keywords)


def _build_spoken(category: str, cards: list[dict]) -> str:
    if not cards:
        return f"You have no {category} items right now."
    ordinals = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth"]
    count = len(cards)
    parts = [f"You have {count} {'item' if count == 1 else 'items'}."]
    for i, card in enumerate(cards):
        title = card.get("title", "")
        body = (card.get("body") or "").split(".")[0]
        ordinal = ordinals[i] if i < len(ordinals) else "Next"
        parts.append(f"{ordinal}, {title}. {body}.")
    closing = f"That's everything{' ' + category if category != 'all' else ''}."
    parts.append(closing)
    return " ".join(parts)


@router.get("/brief")
async def jarvis_brief(
    user_id: str = Query(...),
    category: str = Query("all"),
):
    demo_mode = os.environ.get("DEMO_MODE", "false").lower() == "true"

    if demo_mode:
        data = _DEMO_BY_CATEGORY.get(category, _DEMO_BY_CATEGORY["all"])
        return data

    try:
        from db.supabase_client import get_client
        db = get_client()

        result = db.table("items").select("*").eq("user_id", user_id).order("urgency_score", desc=True).execute()
        items = result.data or []

        if not items:
            br = db.table("briefings").select("items_json").eq("user_id", user_id).order("created_at", desc=True).limit(1).execute()
            if br.data and br.data[0].get("items_json"):
                items = br.data[0]["items_json"]

        filtered = [i for i in items if _matches_category(i, category)][:8]
        cards = [
            {"title": i.get("title", ""), "body": i.get("body", ""), "priority": i.get("priority", "upcoming"), "source": i.get("source", "other")}
            for i in filtered
        ]
        label = category if category != "all" else "today's"
        return {
            "greeting": f"Here's your {label} summary.",
            "spoken_text": _build_spoken(category, cards),
            "cards": cards,
        }
    except Exception as e:
        print(f"Jarvis brief error: {e}")
        data = _DEMO_BY_CATEGORY.get(category, _DEMO_BY_CATEGORY["all"])
        return data
