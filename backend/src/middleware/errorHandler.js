const logger = require('../config/logger');

const errorHandler = (err, req, res, next) => {
  logger.error(err);

  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ success: false, message: 'A record with this value already exists.' });
  }
  if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    return res.status(409).json({ success: false, message: 'Cannot delete: record is referenced by other data.' });
  }

  const status = err.statusCode || err.status || 500;
  const message = err.expose ? err.message : 'Internal server error';

  res.status(status).json({ success: false, message });
};

const notFound = (req, res) => {
  res.status(404).json({ success: false, message: `Route not found: ${req.method} ${req.originalUrl}` });
};

module.exports = { errorHandler, notFound };
