// Local demo data — used when user taps "Try Demo" on login screen.
// Mirrors the backend's DEMO_BRIEFING / DEMO_ITEMS so no network call is needed.

const kDemoBriefing = r"""
## Good morning.

### URGENT
- **Assignment deadline moved to tonight** — Prof. Smith updated the submission portal *(Gmail)*
- **Scholarship application closes in 4 hours** — KFAS Engineering Grant, link in email *(Gmail)*

### IMPORTANT
- Networking event tonight at 6 PM — AI & Society panel, KFAS auditorium *(Calendar)*
- Friend's birthday dinner at 8 PM — conflicts with your 7 PM study block *(Calendar)*
- New grading rubric uploaded — CS301 midterm, check LMS *(Gmail)*

### UPCOMING
- CS301 midterm — tomorrow 10 AM *(Calendar)*
- Team standup — Monday 9 AM *(Calendar)*

### YOU MAY HAVE MISSED
- Internship deadline mentioned in group chat 6 hours ago — Google STEP, closes Sunday *(Telegram)*
- Professor's office hours cancelled this week *(Gmail, unread)*

### OPPORTUNITIES
- Google STEP internship for undergraduates — deadline this Sunday *(Telegram)*
- AI research assistant position — posted by Dr. Al-Rashid *(Gmail)*
""";

const kDemoItems = [
  {
    'id': 'demo-0',
    'source': 'gmail',
    'title': 'Assignment deadline moved to tonight',
    'body': 'Prof. Smith updated the submission portal. Was due Friday.',
    'priority': 'urgent',
    'urgency_score': 95,
    'deadline': null,
    'action_required': true,
  },
  {
    'id': 'demo-1',
    'source': 'gmail',
    'title': 'Scholarship application closes in 4 hours',
    'body': 'KFAS Engineering Grant — link in email body.',
    'priority': 'urgent',
    'urgency_score': 90,
    'deadline': null,
    'action_required': true,
  },
  {
    'id': 'demo-2',
    'source': 'calendar',
    'title': 'AI & Society networking event — 6 PM tonight',
    'body': 'KFAS auditorium. Relevant to your career interests.',
    'priority': 'important',
    'urgency_score': 65,
    'deadline': null,
    'action_required': false,
  },
  {
    'id': 'demo-3',
    'source': 'calendar',
    'title': "Friend's birthday dinner — 8 PM",
    'body': 'Conflicts with your 7 PM study block.',
    'priority': 'important',
    'urgency_score': 60,
    'deadline': null,
    'action_required': false,
  },
  {
    'id': 'demo-4',
    'source': 'telegram',
    'title': 'Google STEP internship — closes Sunday',
    'body': 'Mentioned in Telegram group 6 hours ago.',
    'priority': 'missed',
    'urgency_score': 80,
    'deadline': null,
    'action_required': true,
  },
  {
    'id': 'demo-5',
    'source': 'gmail',
    'title': 'AI research assistant position — Dr. Al-Rashid',
    'body': 'Open to undergraduates. Apply before end of semester.',
    'priority': 'opportunity',
    'urgency_score': 55,
    'deadline': null,
    'action_required': false,
  },
];
