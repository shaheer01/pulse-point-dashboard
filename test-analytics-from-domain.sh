#!/bin/bash
# Test Analytics Integration from compressphotos.cloud domain

echo "Testing Analytics Integration for compressphotos.cloud"
echo "======================================================"
echo ""

# Test 1: Send a test pageview event
echo "1. Sending test pageview event..."
curl -X POST http://localhost:8000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pageview",
    "user_id": "test_user_123",
    "session_id": "test_session_abc",
    "page_url": "https://compressphotos.cloud/",
    "country": "United States",
    "properties": {
      "domain": "compressphotos.cloud",
      "protocol": "https:",
      "path": "/",
      "user_agent": "Test User Agent",
      "screen_resolution": "1920x1080",
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
    }
  }'
echo ""
echo ""

# Test 2: Send image compression event
echo "2. Sending test image compression event..."
curl -X POST http://localhost:8000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "image_compress",
    "user_id": "test_user_123",
    "session_id": "test_session_abc",
    "page_url": "https://compressphotos.cloud/",
    "country": "United States",
    "properties": {
      "domain": "compressphotos.cloud",
      "protocol": "https:",
      "path": "/",
      "original_size_bytes": 1048576,
      "compressed_size_bytes": 262144,
      "compression_ratio": "75.0",
      "quality": 80,
      "processing_time_ms": 1500,
      "savings_bytes": 786432
    }
  }'
echo ""
echo ""

# Test 3: Query the database for compressphotos.cloud events
echo "3. Querying database for compressphotos.cloud events..."
docker exec analytics_db psql -U analytics_user -d analytics -c \
  "SELECT id, event_type, page_url, properties->>'domain' as domain, created_at
   FROM events
   WHERE properties->>'domain' = 'compressphotos.cloud'
      OR page_url LIKE '%compressphotos.cloud%'
   ORDER BY created_at DESC
   LIMIT 10;"

echo ""
echo "======================================================"
echo "✅ Test complete! Check the results above."
echo ""
echo "To run more queries, use:"
echo "  docker exec analytics_db psql -U analytics_user -d analytics -f /path/to/verify-domain-metrics.sql"
