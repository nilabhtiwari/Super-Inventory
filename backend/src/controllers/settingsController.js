const settingsModel = require('../models/settingsModel');
const { logAction } = require('../models/auditModel');

const getSettings = async (req, res, next) => {
  try {
    const settings = await settingsModel.getSettings();
    res.json({ success: true, settings });
  } catch (err) { next(err); }
};

const updateSettings = async (req, res, next) => {
  try {
    await settingsModel.updateSettings(req.body);
    await logAction({ seller_id: req.seller.id, action: 'SETTINGS_UPDATE', entity: 'shop_settings', ip_address: req.ip });
    const settings = await settingsModel.getSettings();
    res.json({ success: true, settings, message: 'Settings updated successfully' });
  } catch (err) { next(err); }
};

module.exports = { getSettings, updateSettings };
