const { query, queryOne } = require('../config/db');

const logAction = async (data) => {
  const { seller_id, action, entity, entity_id, meta, ip_address, user_agent } = data;
  return query(
    `INSERT INTO audit_logs (seller_id, action, entity, entity_id, meta, ip_address, user_agent)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [seller_id || null, action, entity || null, entity_id || null,
     meta ? JSON.stringify(meta) : null, ip_address || null, user_agent || null]
  );
};

const getAuditLogs = ({ sellerId = null, action = null, from = null, to = null, limit = 50, offset = 0 } = {}) => {
  const conditions = [];
  const params = [];
  if (sellerId) { conditions.push('al.seller_id = ?'); params.push(sellerId); }
  if (action)   { conditions.push('al.action = ?'); params.push(action); }
  if (from)     { conditions.push('DATE(al.created_at) >= ?'); params.push(from); }
  if (to)       { conditions.push('DATE(al.created_at) <= ?'); params.push(to); }
  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  params.push(limit, offset);
  return query(
    `SELECT al.*, s.name AS seller_name FROM audit_logs al
     LEFT JOIN sellers s ON s.id = al.seller_id
     ${where} ORDER BY al.created_at DESC LIMIT ? OFFSET ?`,
    params
  );
};

const getStockMovements = ({ productId = null, reason = null, limit = 50, offset = 0 } = {}) => {
  const conditions = [];
  const params = [];
  if (productId) { conditions.push('sm.product_id = ?'); params.push(productId); }
  if (reason)    { conditions.push('sm.reason = ?'); params.push(reason); }
  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  params.push(limit, offset);
  return query(
    `SELECT sm.*, p.name AS product_name, p.barcode, s.name AS seller_name FROM stock_movements sm
     LEFT JOIN products p ON p.id = sm.product_id
     LEFT JOIN sellers s ON s.id = sm.seller_id
     ${where} ORDER BY sm.created_at DESC LIMIT ? OFFSET ?`,
    params
  );
};

module.exports = { logAction, getAuditLogs, getStockMovements };
