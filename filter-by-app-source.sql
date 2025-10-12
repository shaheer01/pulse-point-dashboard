-- SQL Queries to Filter Events by App Source
-- This helps distinguish between photoCompressorApp, simulator, test data, and other sources

-- ==========================================
-- 1. VIEW ALL APP SOURCES
-- ==========================================
SELECT
    properties->>'app_name' as app_name,
    properties->>'app_version' as version,
    properties->>'domain' as domain,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    MIN(created_at) as first_seen,
    MAX(created_at) as last_seen
FROM events
GROUP BY properties->>'app_name', properties->>'app_version', properties->>'domain'
ORDER BY event_count DESC;

-- ==========================================
-- 2. FILTER: photoCompressorApp ONLY
-- ==========================================
SELECT
    id,
    event_type,
    page_url,
    properties->>'domain' as domain,
    country,
    created_at
FROM events
WHERE properties->>'app_name' = 'photoCompressorApp'
ORDER BY created_at DESC
LIMIT 20;

-- ==========================================
-- 3. FILTER: Traffic Simulator ONLY
-- ==========================================
SELECT
    id,
    event_type,
    page_url,
    properties->>'domain' as domain,
    country,
    created_at
FROM events
WHERE properties->>'app_name' = 'traffic_simulator'
ORDER BY created_at DESC
LIMIT 20;

-- ==========================================
-- 4. FILTER: Sample/Test Data (no app_name)
-- ==========================================
SELECT
    id,
    event_type,
    page_url,
    country,
    created_at
FROM events
WHERE properties->>'app_name' IS NULL
ORDER BY created_at DESC
LIMIT 20;

-- ==========================================
-- 5. EVENT BREAKDOWN BY APP
-- ==========================================
SELECT
    properties->>'app_name' as app_name,
    event_type,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM events
GROUP BY properties->>'app_name', event_type
ORDER BY properties->>'app_name', count DESC;

-- ==========================================
-- 6. photoCompressorApp SPECIFIC EVENTS
-- ==========================================
-- Image compression events
SELECT
    event_type,
    properties->>'compression_ratio' as compression_ratio,
    properties->>'quality' as quality,
    properties->>'savings_bytes' as bytes_saved,
    properties->>'original_size_bytes' as original_size,
    properties->>'compressed_size_bytes' as compressed_size,
    created_at
FROM events
WHERE properties->>'app_name' = 'photoCompressorApp'
  AND event_type IN ('image_compress', 'image_upload', 'image_download')
ORDER BY created_at DESC
LIMIT 20;

-- ==========================================
-- 7. IDENTIFY ALL UNIQUE SOURCES
-- ==========================================
SELECT DISTINCT
    COALESCE(properties->>'app_name', 'unknown/legacy') as source,
    COALESCE(properties->>'domain', page_url) as identifier,
    COUNT(*) OVER (PARTITION BY properties->>'app_name') as total_events
FROM events
ORDER BY total_events DESC;

-- ==========================================
-- 8. REAL-TIME: Last 30 Minutes by App
-- ==========================================
SELECT
    properties->>'app_name' as app_name,
    COUNT(*) as events_last_30min,
    COUNT(DISTINCT user_id) as active_users
FROM events
WHERE created_at >= NOW() - INTERVAL '30 minutes'
GROUP BY properties->>'app_name'
ORDER BY events_last_30min DESC;

-- ==========================================
-- 9. PRODUCTION vs TEST DATA
-- ==========================================
SELECT
    CASE
        WHEN properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'compressphotos.cloud' THEN 'Production'
        WHEN properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'localhost' THEN 'Development'
        WHEN properties->>'app_name' = 'traffic_simulator' THEN 'Simulator'
        WHEN properties->>'app_name' IS NULL THEN 'Legacy/Sample Data'
        ELSE 'Other'
    END as data_source,
    COUNT(*) as events,
    COUNT(DISTINCT user_id) as users,
    MIN(created_at) as first_event,
    MAX(created_at) as last_event
FROM events
GROUP BY data_source
ORDER BY events DESC;

-- ==========================================
-- 10. DELETE TEST/SIMULATOR DATA (USE WITH CAUTION!)
-- ==========================================
-- Uncomment to delete simulator data:
-- DELETE FROM events WHERE properties->>'app_name' = 'traffic_simulator';

-- Uncomment to delete legacy sample data:
-- DELETE FROM events WHERE properties->>'app_name' IS NULL;

-- Uncomment to keep only production photoCompressorApp data:
-- DELETE FROM events
-- WHERE properties->>'app_name' != 'photoCompressorApp'
--    OR properties->>'domain' != 'compressphotos.cloud';
