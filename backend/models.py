from sqlalchemy import Column, Integer, String, DateTime, JSON, Index, Float
from sqlalchemy.sql import func
from database import Base
from datetime import datetime

class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    event_type = Column(String, index=True, nullable=False)  # 'pageview', 'click', 'conversion', etc.
    user_id = Column(String, index=True, nullable=False)
    session_id = Column(String, index=True, nullable=False)
    page_url = Column(String)
    country = Column(String, index=True)
    properties = Column(JSON, default={})
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    __table_args__ = (
        Index('idx_event_user_created', 'user_id', 'created_at'),
        Index('idx_event_type_created', 'event_type', 'created_at'),
    )

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, unique=True, index=True, nullable=False)
    first_seen = Column(DateTime(timezone=True), server_default=func.now())
    last_seen = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    country = Column(String)
    properties = Column(JSON, default={})

class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(String, index=True, nullable=False)
    start_time = Column(DateTime(timezone=True), server_default=func.now())
    last_activity = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    country = Column(String)
    properties = Column(JSON, default={})

    __table_args__ = (
        Index('idx_session_user_activity', 'user_id', 'last_activity'),
    )
