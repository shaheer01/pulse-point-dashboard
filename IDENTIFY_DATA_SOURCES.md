# How to Identify Data Sources in Analytics

Your analytics now tracks events from multiple sources. Here's how to identify and filter them:

## 🎯 Data Sources Overview

| Source | app_name | domain | Description |
|--------|----------|--------|-------------|
| 🟢 **Production** | `photoCompressorApp` | `compressphotos.cloud` | Real users on your live website |
| 🟡 **Development** | `photoCompressorApp` | `localhost` | Testing on local machine |
| 🔵 **Simulator** | `traffic_simulator` | `simulator.local` | Traffic simulator for testing |
| ⚪ **Legacy/Sample** | `NULL` | `NULL` or various | Old sample data from init.sql |

---

## 📊 Quick View: All Sources

```sql
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
```

**Run it:**
```bash
docker exec analytics_db psql -U analytics_user -d analytics -c "SELECT CASE WHEN properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'compressphotos.cloud' THEN '🟢 Production' WHEN properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'localhost' THEN '🟡 Development' WHEN properties->>'app_name' = 'traffic_simulator' THEN '🔵 Simulator' WHEN properties->>'app_name' IS NULL THEN '⚪ Legacy/Sample' ELSE '🟣 Other' END as source, COUNT(*) as events, COUNT(DISTINCT user_id) as users FROM events GROUP BY source ORDER BY events DESC;"
```

---

## 🟢 Filter: Production Data Only

Get only real user data from compressphotos.cloud:

```sql
SELECT *
FROM events
WHERE properties->>'app_name' = 'photoCompressorApp'
  AND properties->>'domain' = 'compressphotos.cloud'
ORDER BY created_at DESC;
```

**Run it:**
```bash
docker exec analytics_db psql -U analytics_user -d analytics -c "SELECT id, event_type, page_url, country, created_at FROM events WHERE properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'compressphotos.cloud' ORDER BY created_at DESC LIMIT 20;"
```

---

## 🟡 Filter: Development Data Only

Get only local testing data:

```sql
SELECT *
FROM events
WHERE properties->>'app_name' = 'photoCompressorApp'
  AND properties->>'domain' = 'localhost'
ORDER BY created_at DESC;
```

---

## 🔵 Filter: Simulator Data Only

Get only traffic simulator events:

```sql
SELECT *
FROM events
WHERE properties->>'app_name' = 'traffic_simulator'
ORDER BY created_at DESC;
```

---

## 🧹 Clean Up Test Data

### Delete Simulator Data
```sql
DELETE FROM events WHERE properties->>'app_name' = 'traffic_simulator';
```

### Delete Legacy Sample Data
```sql
DELETE FROM events WHERE properties->>'app_name' IS NULL;
```

### Keep ONLY Production Data
```sql
DELETE FROM events
WHERE properties->>'app_name' != 'photoCompressorApp'
   OR properties->>'domain' != 'compressphotos.cloud';
```

**⚠️ Warning:** These delete operations are permanent. Always backup your data first!

---

## 📈 Production Metrics Dashboard

Create a view for production-only metrics:

```sql
CREATE VIEW production_events AS
SELECT *
FROM events
WHERE properties->>'app_name' = 'photoCompressorApp'
  AND properties->>'domain' = 'compressphotos.cloud';

-- Use the view
SELECT
    event_type,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM production_events
GROUP BY event_type
ORDER BY count DESC;
```

---

## 🔍 Image Compression Stats (Production Only)

```sql
SELECT
    COUNT(*) as total_compressions,
    AVG((properties->>'compression_ratio')::numeric) as avg_compression_ratio,
    AVG((properties->>'quality')::numeric) as avg_quality,
    SUM((properties->>'savings_bytes')::bigint) as total_bytes_saved
FROM events
WHERE properties->>'app_name' = 'photoCompressorApp'
  AND properties->>'domain' = 'compressphotos.cloud'
  AND event_type = 'image_compress';
```

---

## 📊 Daily Production Stats

```sql
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_events,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as sessions,
    COUNT(CASE WHEN event_type = 'image_compress' THEN 1 END) as compressions
FROM events
WHERE properties->>'app_name' = 'photoCompressorApp'
  AND properties->>'domain' = 'compressphotos.cloud'
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 30;
```

---

## 🛠️ Useful Commands

### Run SQL File with All Filters
```bash
docker exec -i analytics_db psql -U analytics_user -d analytics < filter-by-app-source.sql
```

### Quick Stats
```bash
./test-app-sources.sh
```

### Check Latest Production Events
```bash
docker exec analytics_db psql -U analytics_user -d analytics -c "SELECT id, event_type, properties->>'path' as page, created_at FROM events WHERE properties->>'app_name' = 'photoCompressorApp' AND properties->>'domain' = 'compressphotos.cloud' ORDER BY created_at DESC LIMIT 10;"
```

---

## 🎨 Update Dashboard to Filter by Source

To show only production data in your dashboard, update the backend query in `backend/main.py`:

```python
@app.get("/api/analytics/summary", response_model=AnalyticsSummary)
async def get_analytics_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    app_name: Optional[str] = 'photoCompressorApp',  # Add this
    domain: Optional[str] = 'compressphotos.cloud',   # Add this
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Add filters to all queries
    base_filter = and_(
        Event.created_at >= start_date,
        Event.created_at <= end_date,
        Event.properties['app_name'].astext == app_name,
        Event.properties['domain'].astext == domain
    )

    total_users = db.query(func.count(distinct(Event.user_id))).filter(
        base_filter
    ).scalar() or 0

    # ... rest of the query
```

---

## ✅ Verification Checklist

- [ ] photoCompressorApp events have `app_name = 'photoCompressorApp'`
- [ ] Production events have `domain = 'compressphotos.cloud'`
- [ ] Development events have `domain = 'localhost'`
- [ ] Simulator events have `app_name = 'traffic_simulator'`
- [ ] Can filter production data successfully
- [ ] Can clean up test data when needed

---

## 📚 Files Reference

- **SQL Queries**: `filter-by-app-source.sql`
- **Test Script**: `test-app-sources.sh`
- **Analytics Client**: `photoCompressorApp/analytics-client.js`
- **Traffic Simulator**: `simulate_traffic.py`
