const productModel = require('../models/productModel');
const { getStockMovements, logAction } = require('../models/auditModel');
const { transaction } = require('../config/db');
const saleModel = require('../models/saleModel');

const getLowStock = async (req, res, next) => {
  try {
    const products = await productModel.getLowStock();
    res.json({ success: true, products, count: products.length });
  } catch (err) { next(err); }
};

const adjustStock = async (req, res, next) => {
  try {
    const { product_id, delta, reason, note } = req.body;
    const product = await productModel.findById(product_id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    await transaction(async (conn) => {
      if (delta > 0) {
        await productModel.incrementStock(conn, product_id, delta);
      } else {
        if (product.stock_qty + delta < 0) {
          throw Object.assign(new Error('Adjustment would make stock negative'), { statusCode: 400, expose: true });
        }
        await productModel.decrementStock(conn, product_id, Math.abs(delta));
      }
      await saleModel.createStockMovement(conn, { product_id, delta, reason, seller_id: req.seller.id, note });
    });

    const updated = await productModel.findById(product_id);
    await logAction({ seller_id: req.seller.id, action: 'STOCK_ADJUST', entity: 'product', entity_id: product_id, meta: { delta, reason, note }, ip_address: req.ip });

    res.json({ success: true, product: updated, message: `Stock ${delta > 0 ? 'increased' : 'decreased'} by ${Math.abs(delta)}` });
  } catch (err) { next(err); }
};

const getMovements = async (req, res, next) => {
  try {
    const { product_id, reason, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const movements = await getStockMovements({ productId: product_id ? parseInt(product_id) : null, reason, limit: parseInt(limit), offset });
    res.json({ success: true, movements });
  } catch (err) { next(err); }
};

module.exports = { getLowStock, adjustStock, getMovements };
