// backend/src/app.js
const express = require('express');
const cors = require('cors');
const errorMiddleware = require('./middleware/error');
const apiRouter = require('./routes');

const app = express();

// 1. CORS Configuration
app.use(
  cors({
    // Native apps ignore CORS; set CORS_ORIGIN=https://site1,https://site2 to restrict browsers.
    origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',').map(o => o.trim()) : '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  })
);

// 2. Body parsers: text-only app (no uploads), so keep requests small.
app.use(express.json({ limit: '100kb' }));
app.use(express.urlencoded({ extended: true, limit: '100kb' }));

// 3. Health Check Endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    status: 'ok',
    message: 'Facebook Clone REST API is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// 4. API Routes Mount
app.use('/api', apiRouter);

// 5. 404 Route Not Found Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Cannot ${req.method} ${req.originalUrl} - Endpoint not found`,
  });
});

// 6. Centralized Error Handler Middleware (Must be last middleware)
app.use(errorMiddleware);

module.exports = app;
