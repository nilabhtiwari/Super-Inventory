const path = require('path');
require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const compression = require('compression');
const { apiLimiter } = require('./middleware/rateLimiter');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { testConnection } = require('./config/db');
const logger = require('./config/logger');

const app = express();
const PORT = process.env.PORT || 5000;
const webPreviewDir = path.join(__dirname, '../../flutter_app/web_preview');

// ── Security ──────────────────────────────────────────────────────────────────
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || process.env.NODE_ENV !== 'production') {
      return callback(null, true);
    }
    const allowed = (process.env.ALLOWED_ORIGINS || '').split(',').map(o => o.trim());
    if (allowed.includes(origin) || allowed.includes('*')) {
      return callback(null, true);
    }
    return callback(new Error('CORS not allowed'), false);
  },
  credentials: true,
}));
app.set('trust proxy', 1);

// ── General Middleware ─────────────────────────────────────────────────────────
app.use(compression());
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', { stream: { write: (msg) => logger.info(msg.trim()) } }));
app.use('/api', apiLimiter);

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/auth',      require('./routes/auth'));
app.use('/api/products',  require('./routes/products'));
app.use('/api/sales',     require('./routes/sales'));
app.use('/api/inventory', require('./routes/inventory'));
app.use('/api/admin',     require('./routes/admin'));
app.use('/api/settings',  require('./routes/settings'));

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString(), env: process.env.NODE_ENV });
});

// ── Static Web App Serving ───────────────────────────────────────────────────
app.use(express.static(webPreviewDir));
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api') || req.path === '/health') return next();
  res.sendFile(path.join(webPreviewDir, 'index.html'));
});

// ── 404 + Error handlers ──────────────────────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

// ── Start ─────────────────────────────────────────────────────────────────────
const start = async () => {
  await testConnection();
  app.listen(PORT, () => {
    logger.info(`🚀 Super Inventory API running on http://localhost:${PORT}`);
    logger.info(`📦 Environment: ${process.env.NODE_ENV}`);
  });
};

start().catch((err) => {
  logger.error('Failed to start server:', err);
  process.exit(1);
});

module.exports = app;
