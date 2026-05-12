const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const sellerModel = require('../models/sellerModel');
const { signToken } = require('../utils/jwt');
const { logAction } = require('../models/auditModel');

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const seller = await sellerModel.findByEmail(email);
    if (!seller) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    if (!seller.is_active) {
      return res.status(403).json({ success: false, message: 'Account is deactivated' });
    }

    const valid = await bcrypt.compare(password, seller.password_hash);
    if (!valid) {
      await logAction({ action: 'LOGIN_FAILED', entity: 'seller', entity_id: seller.id, ip_address: req.ip, meta: { email } });
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    await sellerModel.updateLastLogin(seller.id);

    const token = signToken({ id: seller.id, uuid: seller.uuid, role: seller.role });

    await logAction({
      seller_id: seller.id, action: 'LOGIN', entity: 'seller', entity_id: seller.id,
      ip_address: req.ip, user_agent: req.headers['user-agent']
    });

    res.json({
      success: true,
      token,
      seller: { id: seller.id, uuid: seller.uuid, name: seller.name, email: seller.email, role: seller.role, avatar_url: seller.avatar_url }
    });
  } catch (err) { next(err); }
};

const me = async (req, res, next) => {
  try {
    const seller = await sellerModel.findById(req.seller.id);
    res.json({ success: true, seller });
  } catch (err) { next(err); }
};

const logout = async (req, res, next) => {
  try {
    await logAction({
      seller_id: req.seller.id, action: 'LOGOUT', entity: 'seller', entity_id: req.seller.id,
      ip_address: req.ip
    });
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (err) { next(err); }
};

const changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body;
    const seller = await sellerModel.findByEmail(req.seller.email);
    const valid = await bcrypt.compare(current_password, seller.password_hash);
    if (!valid) return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    const hash = await bcrypt.hash(new_password, 12);
    await sellerModel.updatePassword(req.seller.id, hash);
    await logAction({ seller_id: req.seller.id, action: 'PASSWORD_CHANGED', entity: 'seller', entity_id: req.seller.id, ip_address: req.ip });
    res.json({ success: true, message: 'Password changed successfully' });
  } catch (err) { next(err); }
};

module.exports = { login, me, logout, changePassword };
