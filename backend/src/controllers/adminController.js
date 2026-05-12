const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const sellerModel = require('../models/sellerModel');
const { logAction, getAuditLogs } = require('../models/auditModel');

const getSellers = async (req, res, next) => {
  try {
    const sellers = await sellerModel.getAll(req.query.include_inactive === 'true');
    res.json({ success: true, sellers });
  } catch (err) { next(err); }
};

const createSeller = async (req, res, next) => {
  try {
    const { name, email, phone, password, role } = req.body;
    const existing = await sellerModel.findByEmail(email);
    if (existing) return res.status(409).json({ success: false, message: 'Email already in use' });
    const password_hash = await bcrypt.hash(password, 12);
    const id = await sellerModel.create({ uuid: uuidv4(), name, email, phone, password_hash, role });
    await logAction({ seller_id: req.seller.id, action: 'SELLER_CREATE', entity: 'seller', entity_id: id, meta: { name, email, role }, ip_address: req.ip });
    res.status(201).json({ success: true, seller: { id, name, email, role } });
  } catch (err) { next(err); }
};

const updateSellerStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;
    await sellerModel.updateStatus(parseInt(id), is_active);
    await logAction({ seller_id: req.seller.id, action: 'SELLER_STATUS_CHANGE', entity: 'seller', entity_id: parseInt(id), meta: { is_active }, ip_address: req.ip });
    res.json({ success: true, message: 'Seller status updated' });
  } catch (err) { next(err); }
};

const updateSellerRole = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role } = req.body;
    await sellerModel.updateRole(parseInt(id), role);
    await logAction({ seller_id: req.seller.id, action: 'SELLER_ROLE_CHANGE', entity: 'seller', entity_id: parseInt(id), meta: { role }, ip_address: req.ip });
    res.json({ success: true, message: 'Seller role updated' });
  } catch (err) { next(err); }
};

const getAuditLogsHandler = async (req, res, next) => {
  try {
    const { seller_id, action, from, to, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const logs = await getAuditLogs({ sellerId: seller_id, action, from, to, limit: parseInt(limit), offset });
    res.json({ success: true, logs });
  } catch (err) { next(err); }
};

module.exports = { getSellers, createSeller, updateSellerStatus, updateSellerRole, getAuditLogsHandler };
