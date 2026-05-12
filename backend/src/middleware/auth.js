const { verifyToken } = require('../utils/jwt');
const { queryOne } = require('../config/db');
const logger = require('../config/logger');

/**
 * Middleware: verify JWT and attach seller to req.seller
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);

    const seller = await queryOne(
      'SELECT id, uuid, name, email, role, is_active FROM sellers WHERE id = ?',
      [decoded.id]
    );

    if (!seller) {
      return res.status(401).json({ success: false, message: 'Seller not found' });
    }
    if (!seller.is_active) {
      return res.status(403).json({ success: false, message: 'Account deactivated' });
    }

    req.seller = seller;
    next();
  } catch (err) {
    logger.warn(`Auth failed: ${err.message}`);
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

/**
 * Factory: require one of the specified roles
 * Usage: requireRole('admin') or requireRole('admin', 'manager')
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.seller) {
      return res.status(401).json({ success: false, message: 'Not authenticated' });
    }
    if (!roles.includes(req.seller.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role: ${roles.join(' or ')}`,
      });
    }
    next();
  };
};

module.exports = { authenticate, requireRole };
