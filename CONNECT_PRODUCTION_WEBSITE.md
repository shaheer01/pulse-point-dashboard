# Connecting Your Production Website to Analytics

Currently, your dashboard is showing **sample/test data**, NOT real data from https://compressphotos.cloud.

Here's how to connect your production website to start tracking real users.

---

## 🔍 Current Situation

**Database Check:**
```
photoCompressorApp (compressphotos.cloud): 1 event (test only)
Legacy sample data: 1000 events (fake data)
```

**What you're seeing in the dashboard:** The 77 new users is from legacy sample data, not real visitors.

---

## ✅ Solution: 3 Steps

### **Step 1: Make Analytics Backend Publicly Accessible**

Your analytics backend is running on `localhost:8000`, which your production website can't reach.

#### **Option A: Quick Testing with Ngrok (5 minutes)**

```bash
# 1. Install ngrok
brew install ngrok

# 2. Expose your local analytics backend
ngrok http 8000

# You'll see output like:
# Forwarding: https://abc123.ngrok-free.app -> http://localhost:8000
# Copy this URL ☝️
```

**Pros:** Quick, no deployment needed
**Cons:** Temporary URL, requires your laptop to be running

#### **Option B: Deploy to Cloud (Recommended for Production)**

Deploy the analytics backend to:
- **Same server as compressphotos.cloud**
- **Separate server** (e.g., DigitalOcean, AWS, etc.)
- **Netlify/Vercel backend** (if using serverless)

Example using Docker on your server:
```bash
# SSH into your server
ssh user@your-server.com

# Clone the analytics repo
git clone [your-repo] pulse-point-dashboard
cd pulse-point-dashboard

# Start services
docker-compose up -d

# Analytics will be available at:
# http://your-server.com:8000
```

Then set up a subdomain:
```
analytics.compressphotos.cloud → your-server.com:8000
```

---

### **Step 2: Update photoCompressorApp Config**

Edit `/Users/shaheer.m/Downloads/PersonalRepo/photoCompressorApp/config.js`:

```javascript
// Production configuration (when deployed)
if (window.location.hostname === 'compressphotos.cloud' ||
    window.location.hostname === 'www.compressphotos.cloud') {

    // OPTION A: Using ngrok (testing)
    CONFIG.analyticsApiUrl = 'https://YOUR-NGROK-URL.ngrok-free.app';

    // OPTION B: Using deployed backend (production)
    // CONFIG.analyticsApiUrl = 'https://analytics.compressphotos.cloud';

    CONFIG.backendApiUrl = 'https://api.compressphotos.cloud';
    CONFIG.analyticsDebug = false;
    CONFIG.analyticsEnabled = true;
    CONFIG.environment = 'production';
}
```

**Replace `YOUR-NGROK-URL` with your actual ngrok URL!**

---

### **Step 3: Deploy Updated Config to Production**

Push the updated `config.js` to your production website:

```bash
cd /Users/shaheer.m/Downloads/PersonalRepo/photoCompressorApp

# If using Netlify
netlify deploy --prod

# If using Git deployment
git add config.js
git commit -m "Connect to analytics backend"
git push origin main

# If using manual upload
# Upload config.js to your server
```

---

## 🧪 Test It's Working

### **1. Visit Your Production Website**

```bash
open https://compressphotos.cloud
```

### **2. Open Browser Console (F12)**

You should see:
```
[Analytics] Analytics Client initialized {userId: "user_xxx", sessionId: "session_xxx"}
[Analytics] Tracking event: {event_type: "pageview", ...}
[Analytics] Event sent successfully: pageview
```

### **3. Check Database**

```bash
docker exec analytics_db psql -U analytics_user -d analytics -c "
SELECT
    properties->>'app_name' as app,
    properties->>'domain' as domain,
    COUNT(*) as events,
    MAX(created_at) as last_event
FROM events
WHERE properties->>'domain' LIKE '%compressphotos.cloud%'
GROUP BY app, domain;
"
```

You should see increasing event counts!

### **4. Refresh Dashboard**

```bash
open http://localhost:3000
```

Select **"photoCompressorApp (compressphotos.cloud)"** from the dropdown.

You should now see REAL data from your production website! 🎉

---

## 🚨 Troubleshooting

### **Issue 1: CORS Error in Browser Console**

```
Access to fetch at 'https://your-ngrok-url...' from origin 'https://compressphotos.cloud'
has been blocked by CORS policy
```

**Fix:** Add your production domain to CORS whitelist in `backend/main.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://frontend:3000",
        "https://compressphotos.cloud",
        "https://www.compressphotos.cloud",  # ✅ Add this
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

Then restart backend:
```bash
docker-compose restart backend
```

### **Issue 2: Events Not Appearing**

**Check 1:** Browser console - any errors?
**Check 2:** Network tab - are requests being sent?
**Check 3:** Backend logs:
```bash
docker-compose logs backend | tail -20
```

**Check 4:** Is analytics enabled?
```javascript
// In browser console on compressphotos.cloud
console.log(window.APP_CONFIG.analyticsEnabled);
// Should be: true
console.log(window.APP_CONFIG.analyticsApiUrl);
// Should be: your ngrok/production URL
```

### **Issue 3: Ngrok Connection Refused**

Make sure your local analytics backend is running:
```bash
docker-compose ps
# All containers should be "running"
```

Make sure ngrok is pointing to the correct port:
```bash
ngrok http 8000
```

---

## 📊 What You'll See

Once connected, your dashboard will show:

✅ **Real pageviews** from actual visitors
✅ **Image compressions** when users compress photos
✅ **Image downloads** when users download results
✅ **User countries** from real geographic data
✅ **Active users** in real-time

---

## 🔒 Security Considerations

### **For Production Deployment:**

1. **Use HTTPS** - Never send analytics over HTTP in production
2. **Rate Limiting** - Add rate limiting to prevent abuse
3. **Authentication** - Consider API keys for event submission
4. **Data Privacy** - Ensure GDPR/privacy compliance

Example rate limiting (add to `backend/main.py`):
```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/api/events")
@limiter.limit("100/minute")  # Max 100 events per minute per IP
async def track_event(event: EventCreate, db: Session = Depends(get_db)):
    # ... existing code
```

---

## 🎯 Next Steps

1. **Start with Ngrok** - Get it working quickly
2. **Deploy to Production** - Set up proper hosting
3. **Monitor Data** - Watch your dashboard fill with real data
4. **Add More Tracking** - Track specific user actions
5. **Set Up Alerts** - Get notified of important metrics

---

## 📁 Files to Update

- `photoCompressorApp/config.js` - Line 33 (analytics URL)
- `pulse-point-dashboard/backend/main.py` - CORS settings
- Deploy both to production

---

## ✅ Checklist

- [ ] Analytics backend is publicly accessible (ngrok or deployed)
- [ ] `config.js` updated with correct analytics URL
- [ ] Updated config deployed to production website
- [ ] CORS configured to allow production domain
- [ ] Tested: Browser console shows analytics events
- [ ] Verified: Database shows new events from production
- [ ] Confirmed: Dashboard shows real production data

---

## 🆘 Still Not Working?

Run this diagnostic script:

```bash
# On production website, open browser console and run:
fetch(window.APP_CONFIG.analyticsApiUrl + '/api/events', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    event_type: 'test',
    user_id: 'test_user',
    session_id: 'test_session',
    page_url: window.location.href,
    country: 'Unknown',
    properties: {
      app_name: 'photoCompressorApp',
      domain: window.location.hostname,
      test: true
    }
  })
})
.then(r => r.json())
.then(d => console.log('✅ Analytics working!', d))
.catch(e => console.error('❌ Analytics failed:', e));
```

If this works, you'll see `✅ Analytics working!` in the console.

---

Need help? Check the backend logs and browser console for specific error messages.
