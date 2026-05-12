const { query, queryOne } = require('../config/db');

const findByBarcode = (barcode) =>
  queryOne(
    `SELECT p.*, c.name AS category_name
     FROM products p
     LEFT JOIN categories c ON c.id = p.category_id
     WHERE p.barcode = ? AND p.is_active = 1`,
    [barcode]
  );

const findById = (id) =>
  queryOne(
    `SELECT p.*, c.name AS category_name
     FROM products p
     LEFT JOIN categories c ON c.id = p.category_id
     WHERE p.id = ?`,
    [id]
  );

const getAll = ({ search = '', categoryId = null, includeInactive = false, limit = 50, offset = 0 } = {}) => {
  const conditions = [];
  const params = [];
  if (!includeInactive) { conditions.push('p.is_active = 1'); }
  if (search) { conditions.push('(p.name LIKE ? OR p.barcode LIKE ? OR p.sku LIKE ?)'); params.push(`%${search}%`, `%${search}%`, `%${search}%`); }
  if (categoryId) { conditions.push('p.category_id = ?'); params.push(categoryId); }
  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  params.push(limit, offset);
  return query(
    `SELECT p.id, p.barcode, p.sku, p.name, p.selling_price, p.cgst_rate, p.sgst_rate, p.igst_rate,
            p.stock_qty, p.low_stock_threshold, p.unit, p.is_active, p.image_url, c.name AS category_name
     FROM products p LEFT JOIN categories c ON c.id = p.category_id
     ${where} ORDER BY p.name LIMIT ? OFFSET ?`,
    params
  );
};

const countAll = ({ search = '', categoryId = null, includeInactive = false } = {}) => {
  const conditions = [];
  const params = [];
  if (!includeInactive) { conditions.push('p.is_active = 1'); }
  if (search) { conditions.push('(p.name LIKE ? OR p.barcode LIKE ?)'); params.push(`%${search}%`, `%${search}%`); }
  if (categoryId) { conditions.push('p.category_id = ?'); params.push(categoryId); }
  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  return queryOne(`SELECT COUNT(*) AS total FROM products p ${where}`, params);
};

const getLowStock = () =>
  query(
    `SELECT id, barcode, name, stock_qty, low_stock_threshold, unit, selling_price
     FROM products WHERE stock_qty <= low_stock_threshold AND is_active = 1 ORDER BY stock_qty ASC`,
    []
  );

const create = async (data) => {
  const {
    barcode, sku, name, description, category_id, hsn_code, unit,
    purchase_price, selling_price, mrp, cgst_rate, sgst_rate, igst_rate,
    stock_qty, low_stock_threshold, image_url
  } = data;
  const result = await query(
    `INSERT INTO products (barcode, sku, name, description, category_id, hsn_code, unit,
       purchase_price, selling_price, mrp, cgst_rate, sgst_rate, igst_rate,
       stock_qty, low_stock_threshold, image_url)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [barcode, sku || null, name, description || null, category_id || null, hsn_code || null, unit || 'pcs',
     purchase_price || 0, selling_price, mrp || null, cgst_rate ?? 9, sgst_rate ?? 9, igst_rate ?? 0,
     stock_qty || 0, low_stock_threshold ?? 10, image_url || null]
  );
  return result.insertId;
};

const update = (id, data) => {
  const {
    barcode, sku, name, description, category_id, hsn_code, unit,
    purchase_price, selling_price, mrp, cgst_rate, sgst_rate, igst_rate,
    low_stock_threshold, image_url
  } = data;
  return query(
    `UPDATE products SET barcode=?, sku=?, name=?, description=?, category_id=?, hsn_code=?, unit=?,
       purchase_price=?, selling_price=?, mrp=?, cgst_rate=?, sgst_rate=?, igst_rate=?,
       low_stock_threshold=?, image_url=? WHERE id=?`,
    [barcode, sku || null, name, description || null, category_id || null, hsn_code || null, unit,
     purchase_price, selling_price, mrp || null, cgst_rate, sgst_rate, igst_rate,
     low_stock_threshold, image_url || null, id]
  );
};

const softDelete = (id) =>
  query('UPDATE products SET is_active = 0 WHERE id = ?', [id]);

const decrementStock = (conn, productId, qty) =>
  conn.execute('UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?', [qty, productId]);

const incrementStock = (conn, productId, qty) =>
  conn.execute('UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?', [qty, productId]);

const getCategories = () =>
  query('SELECT * FROM categories WHERE is_active = 1 ORDER BY name', []);

const createCategory = (name, description) =>
  query('INSERT INTO categories (name, description) VALUES (?, ?)', [name, description || null]);

module.exports = {
  findByBarcode, findById, getAll, countAll, getLowStock, create, update, softDelete,
  decrementStock, incrementStock, getCategories, createCategory
};
