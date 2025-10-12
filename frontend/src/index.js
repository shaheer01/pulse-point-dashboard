import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

// Suppress ResizeObserver error from Chart.js
const resizeObserverLoopErrRe = /^[^(ResizeObserver loop completed with undelivered notifications|ResizeObserver loop limit exceeded)]/;
const resizeObserverErrFilter = (e) => {
  if (
    e.message === 'ResizeObserver loop completed with undelivered notifications.' ||
    e.message === 'ResizeObserver loop limit exceeded'
  ) {
    const resizeObserverErr = document.getElementById('webpack-dev-server-client-overlay');
    if (resizeObserverErr) {
      resizeObserverErr.style.display = 'none';
    }
    return false;
  }
  return true;
};

window.addEventListener('error', (e) => {
  if (!resizeObserverErrFilter(e)) {
    e.stopImmediatePropagation();
  }
});

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
