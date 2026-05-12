const { query, queryOne } = require('../config/db');

const getSettings = () =>
  queryOne('SELECT * FROM shop_settings LIMIT 1', []);

const updateSettings = (data) => {
  const {
    shop_name, shop_address, shop_phone, shop_email, gstin,
    upi_id, upi_name, default_cgst, default_sgst, default_igst, receipt_footer
  } = data;
  return query(
    `UPDATE shop_settings SET
       shop_name=?, shop_address=?, shop_phone=?, shop_email=?, gstin=?,
       upi_id=?, upi_name=?, default_cgst=?, default_sgst=?, default_igst=?,
       receipt_footer=? LIMIT 1`,
    [shop_name, shop_address || null, shop_phone || null, shop_email || null, gstin || null,
     upi_id || null, upi_name || null, default_cgst ?? 9, default_sgst ?? 9, default_igst ?? 0, receipt_footer || null]
  );
};

const updateLogo = (logo_url) =>
  query('UPDATE shop_settings SET logo_url = ? LIMIT 1', [logo_url]);

module.exports = { getSettings, updateSettings, updateLogo };
