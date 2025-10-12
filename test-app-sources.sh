#!/bin/bash
# Test script to demonstrate different app sources

echo "Testing Different App Sources"
echo "======================================================"
echo ""

# 1. Send event from photoCompressorApp (production)
echo "1. Sending event from photoCompressorApp (PRODUCTION)..."
curl -s -X POST http://localhost:8000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "image_compress",
    "user_id": "prod_user_001",
    "session_id": "prod_session_001",
    "page_url": "https://compressphotos.cloud/",
    "country": "United States",
    "properties": {
      "app_name": "photoCompressorApp",
      "app_version": "1.0.0",
      "domain": "compressphotos.cloud",
      "protocol": "https:",
      "path": "/",
      "compression_ratio": "75.0",
      "quality": 80
    }
  }' | jq -r '.event_type + " - " + .properties.app_name'

# 2. Send event from photoCompressorApp (development)
echo "2. Sending event from photoCompressorApp (DEVELOPMENT)..."
curl -s -X POST http://localhost:8000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pageview",
    "user_id": "dev_user_001",
    "session_id": "dev_session_001",
    "page_url": "http://localhost:8080/",
    "country": "United States",
    "properties": {
      "app_name": "photoCompressorApp",
      "app_version": "1.0.0",
      "domain": "localhost",
      "protocol": "http:",
      "path": "/"
    }
  }' | jq -r '.event_type + " - " + .properties.app_name'

# 3. Send event from traffic simulator
echo "3. Sending event from traffic_simulator..."
curl -s -X POST http://localhost:8000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pageview",
    "user_id": "sim_user_001",
    "session_id": "sim_session_001",
    "page_url": "/test",
    "country": "Canada",
    "properties": {
      "app_name": "traffic_simulator",
      "app_version": "1.0.0",
      "domain": "simulator.local",
      "user_agent": "Mozilla/5.0 (Analytics Simulator)"
    }
  }' | jq -r '.event_type + " - " + .properties.app_name'

echo ""
echo "======================================================"
echo "Events sent! Now let's identify them..."
echo ""

# Query 1: View all app sources
echo "📊 ALL APP SOURCES:"
docker exec analytics_db psql -U analytics_user -d analytics -c "
SELECT
    COALESCE(properties->>'app_name', 'legacy/sample') as app_name,
    properties->>'domain' as domain,
    COUNT(*) as events,
    COUNT(DISTINCT user_id) as users
FROM events
GROUP BY properties->>'app_name', properties->>'domain'
ORDER BY events DESC;
"

echo ""
echo "======================================================"
echo "🎯 PRODUCTION vs DEVELOPMENT vs TEST:"
docker exec analytics_db psql -U analytics_user -d analytics -c "
SELECT
    CASE
        WHEN properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'compressphotos.cloud' THEN '🟢 Production'
        WHEN properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'localhost' THEN '🟡 Development'
        WHEN properties->>'app_name' = 'traffic_simulator' THEN '🔵 Simulator'
        WHEN properties->>'app_name' IS NULL THEN '⚪ Legacy/Sample'
        ELSE '🟣 Other'
    END as source,
    COUNT(*) as events,
    COUNT(DISTINCT user_id) as users
FROM events
GROUP BY source
ORDER BY events DESC;
"

echo ""
echo "======================================================"
echo "✅ Done! Use these queries to filter by app source."
