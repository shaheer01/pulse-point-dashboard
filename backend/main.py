from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime, timedelta
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, distinct
import redis
import json

from database import get_db, engine, Base
from models import Event, User, Session as UserSession
from schemas import (
    EventCreate, EventResponse, AnalyticsSummary,
    RealtimeUsers, UserLogin, Token, TimeRange
)
from auth import create_access_token, verify_token
import os

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Analytics Dashboard API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://frontend:3000",
        "http://localhost",
        "http://localhost:80",
        "http://localhost:8080",
        "https://compressphotos.cloud",
        "http://compressphotos.cloud",
        "https://www.compressphotos.cloud",
        "http://www.compressphotos.cloud",
        # Allow ngrok URLs (update this when ngrok URL changes)
        "https://054d9472cc3f.ngrok-free.app",
        "http://054d9472cc3f.ngrok-free.app",
        "https://883f1947c43d.ngrok-free.app",
        "http://883f1947c43d.ngrok-free.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Redis connection
redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379/0"))

security = HTTPBearer()

# Authentication dependency
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    return payload

@app.get("/")
async def root():
    return {"message": "Analytics Dashboard API", "version": "1.0.0"}

@app.get("/api/apps")
async def get_available_apps(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get list of all available apps/clients"""
    from sqlalchemy import cast, Text

    apps = db.query(
        func.coalesce(cast(Event.properties['app_name'], Text), 'legacy').label('app_name'),
        func.coalesce(cast(Event.properties['domain'], Text), 'unknown').label('domain'),
        func.count(Event.id).label('event_count'),
        func.count(distinct(Event.user_id)).label('user_count'),
        func.min(Event.created_at).label('first_seen'),
        func.max(Event.created_at).label('last_seen')
    ).group_by(
        cast(Event.properties['app_name'], Text),
        cast(Event.properties['domain'], Text)
    ).all()

    return {
        "apps": [
            {
                "app_name": app.app_name,
                "domain": app.domain,
                "event_count": app.event_count,
                "user_count": app.user_count,
                "first_seen": app.first_seen,
                "last_seen": app.last_seen
            }
            for app in apps
        ]
    }

@app.post("/api/auth/login", response_model=Token)
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    # For demo purposes - in production, verify against database with hashed passwords
    if user_data.email == "demo@analytics.com" and user_data.password == "demo123":
        access_token = create_access_token(data={"sub": user_data.email})
        return {"access_token": access_token, "token_type": "bearer"}

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect email or password"
    )

@app.options("/api/events")
async def events_options():
    """Handle CORS preflight for events endpoint"""
    return {"message": "OK"}

@app.post("/api/events", response_model=EventResponse)
async def track_event(event: EventCreate, db: Session = Depends(get_db)):
    """Track a new event"""
    # Create event record
    db_event = Event(
        event_type=event.event_type,
        user_id=event.user_id,
        session_id=event.session_id,
        page_url=event.page_url,
        country=event.country,
        properties=event.properties or {}
    )
    db.add(db_event)

    # Update or create session
    session = db.query(UserSession).filter(
        UserSession.session_id == event.session_id
    ).first()

    if not session:
        session = UserSession(
            session_id=event.session_id,
            user_id=event.user_id,
            start_time=datetime.utcnow(),
            last_activity=datetime.utcnow(),
            country=event.country
        )
        db.add(session)
    else:
        session.last_activity = datetime.utcnow()
        # Update country if it was Unknown and now we have a real country
        if session.country == "Unknown" and event.country != "Unknown":
            session.country = event.country

    db.commit()
    db.refresh(db_event)

    # Store in Redis for real-time tracking
    redis_key = f"realtime:{datetime.utcnow().strftime('%Y-%m-%d:%H:%M')}"
    redis_client.hincrby(redis_key, "events", 1)
    redis_client.hincrby(f"country:{event.country}", "count", 1)
    redis_client.expire(redis_key, 3600)  # Expire after 1 hour

    return db_event

@app.get("/api/analytics/summary", response_model=AnalyticsSummary)
async def get_analytics_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    app_name: Optional[str] = None,
    domain: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get analytics summary for dashboard (all apps or filtered by app_name/domain)"""
    # Default to last 7 days if no dates provided
    if not end_date:
        end_date = datetime.utcnow()
    else:
        end_date = datetime.fromisoformat(end_date.replace('Z', '+00:00'))

    if not start_date:
        start_date = end_date - timedelta(days=7)
    else:
        start_date = datetime.fromisoformat(start_date.replace('Z', '+00:00'))

    # Calculate previous period for comparison
    period_length = (end_date - start_date).days
    prev_start = start_date - timedelta(days=period_length)
    prev_end = start_date

    # Build base filter
    def build_filter(start, end):
        from sqlalchemy import cast, Text
        filters = [Event.created_at >= start, Event.created_at <= end]
        if app_name:
            filters.append(cast(Event.properties['app_name'], Text) == app_name)
        if domain:
            filters.append(cast(Event.properties['domain'], Text) == domain)
        return and_(*filters)

    current_filter = build_filter(start_date, end_date)
    prev_filter = build_filter(prev_start, prev_end)

    # Current period metrics
    total_users = db.query(func.count(distinct(Event.user_id))).filter(
        current_filter
    ).scalar() or 0

    event_count = db.query(func.count(Event.id)).filter(
        current_filter
    ).scalar() or 0

    conversion_filter = build_filter(start_date, end_date)
    conversions = db.query(func.count(Event.id)).filter(
        and_(conversion_filter, Event.event_type == 'conversion')
    ).scalar() or 0

    # New users (first event in this period)
    # Build subquery for new users with app/domain filter
    from sqlalchemy import cast, Text
    new_user_subquery = db.query(Event.user_id)
    new_user_filters = [Event.created_at >= start_date]
    if app_name:
        new_user_filters.append(cast(Event.properties['app_name'], Text) == app_name)
    if domain:
        new_user_filters.append(cast(Event.properties['domain'], Text) == domain)

    new_user_subquery = new_user_subquery.filter(and_(*new_user_filters)).group_by(Event.user_id).having(
        func.min(Event.created_at) >= start_date
    )

    new_users = db.query(func.count(distinct(Event.user_id))).filter(
        and_(
            current_filter,
            Event.user_id.in_(new_user_subquery)
        )
    ).scalar() or 0

    # Previous period metrics for comparison
    prev_total_users = db.query(func.count(distinct(Event.user_id))).filter(
        prev_filter
    ).scalar() or 0

    prev_event_count = db.query(func.count(Event.id)).filter(
        prev_filter
    ).scalar() or 0

    prev_conversion_filter = build_filter(prev_start, prev_end)
    prev_conversions = db.query(func.count(Event.id)).filter(
        and_(prev_conversion_filter, Event.event_type == 'conversion')
    ).scalar() or 0

    # Previous period new users with app/domain filter
    prev_new_user_subquery = db.query(Event.user_id)
    prev_new_user_filters = [Event.created_at >= prev_start]
    if app_name:
        prev_new_user_filters.append(cast(Event.properties['app_name'], Text) == app_name)
    if domain:
        prev_new_user_filters.append(cast(Event.properties['domain'], Text) == domain)

    prev_new_user_subquery = prev_new_user_subquery.filter(and_(*prev_new_user_filters)).group_by(Event.user_id).having(
        func.min(Event.created_at) >= prev_start
    )

    prev_new_users = db.query(func.count(distinct(Event.user_id))).filter(
        and_(
            prev_filter,
            Event.user_id.in_(prev_new_user_subquery)
        )
    ).scalar() or 0

    # Calculate percentage changes
    def calc_change(current, previous):
        if previous == 0:
            return 100.0 if current > 0 else 0.0
        return round(((current - previous) / previous) * 100, 1)

    # Get trend data (daily aggregates)
    trend_data = []
    current_date = start_date
    while current_date <= end_date:
        next_date = current_date + timedelta(days=1)
        daily_filter = build_filter(current_date, next_date)
        daily_users = db.query(func.count(distinct(Event.user_id))).filter(
            daily_filter
        ).scalar() or 0

        trend_data.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "users": daily_users
        })
        current_date = next_date

    return {
        "total_users": total_users,
        "total_users_change": calc_change(total_users, prev_total_users),
        "event_count": event_count,
        "event_count_change": calc_change(event_count, prev_event_count),
        "conversions": conversions,
        "conversions_change": calc_change(conversions, prev_conversions),
        "new_users": new_users,
        "new_users_change": calc_change(new_users, prev_new_users),
        "trend_data": trend_data
    }

@app.get("/api/analytics/{app_name}/summary", response_model=AnalyticsSummary)
async def get_app_specific_summary(
    app_name: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    domain: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get analytics summary for a specific app"""
    return await get_analytics_summary(
        start_date=start_date,
        end_date=end_date,
        app_name=app_name,
        domain=domain,
        current_user=current_user,
        db=db
    )

@app.get("/api/analytics/{app_name}/realtime", response_model=RealtimeUsers)
async def get_app_specific_realtime(
    app_name: str,
    domain: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get real-time analytics for a specific app"""
    return await get_realtime_users(
        app_name=app_name,
        domain=domain,
        current_user=current_user,
        db=db
    )

@app.get("/api/analytics/realtime", response_model=RealtimeUsers)
async def get_realtime_users(
    app_name: Optional[str] = None,
    domain: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get real-time user activity (last 30 minutes) - all apps or filtered by app_name/domain"""
    thirty_min_ago = datetime.utcnow() - timedelta(minutes=30)

    # Build filter for app/domain
    def build_event_filter(*time_filters):
        from sqlalchemy import cast, Text
        filters = list(time_filters)
        if app_name:
            filters.append(cast(Event.properties['app_name'], Text) == app_name)
        if domain:
            filters.append(cast(Event.properties['domain'], Text) == domain)
        return and_(*filters)

    # Get active sessions in last 30 minutes
    session_query = db.query(UserSession).filter(
        UserSession.last_activity >= thirty_min_ago
    )
    active_sessions = session_query.all()

    active_users_count = len(set([s.user_id for s in active_sessions]))

    # Users by minute (last 30 minutes)
    users_by_minute = []
    for i in range(30):
        minute_time = datetime.utcnow() - timedelta(minutes=29-i)
        minute_start = minute_time.replace(second=0, microsecond=0)
        minute_end = minute_start + timedelta(minutes=1)

        minute_filter = build_event_filter(
            Event.created_at >= minute_start,
            Event.created_at < minute_end
        )
        minute_users = db.query(func.count(distinct(Event.user_id))).filter(
            minute_filter
        ).scalar() or 0

        users_by_minute.append({
            "minute": minute_start.strftime("%H:%M"),
            "users": minute_users
        })

    # Users by country
    users_by_country = []
    country_data = db.query(
        UserSession.country,
        func.count(distinct(UserSession.user_id)).label('user_count')
    ).filter(
        UserSession.last_activity >= thirty_min_ago
    ).group_by(UserSession.country).all()

    for country, count in country_data:
        users_by_country.append({
            "country": country or "Unknown",
            "users": count
        })

    # Sort by user count descending
    users_by_country.sort(key=lambda x: x["users"], reverse=True)

    return {
        "active_users": active_users_count,
        "users_by_minute": users_by_minute,
        "users_by_country": users_by_country[:10]  # Top 10 countries
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
