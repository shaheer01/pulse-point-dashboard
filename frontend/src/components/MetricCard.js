import React from 'react';
import { Card, CardContent, Typography, Box, Skeleton } from '@mui/material';
import { TrendingUp, TrendingDown } from '@mui/icons-material';

function MetricCard({ title, value, change, loading }) {
  const isPositive = change >= 0;

  if (loading) {
    return (
      <Card elevation={2}>
        <CardContent>
          <Skeleton variant="text" width="60%" />
          <Skeleton variant="text" width="80%" height={40} />
          <Skeleton variant="text" width="40%" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card elevation={2} sx={{ height: '100%' }}>
      <CardContent>
        <Typography color="text.secondary" gutterBottom variant="body2">
          {title}
        </Typography>
        <Typography variant="h4" component="div" sx={{ my: 1, fontWeight: 600 }}>
          {value.toLocaleString()}
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          {isPositive ? (
            <TrendingUp sx={{ color: 'success.main', mr: 0.5, fontSize: 18 }} />
          ) : (
            <TrendingDown sx={{ color: 'error.main', mr: 0.5, fontSize: 18 }} />
          )}
          <Typography
            variant="body2"
            sx={{
              color: isPositive ? 'success.main' : 'error.main',
              fontWeight: 500,
            }}
          >
            {isPositive ? '+' : ''}{change.toFixed(1)}%
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
            vs previous period
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );
}

export default MetricCard;
