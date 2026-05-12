/**
 * Invoice number generator — INV-YYYYMMDD-NNNN
 * e.g. INV-20241201-0042
 */
const { query } = require('../config/db');

const generateInvoiceNo = async () => {
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
  const prefix = `INV-${dateStr}`;

  const row = await query(
    `SELECT COUNT(*) AS cnt FROM sales WHERE invoice_no LIKE ?`,
    [`${prefix}%`]
  );
  const count = (row[0]?.cnt || 0) + 1;
  const seq = String(count).padStart(4, '0');
  return `${prefix}-${seq}`;
};

module.exports = { generateInvoiceNo };
