from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class GoogleAuthRequest(BaseModel):
    code: str
    redirect_uri: str


class UserProfile(BaseModel):
    id: str
    email: str
    name: Optional[str] = None
    user_type: str = "student"


class PriorityItem(BaseModel):
    id: str
    source: str           # gmail | calendar | telegram | pdf
    title: str
    body: Optional[str] = None
    priority: str         # urgent | important | upcoming | opportunity | missed
    urgency_score: int = 0
    deadline: Optional[datetime] = None
    action_required: bool = False


class BriefingResponse(BaseModel):
    content: str          # AI-generated markdown
    items: list[PriorityItem]
    generated_at: datetime
    from_cache: bool = False


class RefreshRequest(BaseModel):
    force: bool = False
