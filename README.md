# Analytics Dashboard

A complete website analytics platform similar to Google Analytics, built with React, FastAPI, PostgreSQL, and Docker. Features real-time user tracking, event analytics, and a modern, responsive dashboard.

![Analytics Dashboard](https://img.shields.io/badge/Status-Production%20Ready-green)

## Features

- **Real-time Analytics**: Track active users, events, and conversions in real-time
- **Metrics Dashboard**: Display key metrics including users, event count, conversions, and new users
- **Trend Analysis**: Visualize user activity trends over customizable time periods
- **Geographic Insights**: View users by country with real-time breakdowns
- **Event Tracking**: Comprehensive event ingestion and storage system
- **JWT Authentication**: Secure API access with token-based authentication
- **Dark Mode**: Built-in dark/light theme switching
- **Responsive Design**: Clean, modern UI that works on all devices
- **Docker Support**: Fully containerized with Docker Compose for easy deployment

## Tech Stack

### Frontend
- **React 18** with Hooks
- **Material-UI (MUI)** for modern, clean components
- **Chart.js** & **react-chartjs-2** for data visualization
- **Axios** for API communication
- **React Router** for navigation

### Backend
- **FastAPI** (Python) - High-performance REST API
- **PostgreSQL** - Robust relational database
- **Redis** - Real-time data caching
- **SQLAlchemy** - ORM for database operations
- **JWT** - Secure authentication

### Infrastructure
- **Docker** & **Docker Compose** - Container orchestration
- **Nginx** (production-ready setup included)

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Python 3.11+ (for running traffic simulator outside Docker)
- Node.js 18+ (for local frontend development)

### 1. Clone and Setup

```bash
cd pulsePointDashboard
```

### 2. Start the Application

```bash
docker-compose up --build
```

This will start:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 3. Access the Dashboard

1. Open http://localhost:3000 in your browser
2. Login with demo credentials:
   - **Email**: `demo@analytics.com`
   - **Password**: `demo123`

### 4. Generate Sample Traffic (Optional)

Run the traffic simulator to populate your dashboard with data:

```bash
# Install requests library if needed
pip install requests

# Run the simulator
python3 simulate_traffic.py
```

Choose from:
- **Continuous traffic**: Steady stream of events (default 10/min)
- **Burst mode**: Send 100 events quickly
- **Custom rate**: Specify your own events per minute

## Project Structure

```
pulsePointDashboard/
├── backend/
│   ├── main.py              # FastAPI application
│   ├── models.py            # SQLAlchemy database models
│   ├── schemas.py           # Pydantic schemas
│   ├── auth.py              # JWT authentication
│   ├── database.py          # Database configuration
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard.js       # Main dashboard
│   │   │   ├── Login.js           # Login page
│   │   │   ├── MetricCard.js      # Metric display card
│   │   │   ├── TrendChart.js      # Trend visualization
│   │   │   └── RealtimeWidget.js  # Real-time user widget
│   │   ├── App.js
│   │   └── index.js
│   ├── package.json
│   └── Dockerfile
├── db/
│   └── init.sql             # Database initialization
├── docker-compose.yml       # Docker orchestration
├── simulate_traffic.py      # Event traffic simulator
└── README.md
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login (returns JWT token)

### Analytics
- `GET /api/analytics/summary` - Get analytics summary with trends
  - Query params: `start_date`, `end_date`
- `GET /api/analytics/realtime` - Get real-time user data (last 30 min)
- `POST /api/events` - Track a new event

### Event Tracking Example

```bash
curl -X POST http://localhost:8000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pageview",
    "user_id": "user_123",
    "session_id": "session_abc",
    "page_url": "/products",
    "country": "United States"
  }'
```

## Environment Variables

### Backend (.env)

```env
DATABASE_URL=postgresql://analytics_user:analytics_password@db:5432/analytics
SECRET_KEY=your-secret-key-change-in-production
REDIS_URL=redis://redis:6379/0
```

### Frontend (.env)

```env
REACT_APP_API_URL=http://localhost:8000
```

## Development

### Backend Development

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### Frontend Development

```bash
cd frontend
npm install
npm start
```

### Database Access

```bash
# Connect to PostgreSQL
docker exec -it analytics_db psql -U analytics_user -d analytics

# View events
SELECT * FROM events ORDER BY created_at DESC LIMIT 10;

# View active sessions
SELECT * FROM sessions ORDER BY last_activity DESC LIMIT 10;
```

## Dashboard Features

### Metrics Cards
- **Users**: Total unique users with percentage change
- **Event Count**: Total events tracked with trend
- **Conversions**: Conversion events with comparison
- **New Users**: First-time users with growth rate

### Trend Chart
- Line chart showing user activity over time
- Selectable time ranges: 24 hours, 7 days, 30 days, 90 days
- Smooth animations and interactive tooltips

### Real-time Widget
- Active users in the last 30 minutes
- Users per minute bar chart
- Top 5 countries by active users
- Auto-refreshes every 30 seconds

## Scaling Considerations

### Database Optimization
- Indexed columns for fast queries (user_id, created_at, event_type)
- Composite indexes for complex queries
- Ready for partitioning by date for large datasets

### Production Deployment
1. Use environment-specific `.env` files
2. Enable HTTPS with SSL certificates
3. Set up database backups and replication
4. Use a reverse proxy (Nginx) for load balancing
5. Scale backend with multiple containers
6. Implement rate limiting on API endpoints

### Cloud Deployment Options
- **AWS**: RDS (PostgreSQL), ElastiCache (Redis), ECS/EKS for containers
- **GCP**: Cloud SQL, Memorystore, GKE
- **Azure**: Azure Database for PostgreSQL, Azure Cache for Redis, AKS

## Customization

### Adding New Event Types
1. No schema changes needed - flexible JSON properties
2. Update frontend filters/visualizations as desired
3. Add custom aggregations in backend queries

### Custom Metrics
Add new endpoints in `backend/main.py`:

```python
@app.get("/api/analytics/custom-metric")
async def get_custom_metric(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Your custom logic here
    return {"metric": value}
```

## Troubleshooting

### Container Issues
```bash
# View logs
docker-compose logs backend
docker-compose logs frontend

# Restart services
docker-compose restart

# Rebuild from scratch
docker-compose down -v
docker-compose up --build
```

### Database Connection Issues
- Ensure PostgreSQL container is healthy: `docker-compose ps`
- Check connection string in backend/.env
- Verify port 5432 is not in use by another service

### Frontend Not Loading
- Clear browser cache and local storage
- Check API_URL in frontend environment
- Verify CORS settings in backend/main.py

## License

MIT License - feel free to use this project for personal or commercial purposes.

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your fork
5. Open a Pull Request

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Built with ❤️ using React, FastAPI, and PostgreSQL**
