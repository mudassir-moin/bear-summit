BRIEFING_PROMPT = """\
You are an intelligent cognitive assistant. The user is a {user_type}.

Analyze the following raw data from their digital sources and generate two outputs:

1. A structured daily briefing (markdown format)
2. A JSON list of prioritized items

RULES:
- Be ruthlessly concise. Every line must earn its place.
- Highlight hidden deadlines and forgotten commitments first.
- Urgency score: 0-100. Use: deadline within 2h=95+, 6h=80+, 24h=60+, 48h=40+.
- Categories: URGENT, IMPORTANT, UPCOMING, MISSED, OPPORTUNITIES
- If nothing fits a category, omit that section entirely.

RAW DATA:
{aggregated_data}

---

Respond ONLY with valid JSON in this exact structure:
{{
  "briefing": "## Good morning, {name}.\\n\\n### URGENT\\n- ...\\n\\n### IMPORTANT\\n...",
  "items": [
    {{
      "source": "gmail",
      "title": "Assignment deadline moved to tonight",
      "body": "Prof. Smith email: submission closes 11:59 PM",
      "priority": "urgent",
      "urgency_score": 92,
      "deadline": "2026-05-15T23:59:00",
      "action_required": true
    }}
  ]
}}
"""

DEMO_BRIEFING = """\
## Good morning.

### URGENT
- **Assignment deadline moved to tonight** — Prof. Smith updated the submission portal (was Friday) *(Gmail)*
- **Scholarship application closes in 4 hours** — KFAS Engineering Grant, link in email *(Gmail)*

### IMPORTANT
- Networking event tonight at 6 PM — AI & Society panel, KFAS auditorium *(Calendar)*
- Friend's birthday dinner at 8 PM — conflicts with your 7 PM study block *(Calendar)*
- New grading rubric uploaded — CS301 midterm, check LMS *(Gmail)*

### UPCOMING
- CS301 midterm — tomorrow 10 AM *(Calendar)*
- Team standup — Monday 9 AM *(Calendar)*

### YOU MAY HAVE MISSED
- Internship application deadline mentioned in group chat 6 hours ago — Google STEP, closes Sunday *(Telegram)*
- Professor's office hours cancelled this week *(Gmail, unread)*

### OPPORTUNITIES
- Google STEP internship for undergraduates — deadline this Sunday *(Telegram)*
- AI research assistant position — posted by Dr. Al-Rashid *(Gmail)*
"""

DEMO_ITEMS = [
    {
        "source": "gmail",
        "title": "Assignment deadline moved to tonight",
        "body": "Prof. Smith updated the submission portal. Was due Friday.",
        "priority": "urgent",
        "urgency_score": 95,
        "deadline": None,
        "action_required": True,
    },
    {
        "source": "gmail",
        "title": "Scholarship application closes in 4 hours",
        "body": "KFAS Engineering Grant — link in email body.",
        "priority": "urgent",
        "urgency_score": 90,
        "deadline": None,
        "action_required": True,
    },
    {
        "source": "calendar",
        "title": "AI & Society networking event — 6 PM tonight",
        "body": "KFAS auditorium. Relevant to your career interests.",
        "priority": "important",
        "urgency_score": 65,
        "deadline": None,
        "action_required": False,
    },
    {
        "source": "calendar",
        "title": "Friend's birthday dinner — 8 PM",
        "body": "Conflicts with your 7 PM study block.",
        "priority": "important",
        "urgency_score": 60,
        "deadline": None,
        "action_required": False,
    },
    {
        "source": "gmail",
        "title": "Google STEP internship — closes Sunday",
        "body": "Mentioned in Telegram group 6 hours ago. Deadline this Sunday.",
        "priority": "opportunity",
        "urgency_score": 70,
        "deadline": None,
        "action_required": True,
    },
]
