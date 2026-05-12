/**
 * Seed script — creates admin user + sample data
 * Usage: node src/config/seed.js
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { query, testConnection } = require('./db');

const seed = async () => {
  await testConnection();

  // ── Admin user ────────────────────────────────────────────────────────────
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@shop.local';
  const adminPass  = process.env.ADMIN_PASSWORD || 'Admin@1234';
  const existing   = await query('SELECT id FROM sellers WHERE email = ?', [adminEmail]);

  if (existing.length === 0) {
    const hash = await bcrypt.hash(adminPass, 12);
    await query(
      'INSERT INTO sellers (uuid, name, email, password_hash, role) VALUES (?, ?, ?, ?, ?)',
      [uuidv4(), 'Admin', adminEmail, hash, 'admin']
    );
    console.log(`✅ Admin created: ${adminEmail} / ${adminPass}`);
  } else {
    console.log('ℹ️  Admin already exists, skipping.');
  }

  // ── Sample categories ─────────────────────────────────────────────────────
  const cats = ['Electronics', 'Groceries', 'Beverages', 'Dairy', 'Snacks', 'Stationery'];
  for (const c of cats) {
    await query('INSERT IGNORE INTO categories (name) VALUES (?)', [c]);
  }
  console.log('✅ Sample categories seeded');

  // ── Sample products ───────────────────────────────────────────────────────
  const sampleProducts = [
    { barcode: '8901030762512', name: 'Parle-G Biscuits 800g', selling_price: 40, cgst_rate: 6, sgst_rate: 6, stock_qty: 100, low_stock_threshold: 20, unit: 'pcs' },
    { barcode: '8901058000491', name: 'Amul Butter 500g',      selling_price: 270, cgst_rate: 6, sgst_rate: 6, stock_qty: 50,  low_stock_threshold: 10, unit: 'pcs' },
    { barcode: '8901030010025', name: 'Good Day Butter Cookies', selling_price: 30, cgst_rate: 9, sgst_rate: 9, stock_qty: 80,  low_stock_threshold: 15, unit: 'pcs' },
    { barcode: '8906003200014', name: 'Kurkure Masala Munch',  selling_price: 20, cgst_rate: 9, sgst_rate: 9, stock_qty: 200, low_stock_threshold: 30, unit: 'pcs' },
    { barcode: '8901719106361', name: 'Tata Tea Gold 250g',    selling_price: 155, cgst_rate: 2.5, sgst_rate: 2.5, stock_qty: 60, low_stock_threshold: 10, unit: 'pcs' },
  ];

  for (const p of sampleProducts) {
    await query(
      `INSERT IGNORE INTO products (barcode, name, selling_price, cgst_rate, sgst_rate, stock_qty, low_stock_threshold, unit, purchase_price)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [p.barcode, p.name, p.selling_price, p.cgst_rate, p.sgst_rate, p.stock_qty, p.low_stock_threshold, p.unit, p.selling_price * 0.7]
    );
  }
  console.log('✅ Sample products seeded');

  // ── Shop settings ─────────────────────────────────────────────────────────
  await query(
    `UPDATE shop_settings SET shop_name='My POS Store', shop_address='123 Main Street, City - 400001',
     shop_phone='9876543210', default_cgst=9, default_sgst=9, receipt_footer='Thank you for shopping with us!' LIMIT 1`
  );
  console.log('✅ Shop settings seeded');

  console.log('\n🎉 Seed complete! You can log in with:');
  console.log(`   Email:    ${adminEmail}`);
  console.log(`   Password: ${adminPass}`);
  process.exit(0);
};

seed().catch((err) => { console.error('❌ Seed failed:', err.message); process.exit(1); });
