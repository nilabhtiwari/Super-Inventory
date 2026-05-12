const rateLimit = require('express-rate-limit');
const logger = require('../config/logger');

const createLimiter = (windowMs, max, message) =>
  rateLimit({
    windowMs,
    max,
    message: { success: false, message },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
      logger.warn(`Rate limit hit: ${req.ip} → ${req.originalUrl}`);
      res.status(429).json(options.message);
    },
  });

// 10 login attempts per 15 min
const loginLimiter = createLimiter(15 * 60 * 1000, 10, 'Too many login attempts. Try again in 15 minutes.');

// 200 general API requests per minute
const apiLimiter = createLimiter(60 * 1000, 200, 'Too many requests. Please slow down.');

// 60 barcode lookups per minute (fast POS use)
const barcodeLimiter = createLimiter(60 * 1000, 120, 'Too many barcode requests.');

module.exports = { loginLimiter, apiLimiter, barcodeLimiter };
