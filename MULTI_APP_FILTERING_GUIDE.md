# Multi-App Filtering Guide

Your analytics dashboard now supports filtering data by specific apps/clients! This allows you to track metrics for multiple applications from a single dashboard.

---

## 🎯 Features

### ✅ Backend API Endpoints

1. **`GET /api/apps`** - List all available apps/clients
   - Returns all apps with event counts, user counts, and date ranges
   - Requires authentication

2. **`GET /api/analytics/summary?app_name=X&domain=Y`** - Filter analytics by app
   - Optional `app_name` parameter
   - Optional `domain` parameter
   - Returns filtered metrics

3. **`GET /api/analytics/realtime?app_name=X&domain=Y`** - Filter realtime data by app
   - Optional `app_name` parameter
   - Optional `domain` parameter
   - Returns filtered realtime stats

4. **`GET /api/analytics/{app_name}/summary`** - App-specific endpoint
   - Dedicated endpoint for a specific app
   - Cleaner URL structure

5. **`GET /api/analytics/{app_name}/realtime`** - App-specific realtime
   - Dedicated realtime endpoint for a specific app

### ✅ Frontend Dashboard

- **App Selector Dropdown** in the toolbar
- Select "All Apps" to view combined data
- Select specific app to view only that app's data
- Automatically refreshes when changing apps

---

## 📖 How to Use

### 1. **Access the Dashboard**

```bash
# Open in browser
open http://localhost:3000

# Login
Email: demo@analytics.com
Password: demo123
```

### 2. **Select an App**

In the dashboard toolbar, you'll see a dropdown with:
- **All Apps** - View combined data from all sources
- **photoCompressorApp (compressphotos.cloud)** - Production app data
- **photoCompressorApp (localhost)** - Development app data
- **traffic_simulator (simulator.local)** - Test data
- **Legacy Data** - Old sample data

### 3. **View Filtered Metrics**

When you select an app, all metrics update to show only that app's data:
- Total users
- Event count
- Conversions
- New users
- Trend chart
- Realtime activity

---

## 🔌 API Usage Examples

### List All Apps

```bash
# Get auth token
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@analytics.com","password":"demo123"}' \
  | jq -r '.access_token')

# Get list of apps
curl -s http://localhost:8000/api/apps \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'
```

**Response:**
```json
{
  "apps": [
    {
      "app_name": "photoCompressorApp",
      "domain": "compressphotos.cloud",
      "event_count": 150,
      "user_count": 25,
      "first_seen": "2025-10-01T10:00:00Z",
      "last_seen": "2025-10-05T06:30:00Z"
    },
    {
      "app_name": "photoCompressorApp",
      "domain": "localhost",
      "event_count": 50,
      "user_count": 5,
      "first_seen": "2025-10-04T12:00:00Z",
      "last_seen": "2025-10-05T06:30:00Z"
    }
  ]
}
```

### Get Analytics for Specific App

```bash
# Method 1: Using query parameters
curl -s "http://localhost:8000/api/analytics/summary?app_name=photoCompressorApp&domain=compressphotos.cloud" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'

# Method 2: Using dedicated endpoint
curl -s "http://localhost:8000/api/analytics/photoCompressorApp/summary?domain=compressphotos.cloud" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'
```

### Get Realtime Data for Specific App

```bash
# Method 1: Using query parameters
curl -s "http://localhost:8000/api/analytics/realtime?app_name=photoCompressorApp&domain=compressphotos.cloud" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'

# Method 2: Using dedicated endpoint
curl -s "http://localhost:8000/api/analytics/photoCompressorApp/realtime?domain=compressphotos.cloud" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'
```

---

## 🏗️ Architecture

### How It Works

1. **App Identification**
   - Each event sent to `/api/events` includes `properties.app_name` and `properties.domain`
   - These are set automatically by the `analytics-client.js`

2. **Database Filtering**
   - Backend queries filter events based on `app_name` and `domain` from JSONB properties
   - Efficient indexing on JSONB columns for fast queries

3. **Frontend Selection**
   - Dashboard fetches list of available apps on load
   - When user selects an app, all API calls include `app_name` and `domain` parameters
   - Real-time data refreshes automatically with selected filter

---

## 🎨 Customization

### Add More Apps

Simply integrate `analytics-client.js` in your new app with a unique `appName`:

```javascript
const analytics = new AnalyticsClient({
    apiUrl: 'http://localhost:8000',
    appName: 'myNewApp',  // Unique name for your app
    appVersion: '1.0.0',
    autoPageView: true
});
```

The app will automatically appear in the dropdown after sending events!

### Create Dedicated Dashboards

You can create separate dashboard instances for each app:

```javascript
// In your React app routing
<Route path="/analytics/photoCompressor" element={
  <Dashboard defaultApp="photoCompressorApp" />
} />

<Route path="/analytics/myOtherApp" element={
  <Dashboard defaultApp="myOtherApp" />
} />
```

### API-Level App Restriction

For production, you might want to restrict API access per app:

```python
# In backend/main.py

@app.get("/api/analytics/photoCompressorApp/summary")
async def get_photo_compressor_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify user has access to photoCompressorApp
    if current_user.get('app') != 'photoCompressorApp':
        raise HTTPException(status_code=403, detail="Access denied")

    return await get_analytics_summary(
        start_date=start_date,
        end_date=end_date,
        app_name="photoCompressorApp",
        domain="compressphotos.cloud",
        current_user=current_user,
        db=db
    )
```

---

## 🧪 Testing

### Test with Multiple Apps

```bash
# Run the test script
./test-app-sources.sh

# This will:
# 1. Send events from photoCompressorApp (production)
# 2. Send events from photoCompressorApp (development)
# 3. Send events from traffic_simulator
# 4. Show breakdown by app in the database
```

### Verify in UI

1. Open http://localhost:3000
2. Login
3. Check the app selector dropdown - you should see all your apps
4. Select "photoCompressorApp (compressphotos.cloud)"
5. Verify metrics show only production data
6. Select "All Apps"
7. Verify metrics show combined data

---

## 🔍 Troubleshooting

### App Not Appearing in Dropdown

**Problem:** Your app sent events but doesn't appear in the selector.

**Solution:**
1. Check that events include `app_name` in properties:
   ```sql
   SELECT properties->>'app_name', COUNT(*)
   FROM events
   GROUP BY properties->>'app_name';
   ```

2. Refresh the browser to reload the app list

3. Check browser console for errors

### Metrics Not Filtering

**Problem:** Selecting an app doesn't filter the data.

**Solution:**
1. Open browser DevTools → Network tab
2. Select an app from dropdown
3. Check the API call includes `app_name` and `domain` parameters
4. Check backend logs for any errors

### Quotes in App Names

**Problem:** App names showing as `"photoCompressorApp"` instead of `photoCompressorApp`.

**Solution:** This is handled in the frontend with `.replace(/"/g, '')`. If you see quotes in the UI, check the Dashboard.js code around line 152.

---

## 📊 Use Cases

### 1. Multi-Tenant SaaS

Track analytics for multiple clients:
- Client A's dashboard
- Client B's dashboard
- Combined overview

### 2. Multi-Product Company

Separate analytics for each product:
- Product A metrics
- Product B metrics
- Company-wide metrics

### 3. Development vs Production

Compare environments:
- Production traffic
- Staging traffic
- Development testing

### 4. A/B Testing

Track different versions:
- Version A metrics
- Version B metrics
- Combined comparison

---

## 🚀 Next Steps

1. **Add Authentication Per App**
   - Create user accounts tied to specific apps
   - Restrict API access based on user's app permissions

2. **Custom Dashboards**
   - Create app-specific dashboard layouts
   - Add app-specific metrics and charts

3. **Alerts & Notifications**
   - Set up alerts per app
   - Email notifications for app-specific thresholds

4. **Export & Reports**
   - Generate PDF reports per app
   - CSV export with app filtering

---

## 📁 Related Files

- **Backend**: `/backend/main.py` - API endpoints
- **Frontend**: `/frontend/src/components/Dashboard.js` - UI component
- **Analytics Client**: `/photoCompressorApp/analytics-client.js` - Tracking code
- **SQL Queries**: `/filter-by-app-source.sql` - Database queries
- **Test Script**: `/test-app-sources.sh` - Testing tool

---

## ✅ Summary

You now have a fully functional multi-app analytics dashboard! You can:

✅ View all apps or filter by specific app
✅ Track multiple products/clients from one dashboard
✅ Use API endpoints with app filtering
✅ Add new apps automatically
✅ Compare metrics across apps

Happy analyzing! 📊
