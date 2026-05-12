const { query, queryOne } = require('../config/db');

/**
 * Insert sale header and return sale id
 */
const createSaleHeader = async (conn, data) => {
  const {
    invoice_no, seller_id, customer_name, customer_phone,
    subtotal, cgst_total, sgst_total, igst_total, tax_total,
    discount_amount, grand_total, payment_method, payment_ref, notes
  } = data;
  const [result] = await conn.execute(
    `INSERT INTO sales (invoice_no, seller_id, customer_name, customer_phone,
       subtotal, cgst_total, sgst_total, igst_total, tax_total,
       discount_amount, grand_total, payment_method, payment_ref, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [invoice_no, seller_id, customer_name || null, customer_phone || null,
     subtotal, cgst_total, sgst_total, igst_total, tax_total,
     discount_amount || 0, grand_total, payment_method || 'cash', payment_ref || null, notes || null]
  );
  return result.insertId;
};

const createSaleItem = async (conn, data) => {
  const {
    sale_id, product_id, product_name, barcode, hsn_code, qty,
    unit_price, cgst_rate, sgst_rate, igst_rate,
    cgst_amount, sgst_amount, igst_amount, line_total
  } = data;
  await conn.execute(
    `INSERT INTO sale_items (sale_id, product_id, product_name, barcode, hsn_code, qty,
       unit_price, cgst_rate, sgst_rate, igst_rate, cgst_amount, sgst_amount, igst_amount, line_total)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [sale_id, product_id, product_name, barcode, hsn_code || null, qty,
     unit_price, cgst_rate, sgst_rate, igst_rate, cgst_amount, sgst_amount, igst_amount, line_total]
  );
};

const createStockMovement = async (conn, data) => {
  const { product_id, delta, reason, reference_id, seller_id, note } = data;
  await conn.execute(
    `INSERT INTO stock_movements (product_id, delta, reason, reference_id, seller_id, note)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [product_id, delta, reason, reference_id || null, seller_id || null, note || null]
  );
};

const getById = (id) =>
  queryOne(
    `SELECT s.*, sl.name AS seller_name FROM sales s
     LEFT JOIN sellers sl ON sl.id = s.seller_id WHERE s.id = ?`,
    [id]
  );

const getItems = (saleId) =>
  query('SELECT * FROM sale_items WHERE sale_id = ? ORDER BY id', [saleId]);

const getAll = ({ sellerId = null, from = null, to = null, limit = 20, offset = 0 } = {}) => {
  const conditions = [];
  const params = [];
  if (sellerId) { conditions.push('s.seller_id = ?'); params.push(sellerId); }
  if (from)     { conditions.push('DATE(s.created_at) >= ?'); params.push(from); }
  if (to)       { conditions.push('DATE(s.created_at) <= ?'); params.push(to); }
  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  params.push(limit, offset);
  return query(
    `SELECT s.id, s.invoice_no, s.grand_total, s.tax_total, s.payment_method, s.status, s.created_at,
            sl.name AS seller_name, s.customer_name
     FROM sales s LEFT JOIN sellers sl ON sl.id = s.seller_id
     ${where} ORDER BY s.created_at DESC LIMIT ? OFFSET ?`,
    params
  );
};

const countAll = ({ sellerId = null, from = null, to = null } = {}) => {
  const conditions = [];
  const params = [];
  if (sellerId) { conditions.push('seller_id = ?'); params.push(sellerId); }
  if (from)     { conditions.push('DATE(created_at) >= ?'); params.push(from); }
  if (to)       { conditions.push('DATE(created_at) <= ?'); params.push(to); }
  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  return queryOne(`SELECT COUNT(*) AS total FROM sales ${where}`, params);
};

const getDailySummary = (date) =>
  queryOne(
    `SELECT COUNT(*) AS total_sales, COALESCE(SUM(grand_total),0) AS total_revenue,
            COALESCE(SUM(tax_total),0) AS total_tax
     FROM sales WHERE DATE(created_at) = ? AND status = 'completed'`,
    [date]
  );

module.exports = {
  createSaleHeader, createSaleItem, createStockMovement,
  getById, getItems, getAll, countAll, getDailySummary
};
