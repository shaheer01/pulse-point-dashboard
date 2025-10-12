import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Skeleton,
  Divider,
  List,
  ListItem,
  ListItemText,
} from '@mui/material';
import { Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

function RealtimeWidget({ data, loading }) {
  if (loading || !data) {
    return (
      <Card elevation={2} sx={{ height: '100%' }}>
        <CardContent>
          <Skeleton variant="text" width="60%" />
          <Skeleton variant="text" width="40%" height={60} />
          <Skeleton variant="rectangular" height={150} sx={{ mt: 2 }} />
          <Skeleton variant="rectangular" height={100} sx={{ mt: 2 }} />
        </CardContent>
      </Card>
    );
  }

  // Chart data for users by minute
  const chartData = {
    labels: data.users_by_minute.map((d) => d.minute),
    datasets: [
      {
        label: 'Users',
        data: data.users_by_minute.map((d) => d.users),
        backgroundColor: 'rgba(54, 162, 235, 0.6)',
        borderColor: 'rgba(54, 162, 235, 1)',
        borderWidth: 1,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false,
      },
      tooltip: {
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        padding: 8,
      },
    },
    scales: {
      x: {
        display: false,
      },
      y: {
        beginAtZero: true,
        ticks: {
          precision: 0,
          font: {
            size: 10,
          },
        },
      },
    },
  };

  return (
    <Card elevation={2} sx={{ height: '100%' }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Real-time (Last 30 min)
        </Typography>

        {/* Active Users Count */}
        <Box sx={{ my: 2 }}>
          <Typography variant="h3" component="div" sx={{ fontWeight: 600, color: 'primary.main' }}>
            {data.active_users}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Active users right now
          </Typography>
        </Box>

        {/* Users by Minute Chart */}
        <Box sx={{ height: 120, mb: 2 }}>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            Users per minute
          </Typography>
          <Bar data={chartData} options={chartOptions} />
        </Box>

        <Divider sx={{ my: 2 }} />

        {/* Users by Country */}
        <Typography variant="body2" color="text.secondary" gutterBottom>
          Users by country
        </Typography>
        <List dense disablePadding>
          {data.users_by_country.slice(0, 5).map((country, index) => (
            <ListItem key={index} disableGutters>
              <ListItemText
                primary={
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="body2">{country.country}</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {country.users}
                    </Typography>
                  </Box>
                }
              />
            </ListItem>
          ))}
        </List>

        {data.users_by_country.length === 0 && (
          <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic', mt: 1 }}>
            No active users by country
          </Typography>
        )}
      </CardContent>
    </Card>
  );
}

export default RealtimeWidget;
