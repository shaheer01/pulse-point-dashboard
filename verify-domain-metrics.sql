-- SQL Queries to Verify Metrics from compressphotos.cloud
-- Run these queries to verify analytics from your domain

-- 1. Count events by domain
SELECT
    properties->>'domain' as domain,
    COUNT(*) as event_count
FROM events
WHERE properties->>'domain' IS NOT NULL
GROUP BY properties->>'domain'
ORDER BY event_count DESC;

-- 2. Get all events from compressphotos.cloud
SELECT
    id,
    event_type,
    page_url,
    properties->>'domain' as domain,
    properties->>'path' as path,
    country,
    created_at
FROM events
WHERE properties->>'domain' = 'compressphotos.cloud'
   OR page_url LIKE '%compressphotos.cloud%'
ORDER BY created_at DESC
LIMIT 20;

-- 3. Event types breakdown for compressphotos.cloud
SELECT
    event_type,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM events
WHERE properties->>'domain' = 'compressphotos.cloud'
   OR page_url LIKE '%compressphotos.cloud%'
GROUP BY event_type
ORDER BY count DESC;

-- 4. Most visited pages on compressphotos.cloud
SELECT
    properties->>'path' as path,
    page_url,
    COUNT(*) as views,
    COUNT(DISTINCT user_id) as unique_visitors
FROM events
WHERE (properties->>'domain' = 'compressphotos.cloud'
   OR page_url LIKE '%compressphotos.cloud%')
   AND event_type = 'pageview'
GROUP BY properties->>'path', page_url
ORDER BY views DESC
LIMIT 10;

-- 5. User activity timeline for compressphotos.cloud
SELECT
    DATE(created_at) as date,
    COUNT(*) as events,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as sessions
FROM events
WHERE properties->>'domain' = 'compressphotos.cloud'
   OR page_url LIKE '%compressphotos.cloud%'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- 6. Image compression events (specific to your app)
SELECT
    event_type,
    properties->>'compression_ratio' as compression_ratio,
    properties->>'quality' as quality,
    properties->>'savings_bytes' as bytes_saved,
    created_at
FROM events
WHERE (properties->>'domain' = 'compressphotos.cloud'
   OR page_url LIKE '%compressphotos.cloud%')
   AND event_type IN ('image_compress', 'image_upload', 'image_download')
ORDER BY created_at DESC
LIMIT 10;

-- 7. Conversion tracking
SELECT
    COUNT(*) as total_conversions,
    properties->>'subscription_type' as subscription_type,
    SUM((properties->>'amount')::numeric) as total_revenue
FROM events
WHERE (properties->>'domain' = 'compressphotos.cloud'
   OR page_url LIKE '%compressphotos.cloud%')
   AND event_type = 'conversion'
GROUP BY properties->>'subscription_type';

-- 8. Countries of users visiting compressphotos.cloud
SELECT
    country,
    COUNT(*) as events,
    COUNT(DISTINCT user_id) as unique_users
FROM events
WHERE properties->>'domain' = 'compressphotos.cloud'
   OR page_url LIKE '%compressphotos.cloud%'
GROUP BY country
ORDER BY events DESC
LIMIT 10;
