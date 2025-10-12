from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict, Any
from datetime import datetime

class EventCreate(BaseModel):
    event_type: str
    user_id: str
    session_id: str
    page_url: Optional[str] = None
    country: Optional[str] = "Unknown"
    properties: Optional[Dict[str, Any]] = {}

class EventResponse(BaseModel):
    id: int
    event_type: str
    user_id: str
    session_id: str
    page_url: Optional[str]
    country: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class TrendDataPoint(BaseModel):
    date: str
    users: int

class AnalyticsSummary(BaseModel):
    total_users: int
    total_users_change: float
    event_count: int
    event_count_change: float
    conversions: int
    conversions_change: float
    new_users: int
    new_users_change: float
    trend_data: List[TrendDataPoint]

class MinuteData(BaseModel):
    minute: str
    users: int

class CountryData(BaseModel):
    country: str
    users: int

class RealtimeUsers(BaseModel):
    active_users: int
    users_by_minute: List[MinuteData]
    users_by_country: List[CountryData]

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TimeRange(BaseModel):
    start_date: Optional[str] = None
    end_date: Optional[str] = None
