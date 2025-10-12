#!/bin/bash
# Clean up test/sample data to prepare for production data

echo "⚠️  WARNING: This will delete test and sample data!"
echo ""
echo "This will keep:"
echo "  ✅ photoCompressorApp production data (if any)"
echo ""
echo "This will DELETE:"
echo "  ❌ Legacy sample data (1000 events)"
echo "  ❌ traffic_simulator test data"
echo "  ❌ localhost development data"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Cleaning up test data..."
echo ""

# Delete legacy sample data (no app_name)
echo "1. Deleting legacy sample data..."
docker exec analytics_db psql -U analytics_user -d analytics -c "
DELETE FROM events
WHERE properties->>'app_name' IS NULL;
"

# Delete traffic simulator data
echo "2. Deleting traffic_simulator data..."
docker exec analytics_db psql -U analytics_user -d analytics -c "
DELETE FROM events
WHERE properties->>'app_name' LIKE '%traffic_simulator%';
"

# Delete localhost development data
echo "3. Deleting localhost development data..."
docker exec analytics_db psql -U analytics_user -d analytics -c "
DELETE FROM events
WHERE properties->>'domain' = '\"localhost\"';
"

# Delete old test events with NULL domain
echo "4. Deleting test events..."
docker exec analytics_db psql -U analytics_user -d analytics -c "
DELETE FROM events
WHERE properties->>'domain' = 'unknown'
   OR properties->>'domain' IS NULL;
"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Remaining data:"
docker exec analytics_db psql -U analytics_user -d analytics -c "
SELECT
    COALESCE(properties->>'app_name', 'NULL') as app_name,
    COALESCE(properties->>'domain', 'NULL') as domain,
    COUNT(*) as events,
    COUNT(DISTINCT user_id) as users
FROM events
GROUP BY properties->>'app_name', properties->>'domain'
ORDER BY events DESC;
"

echo ""
echo "🎯 Your dashboard is now ready for production data!"
echo "👉 Next: Connect your production website using CONNECT_PRODUCTION_WEBSITE.md"
