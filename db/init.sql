-- Initialize analytics database

-- Create events table
CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    page_url TEXT,
    country VARCHAR(100),
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    country VARCHAR(100),
    properties JSONB DEFAULT '{}'
);

-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    country VARCHAR(100),
    properties JSONB DEFAULT '{}'
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_events_user_id ON events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_session_id ON events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_event_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at);
CREATE INDEX IF NOT EXISTS idx_events_country ON events(country);
CREATE INDEX IF NOT EXISTS idx_events_user_created ON events(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_events_type_created ON events(event_type, created_at);

CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_last_activity ON sessions(last_activity);
CREATE INDEX IF NOT EXISTS idx_sessions_user_activity ON sessions(user_id, last_activity);

-- Insert sample data for demonstration
INSERT INTO events (event_type, user_id, session_id, page_url, country, created_at)
SELECT
    CASE (random() * 4)::int
        WHEN 0 THEN 'pageview'
        WHEN 1 THEN 'click'
        WHEN 2 THEN 'conversion'
        ELSE 'engagement'
    END,
    'user_' || (random() * 100)::int,
    'session_' || (random() * 50)::int,
    '/page/' || (random() * 10)::int,
    CASE (random() * 5)::int
        WHEN 0 THEN 'United States'
        WHEN 1 THEN 'United Kingdom'
        WHEN 2 THEN 'Canada'
        WHEN 3 THEN 'Germany'
        ELSE 'France'
    END,
    CURRENT_TIMESTAMP - (random() * interval '7 days')
FROM generate_series(1, 1000);

-- Update sessions based on events
INSERT INTO sessions (session_id, user_id, start_time, last_activity, country)
SELECT DISTINCT ON (session_id)
    session_id,
    user_id,
    MIN(created_at) OVER (PARTITION BY session_id),
    MAX(created_at) OVER (PARTITION BY session_id),
    country
FROM events
ON CONFLICT (session_id) DO NOTHING;

-- Update users based on events
INSERT INTO users (user_id, first_seen, last_seen, country)
SELECT DISTINCT ON (user_id)
    user_id,
    MIN(created_at) OVER (PARTITION BY user_id),
    MAX(created_at) OVER (PARTITION BY user_id),
    country
FROM events
ON CONFLICT (user_id) DO NOTHING;
