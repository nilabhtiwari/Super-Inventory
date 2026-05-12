/**
 * Database migration script — runs schema.sql
 * Usage: node src/config/migrate.js
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

const run = async () => {
  const conn = await mysql.createConnection({
    host:     process.env.DB_HOST || 'localhost',
    port:     parseInt(process.env.DB_PORT || '3306'),
    user:     process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
  });

  const schemaPath = path.join(__dirname, '../../sql/schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');

  console.log('🔄 Running database migration...');
  await conn.query(sql);
  console.log('✅ Migration complete!');
  await conn.end();
};

run().catch((err) => { console.error('❌ Migration failed:', err.message); process.exit(1); });
