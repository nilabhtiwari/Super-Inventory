let app;
try {
  app = require('../backend/src/index');
} catch (err) {
  console.error('API initialization error:', err);
  const express = require('express');
  app = express();
  app.get('/health', (req, res) => res.json({ status: 'ok', fallback: true, error: err.message }));
  app.use((req, res) => res.status(500).json({ error: 'Server initialization error', message: err.message }));
}

module.exports = app;

