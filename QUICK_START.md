# Quick Start Guide

Get your analytics dashboard running in 5 minutes!

## Prerequisites

- Docker and Docker Compose installed on your system
- Python 3.11+ (optional, for traffic simulator)

## Step 1: Start the Application

```bash
# Navigate to project directory
cd pulsePointDashboard

# Start all services with Docker Compose
docker-compose up --build
```

Wait for all services to start. You should see:
- ✓ PostgreSQL database running
- ✓ Redis cache running
- ✓ Backend API running on port 8000
- ✓ Frontend running on port 3000

## Step 2: Access the Dashboard

1. Open your browser and go to: **http://localhost:3000**

2. Login with the demo credentials:
   ```
   Email: demo@analytics.com
   Password: demo123
   ```

3. You'll see the analytics dashboard with sample data!

## Step 3: Generate More Data (Optional)

To see real-time updates, run the traffic simulator:

```bash
# Install requests library (if not already installed)
pip install requests

# Run the simulator
python3 simulate_traffic.py
```

Choose option **1** for continuous traffic (recommended) or **2** for a quick burst of 100 events.

Watch your dashboard update in real-time!

## What You'll See

### Main Dashboard
- **4 Metric Cards**: Users, Event Count, Conversions, New Users
- **Trend Chart**: User activity over the selected time period
- **Real-time Widget**: Active users in the last 30 minutes

### Features to Try
- 🌓 Toggle dark/light mode (top right)
- 📅 Change time range (dropdown in toolbar)
- 🔄 Refresh data (refresh button)
- 🌍 View users by country (real-time widget)

## Stopping the Application

Press `Ctrl+C` in the terminal where docker-compose is running, then:

```bash
docker-compose down
```

## Troubleshooting

### Port Already in Use
If ports 3000, 8000, or 5432 are already in use, stop the conflicting services or edit `docker-compose.yml` to use different ports.

### Database Connection Issues
```bash
# Check if all containers are running
docker-compose ps

# View backend logs
docker-compose logs backend
```

### Frontend Not Loading
- Clear your browser cache
- Try accessing http://localhost:3000 in an incognito window
- Check frontend logs: `docker-compose logs frontend`

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Explore the API at http://localhost:8000/docs (FastAPI auto-generated docs)
- Customize the dashboard components in `frontend/src/components/`
- Add custom metrics in `backend/main.py`

## Need Help?

Check the main README.md for:
- Detailed API documentation
- Development setup
- Production deployment guide
- Customization options

Enjoy your analytics dashboard! 📊
