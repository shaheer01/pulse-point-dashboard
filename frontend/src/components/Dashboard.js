import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Grid,
  FormControl,
  Select,
  MenuItem,
  Button,
} from '@mui/material';
import {
  Brightness4,
  Brightness7,
  Logout,
  Refresh,
} from '@mui/icons-material';
import axios from 'axios';
import MetricCard from './MetricCard';
import TrendChart from './TrendChart';
import RealtimeWidget from './RealtimeWidget';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

function Dashboard({ darkMode, setDarkMode, onLogout }) {
  const [analytics, setAnalytics] = useState(null);
  const [realtime, setRealtime] = useState(null);
  const [timeRange, setTimeRange] = useState(7);
  const [loading, setLoading] = useState(false);
  const [apps, setApps] = useState([]);
  const [selectedApp, setSelectedApp] = useState('all');

  const fetchApps = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/api/apps`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      setApps(response.data.apps || []);
    } catch (error) {
      console.error('Error fetching apps:', error);
    }
  };

  const fetchAnalytics = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('token');
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - timeRange);

      const params = {
        start_date: startDate.toISOString(),
        end_date: endDate.toISOString(),
      };

      // Add app filter if not "all"
      if (selectedApp !== 'all') {
        const appData = apps.find(app => `${app.app_name}_${app.domain}` === selectedApp);
        if (appData) {
          params.app_name = appData.app_name.replace(/"/g, ''); // Remove quotes
          params.domain = appData.domain.replace(/"/g, '');
        }
      }

      const response = await axios.get(`${API_URL}/api/analytics/summary`, {
        params,
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      setAnalytics(response.data);
    } catch (error) {
      console.error('Error fetching analytics:', error);
      if (error.response?.status === 401) {
        onLogout();
      }
    } finally {
      setLoading(false);
    }
  };

  const fetchRealtime = async () => {
    try {
      const token = localStorage.getItem('token');

      const params = {};
      // Add app filter if not "all"
      if (selectedApp !== 'all') {
        const appData = apps.find(app => `${app.app_name}_${app.domain}` === selectedApp);
        if (appData) {
          params.app_name = appData.app_name.replace(/"/g, '');
          params.domain = appData.domain.replace(/"/g, '');
        }
      }

      const response = await axios.get(`${API_URL}/api/analytics/realtime`, {
        params,
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      setRealtime(response.data);
    } catch (error) {
      console.error('Error fetching realtime data:', error);
    }
  };

  useEffect(() => {
    fetchApps();
  }, []);

  useEffect(() => {
    fetchAnalytics();
    fetchRealtime();

    // Refresh realtime data every 30 seconds
    const interval = setInterval(fetchRealtime, 30000);
    return () => clearInterval(interval);
  }, [timeRange, selectedApp, apps]);

  const handleRefresh = () => {
    fetchAnalytics();
    fetchRealtime();
  };

  return (
    <Box sx={{ flexGrow: 1, minHeight: '100vh', bgcolor: 'background.default' }}>
      <AppBar position="static" elevation={0}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Analytics Dashboard
          </Typography>

          <FormControl sx={{ mr: 2, minWidth: 200 }} size="small">
            <Select
              value={selectedApp}
              onChange={(e) => setSelectedApp(e.target.value)}
              sx={{ color: 'white', '.MuiOutlinedInput-notchedOutline': { borderColor: 'rgba(255, 255, 255, 0.23)' } }}
              displayEmpty
            >
              <MenuItem value="all">All Apps</MenuItem>
              {apps.map((app, index) => {
                const appName = app.app_name.replace(/"/g, '');
                const domain = app.domain.replace(/"/g, '');
                const value = `${app.app_name}_${app.domain}`;
                const label = appName === 'legacy' ? `Legacy Data (${domain})` : `${appName} (${domain})`;

                return (
                  <MenuItem key={index} value={value}>
                    {label}
                  </MenuItem>
                );
              })}
            </Select>
          </FormControl>

          <FormControl sx={{ mr: 2, minWidth: 120 }} size="small">
            <Select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              sx={{ color: 'white', '.MuiOutlinedInput-notchedOutline': { borderColor: 'rgba(255, 255, 255, 0.23)' } }}
            >
              <MenuItem value={1}>Last 24 hours</MenuItem>
              <MenuItem value={7}>Last 7 days</MenuItem>
              <MenuItem value={30}>Last 30 days</MenuItem>
              <MenuItem value={90}>Last 90 days</MenuItem>
            </Select>
          </FormControl>

          <IconButton color="inherit" onClick={handleRefresh} sx={{ mr: 1 }}>
            <Refresh />
          </IconButton>

          <IconButton color="inherit" onClick={() => setDarkMode(!darkMode)} sx={{ mr: 1 }}>
            {darkMode ? <Brightness7 /> : <Brightness4 />}
          </IconButton>

          <IconButton color="inherit" onClick={onLogout}>
            <Logout />
          </IconButton>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
        <Grid container spacing={3}>
          {/* Metric Cards */}
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard
              title="Users"
              value={analytics?.total_users || 0}
              change={analytics?.total_users_change || 0}
              loading={loading}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard
              title="Event count"
              value={analytics?.event_count || 0}
              change={analytics?.event_count_change || 0}
              loading={loading}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard
              title="Conversions"
              value={analytics?.conversions || 0}
              change={analytics?.conversions_change || 0}
              loading={loading}
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard
              title="New users"
              value={analytics?.new_users || 0}
              change={analytics?.new_users_change || 0}
              loading={loading}
            />
          </Grid>

          {/* Trend Chart */}
          <Grid item xs={12} md={8}>
            <TrendChart
              data={analytics?.trend_data || []}
              loading={loading}
              timeRange={timeRange}
            />
          </Grid>

          {/* Realtime Widget */}
          <Grid item xs={12} md={4}>
            <RealtimeWidget data={realtime} loading={loading} />
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}

export default Dashboard;
