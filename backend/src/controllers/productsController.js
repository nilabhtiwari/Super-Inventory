const productModel = require('../models/productModel');
const { logAction } = require('../models/auditModel');

const getByBarcode = async (req, res, next) => {
  try {
    const { code } = req.params;
    const product = await productModel.findByBarcode(code.trim());
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found for barcode: ' + code });
    }
    res.json({ success: true, product });
  } catch (err) { next(err); }
};

const getAll = async (req, res, next) => {
  try {
    const { search = '', category_id, include_inactive, limit = 50, page = 1 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const opts = {
      search, categoryId: category_id ? parseInt(category_id) : null,
      includeInactive: include_inactive === 'true',
      limit: parseInt(limit), offset
    };
    const [products, countRow] = await Promise.all([
      productModel.getAll(opts),
      productModel.countAll(opts)
    ]);
    res.json({ success: true, products, total: countRow.total, page: parseInt(page), limit: parseInt(limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const product = await productModel.findById(parseInt(req.params.id));
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, product });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const id = await productModel.create(req.body);
    const product = await productModel.findById(id);
    await logAction({ seller_id: req.seller.id, action: 'PRODUCT_CREATE', entity: 'product', entity_id: id, meta: { name: req.body.name, barcode: req.body.barcode }, ip_address: req.ip });
    res.status(201).json({ success: true, product });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const existing = await productModel.findById(id);
    if (!existing) return res.status(404).json({ success: false, message: 'Product not found' });
    await productModel.update(id, req.body);
    const product = await productModel.findById(id);
    await logAction({ seller_id: req.seller.id, action: 'PRODUCT_UPDATE', entity: 'product', entity_id: id, meta: { name: req.body.name }, ip_address: req.ip });
    res.json({ success: true, product });
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    await productModel.softDelete(id);
    await logAction({ seller_id: req.seller.id, action: 'PRODUCT_DELETE', entity: 'product', entity_id: id, ip_address: req.ip });
    res.json({ success: true, message: 'Product deleted' });
  } catch (err) { next(err); }
};

const getCategories = async (req, res, next) => {
  try {
    const categories = await productModel.getCategories();
    res.json({ success: true, categories });
  } catch (err) { next(err); }
};

const createCategory = async (req, res, next) => {
  try {
    const { name, description } = req.body;
    if (!name) return res.status(422).json({ success: false, message: 'Category name is required' });
    const result = await productModel.createCategory(name, description);
    res.status(201).json({ success: true, category: { id: result.insertId, name, description } });
  } catch (err) { next(err); }
};

const getLowStock = async (req, res, next) => {
  try {
    const products = await productModel.getLowStock();
    res.json({ success: true, products });
  } catch (err) { next(err); }
};

module.exports = { getByBarcode, getAll, getOne, create, update, remove, getCategories, createCategory, getLowStock };
